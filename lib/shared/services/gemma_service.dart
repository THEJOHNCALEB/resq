import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

enum GemmaState { loading, ready, idle, processing, error }

class GemmaService extends ChangeNotifier {
  GemmaState _state = GemmaState.idle;
  String _error = '';

  GemmaState get state => _state;
  String get error => _error;
  bool get isReady =>
      _state == GemmaState.ready || _state == GemmaState.processing;
  bool get modelLoaded => FlutterGemma.hasActiveModel();

  InferenceModel? _model;

  Future<void> initialize() async {
    if (_state == GemmaState.ready) return;
    if (_state == GemmaState.loading) return;

    _state = GemmaState.loading;
    notifyListeners();

    try {
      if (FlutterGemma.hasActiveModel()) {
        _model = await FlutterGemma.getActiveModel(maxTokens: 2048);
      }
      _state = GemmaState.ready;
    } catch (e) {
      _model = null;
      _state = GemmaState.ready;
      _error = e.toString();
    }

    notifyListeners();
  }

  Future<bool> installModel() async {
    _state = GemmaState.loading;
    notifyListeners();

    try {
      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromNetwork(
              'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/'
              'Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.task')
          .withProgress((progress) {
            notifyListeners();
          })
          .install();

      _model = await FlutterGemma.getActiveModel(maxTokens: 2048);
      _state = GemmaState.ready;
      notifyListeners();
      return true;
    } catch (e) {
      _state = GemmaState.ready;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> _tryGetResponse(String prompt) async {
    if (_model == null) {
      if (!FlutterGemma.hasActiveModel()) return null;
      _model = await FlutterGemma.getActiveModel(maxTokens: 2048);
    }
    if (_model == null) return null;

    try {
      final session = await _model!.createSession();
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await session.getResponse();
      if (response.isEmpty) return null;
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<String> analyzeEmergency({
    required String userDescription,
    String? imagePath,
    String? audioTranscription,
  }) async {
    _state = GemmaState.processing;
    notifyListeners();

    final prompt = _buildEmergencyPrompt(
      description: userDescription,
      imagePath: imagePath,
      audioTranscription: audioTranscription,
    );

    final response = await _tryGetResponse(prompt);
    _state = GemmaState.ready;
    notifyListeners();

    if (response != null && response.isNotEmpty) return response;
    return _emergencyAnalysis(userDescription);
  }

  Future<String> generateGuidance({required String context}) async {
    _state = GemmaState.processing;
    notifyListeners();

    final prompt = '''
You are an emergency response assistant providing guidance. Based on the following emergency context, provide structured guidance. Format your response as JSON with these keys:

- assessment: Brief current assessment of the situation
- actions: List of immediate actions to take (array of strings)
- avoid: Things to avoid doing (array of strings)
- monitor: Signs and symptoms to monitor (array of strings)
- seekCare: When to seek immediate medical care

Emergency context: $context

Respond ONLY with valid JSON, nothing else.
''';

    final response = await _tryGetResponse(prompt);
    _state = GemmaState.ready;
    notifyListeners();

    if (response != null && response.isNotEmpty) return response;
    return _structuredGuidance(context);
  }

  Future<String> generateSummary({
    required String context,
    required String guidance,
    String? imagePath,
    String? profileInfo,
  }) async {
    _state = GemmaState.processing;
    notifyListeners();

    final prompt = '''
Generate a professional medical summary for healthcare providers. Include:

1. Date and Time
2. Description of emergency
3. Observed symptoms
4. Visible findings
5. Actions already taken
6. Timeline of events
7. Relevant medical profile information
8. AI assessment
9. Recommended next steps

Emergency context: $context
Guidance provided: $guidance
Medical profile: ${profileInfo ?? 'No profile available'}

Write in clear, professional medical language. Be concise.
''';

    final response = await _tryGetResponse(prompt);
    _state = GemmaState.ready;
    notifyListeners();

    if (response != null && response.isNotEmpty) return response;
    return _basicSummary(context, profileInfo);
  }

  Future<String?> askFollowUp({
    required String context,
    required String userAnswer,
  }) async {
    _state = GemmaState.processing;
    notifyListeners();

    final prompt = '''
You are assisting with an emergency. Previous context:

$context

The person responded: "$userAnswer"

Based on this, what is the single most important follow-up question to ask?
Respond with ONLY the question, nothing else.
''';

    final response = await _tryGetResponse(prompt);
    _state = GemmaState.ready;
    notifyListeners();
    return response;
  }

  String _emergencyAnalysis(String description) {
    final e = _classify(description);
    return json.encode({
      'type': e['type'],
      'severity': e['severity'],
      'context': e['context'],
      'nextQuestion':
          'Can you provide more details about when and how this started?',
    });
  }

  String _structuredGuidance(String context) {
    final e = _classify(context);
    final t = e['type']!;

    Map<String, dynamic> guidance = _getGuidanceFor(t);

    return json.encode({
      'assessment': guidance['assessment'],
      'actions': guidance['actions'],
      'avoid': guidance['avoid'],
      'monitor': guidance['monitor'],
      'seekCare': guidance['seekCare'],
    });
  }

  Map<String, String> _classify(String description) {
    final d = description.toLowerCase();
    if (_hasAny(d, ['bleed', 'blood', 'haemorrhage', 'cut', 'wound'])) {
      return {
        'type': 'Bleeding',
        'severity': 'high',
        'context':
            'Active bleeding requires immediate action to control blood loss.',
      };
    }
    if (_hasAny(d, [
      'burn', 'fire', 'flame', 'hot oil', 'scald', 'boil',
    ])) {
      return {
        'type': 'Burn',
        'severity': 'high',
        'context':
            'Thermal injury from heat source. Requires cooling and protection.',
      };
    }
    if (_hasAny(d, ['break', 'fracture', 'bone', 'snap', 'crack'])) {
      return {
        'type': 'Fracture',
        'severity': 'medium',
        'context': 'Suspected bone fracture. Immobilisation needed.',
      };
    }
    if (_hasAny(d, [
      'allerg', 'reaction', 'swell', 'rash', 'hive', 'sting', 'itch',
    ])) {
      return {
        'type': 'Allergic Reaction',
        'severity': 'high',
        'context':
            'Allergic response with visible skin changes. Monitor breathing.',
      };
    }
    if (_hasAny(d, [
      'seizure', 'convulsion', 'fit', 'shaking', 'uncontrollable',
    ])) {
      return {
        'type': 'Seizure',
        'severity': 'critical',
        'context': 'Active seizure. Protect from injury and time the episode.',
      };
    }
    if (_hasAny(d, [
      'unconscious', 'faint', 'collapse', 'passed out', 'unresponsive',
      'blacked out',
    ])) {
      return {
        'type': 'Unconsciousness',
        'severity': 'critical',
        'context':
            'Person is unresponsive. Check airway and breathing immediately.',
      };
    }
    if (_hasAny(d, [
      'chok', 'breath', 'asthma', 'wheez', 'suffocat', 'cant breathe',
    ])) {
      return {
        'type': 'Breathing Emergency',
        'severity': 'high',
        'context':
            'Difficulty breathing requires immediate assessment and intervention.',
      };
    }
    if (_hasAny(d, [
      'poison', 'toxin', 'chemical', 'ingest', 'drank', 'swallowed',
    ])) {
      return {
        'type': 'Poisoning',
        'severity': 'high',
        'context':
            'Possible toxic ingestion. Identify the substance if possible.',
      };
    }
    if (_hasAny(d, [
      'snake', 'bite', 'bitten', 'animal', 'dog', 'scorpion', 'spider',
    ])) {
      return {
        'type': 'Snake or Animal Bite',
        'severity': 'high',
        'context':
            'Animal bite with possible envenomation. Keep calm and immobilise.',
      };
    }
    if (_hasAny(d, [
      'electric', 'shock', 'wire', 'voltage', 'electrocuted',
    ])) {
      return {
        'type': 'Electrical Injury',
        'severity': 'high',
        'context': 'Electrical contact injury. Ensure scene safety first.',
      };
    }
    if (_hasAny(d, [
      'accident', 'car', 'crash', 'motor', 'bike', 'road', 'vehicle',
      'collision',
    ])) {
      return {
        'type': 'Road Accident',
        'severity': 'high',
        'context': 'Vehicle-related trauma. Check for multiple injuries.',
      };
    }
    if (_hasAny(d, [
      'attack', 'assault', 'rob', 'mug', 'ambush', 'chase', 'knife', 'gun',
      'weapon',
    ])) {
      return {
        'type': 'Physical Assault',
        'severity': 'high',
        'context': 'Trauma from assault. Check for bleeding and fractures.',
      };
    }
    if (_hasAny(d, ['fall', 'fell', 'trip', 'slip', 'dropped'])) {
      return {
        'type': 'Fall',
        'severity': 'medium',
        'context': 'Fall-related injury. Check for head impact and fractures.',
      };
    }
    if (_hasAny(d, [
      'head', 'dizzy', 'headache', 'confused', 'concussion',
    ])) {
      return {
        'type': 'Head Injury',
        'severity': 'high',
        'context': 'Possible head trauma. Monitor consciousness closely.',
      };
    }
    return {
      'type': 'Medical Emergency',
      'severity': 'medium',
      'context':
          'General medical emergency. Assess the person and provide basic care.',
    };
  }

  bool _hasAny(String text, List<String> words) {
    return words.any((w) => text.contains(w));
  }

  Map<String, dynamic> _getGuidanceFor(String type) {
    switch (type) {
      case 'Bleeding':
        return {
          'assessment':
              'Active bleeding detected. The priority is to control blood loss while keeping the person calm.',
          'actions': [
            'Apply firm, direct pressure to the wound with a clean cloth',
            'Elevate the injured area above heart level if possible',
            'Keep the person lying down and warm',
            'Apply additional bandages on top if blood soaks through',
            'Call for emergency help immediately',
          ],
          'avoid': [
            'Do NOT remove embedded objects from the wound',
            'Do NOT apply a tourniquet unless bleeding is life-threatening',
            'Do NOT wash a major wound as it may increase bleeding',
            'Do NOT remove blood-soaked bandages; add more on top',
          ],
          'monitor': [
            'Colour of skin (pale or bluish = shock)',
            'Consciousness level and responsiveness',
            'Breathing rate and depth',
            'Amount of blood loss',
            'Signs of shock: cold sweat, rapid pulse, confusion',
          ],
          'seekCare':
              'Seek immediate medical care if bleeding does not stop after 10 minutes of pressure, if blood is spurting, or if the person shows signs of shock.',
        };
      case 'Burn':
        return {
          'assessment':
              'Thermal burn injury. Cooling the affected area is the immediate priority to limit tissue damage.',
          'actions': [
            'Cool the burn under cool running water for at least 20 minutes',
            'Remove any jewellery or tight clothing near the burn area',
            'Cover the burn loosely with a clean, dry cloth or cling film',
            'Keep the person warm to prevent shock',
            'Offer small sips of water if the person is conscious',
          ],
          'avoid': [
            'Do NOT apply ice or very cold water directly to the burn',
            'Do NOT break any blisters that form',
            'Do NOT apply butter, oil, toothpaste or any home remedies',
            'Do NOT remove clothing that is stuck to the burn',
          ],
          'monitor': [
            'Size and depth of the burn area',
            'Blister formation and colour',
            'Signs of shock: pale skin, rapid breathing, confusion',
            'Pain levels and response to cooling',
          ],
          'seekCare':
              "Seek medical care if the burn is larger than the person's palm, involves the face, hands, feet or joints, if there are large blisters, or if the person is a child or elderly.",
        };
      case 'Fracture':
        return {
          'assessment':
              'Suspected bone fracture. Immobilisation is critical to prevent further injury.',
          'actions': [
            'Keep the injured area completely still',
            'Support the injured limb with padding or a makeshift splint',
            'Apply ice wrapped in a cloth for 15-20 minutes to reduce swelling',
            'Keep the person still and comfortable',
            'Call for emergency assistance',
          ],
          'avoid': [
            'Do NOT attempt to straighten or realign the bone',
            'Do NOT move the person unless absolutely necessary',
            'Do NOT give the person food or drink (surgery may be needed)',
            'Do NOT apply a tight bandage around the injury',
          ],
          'monitor': [
            'Swelling and bruising around the injury',
            'Colour and temperature of fingers/toes below the injury',
            'Numbness or tingling in the affected limb',
            'Pain levels',
            'Signs of shock',
          ],
          'seekCare':
              'Seek immediate medical care. All suspected fractures need professional assessment and X-ray. Call emergency services for transport.',
        };
      case 'Allergic Reaction':
        return {
          'assessment':
              'Allergic reaction with visible symptoms. Monitor closely for signs of anaphylaxis which can be life-threatening.',
          'actions': [
            'Check if the person has an epinephrine auto-injector (EpiPen)',
            'If they do, help them use it immediately',
            'Keep the person sitting upright to help breathing',
            'Loosen any tight clothing around the neck',
            'Call for emergency help if symptoms are severe',
          ],
          'avoid': [
            'Do NOT give the person anything to eat or drink',
            'Do NOT leave the person alone',
            'Do NOT delay calling for help if symptoms worsen',
            'Do NOT apply anything to skin rashes unless prescribed',
          ],
          'monitor': [
            'Breathing difficulty or wheezing',
            'Swelling of lips, tongue or throat',
            'Change in voice or difficulty speaking',
            'Dizziness or fainting',
            'Spreading of rash or hives',
          ],
          'seekCare':
              'Call emergency services immediately if there is difficulty breathing, throat swelling, dizziness, or if the person has a known severe allergy and symptoms are progressing rapidly.',
        };
      case 'Snake or Animal Bite':
        return {
          'assessment':
              'Animal bite with possible envenomation. Keeping calm and immobile is critical to slow venom spread.',
          'actions': [
            'Keep the person as still and calm as possible',
            'Immobilise the bitten limb below heart level',
            'Remove any jewellery or tight clothing near the bite',
            'Note the time of the bite',
            'Transport to medical care immediately',
          ],
          'avoid': [
            'Do NOT apply a tourniquet',
            'Do NOT attempt to suck out venom',
            'Do NOT cut the wound or apply ice',
            'Do NOT give the person alcohol or caffeine',
            'Do NOT try to catch or kill the snake',
          ],
          'monitor': [
            'Swelling and colour change around the bite site',
            'Spreading numbness or tingling',
            'Nausea, vomiting or abdominal pain',
            'Breathing difficulty',
            'Consciousness level',
          ],
          'seekCare':
              'Seek IMMEDIATE medical care. All snake bites and animal bites that break the skin need professional assessment. Antivenom may be required.',
        };
      default:
        return {
          'assessment':
              'Based on the description, this situation requires careful monitoring and prompt action.',
          'actions': [
            'Stay calm and assess the situation carefully',
            'Ensure the scene is safe before approaching',
            'Check if the person is responsive and breathing normally',
            'Call for emergency help if available',
            'Provide basic first aid as appropriate',
          ],
          'avoid': [
            'Do NOT move the person unless absolutely necessary',
            'Do NOT give food or drink if the person is not fully alert',
            'Do NOT leave the person unattended',
          ],
          'monitor': [
            'Breathing rate and depth',
            'Level of consciousness',
            'Any changes in condition',
            'Skin colour and temperature',
          ],
          'seekCare':
              'Seek medical care if the condition worsens, if there is difficulty breathing, loss of consciousness, severe bleeding, or if you are unsure about the severity.',
        };
    }
  }

  String _basicSummary(String context, String? profileInfo) {
    final now = DateTime.now();
    return '''
MEDICAL SUMMARY
Date: ${now.day}/${now.month}/${now.year}
Time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}

EMERGENCY DESCRIPTION
$context

PATIENT PROFILE
${profileInfo ?? 'No medical profile available'}

ACTIONS TAKEN
Initial assessment and emergency guidance provided.

RECOMMENDED NEXT STEPS
Continue monitoring the person. Seek professional medical evaluation at the earliest opportunity. Share this summary with healthcare providers.

NOTE: This summary was generated for informational support. Please review with a qualified healthcare professional.
''';
  }

  String _buildEmergencyPrompt({
    required String description,
    String? imagePath,
    String? audioTranscription,
  }) {
    final parts = <String>[
      'You are assisting someone in an emergency situation.',
      'Based on the following information, determine the likely emergency context.',
      '',
      'User description: $description',
    ];

    if (audioTranscription != null && audioTranscription.isNotEmpty) {
      parts.add('Voice description: $audioTranscription');
    }

    if (imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync()) {
      parts.add('');
      parts.add('The user has also shared an image of the situation.');
    }

    parts.add('');
    parts.add(
        'What is the most likely emergency situation? Respond with a JSON object:');
    parts.add(json.encode({
      'type': 'emergency type',
      'severity': 'low/medium/high/critical',
      'context': 'brief analysis',
      'nextQuestion': 'one most important follow-up question',
    }));
    parts.add('');
    parts.add('Respond ONLY with valid JSON.');

    return parts.join('\n');
  }
}
