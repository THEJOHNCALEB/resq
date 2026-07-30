import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'agent/resq_tools.dart';
import 'agent/resq_agent.dart';
import '../../features/medical_profile/data/models/medical_profile.dart';
import '../../features/continue_to_care/data/models/emergency_facility.dart';

enum GemmaState { checking, loading, ready, error }

class GemmaService extends ChangeNotifier {
  GemmaState _state = GemmaState.checking;
  String _error = '';
  InferenceModel? _model;

  GemmaState get state => _state;
  String get error => _error;
  bool get modelLoaded => _state == GemmaState.ready && _model != null;

  static const _modelName = 'gemma-4-E2B-it.litertlm';
  static const _modelUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';

  Future<void> initialize() async {
    if (_state == GemmaState.ready) return;
    if (_state == GemmaState.loading) return;

    _state = GemmaState.checking;
    notifyListeners();

    try {
      final installed = await _ensureModelInstalled();
      if (!installed) {
        _state = GemmaState.error;
        _error = 'Model not found';
        notifyListeners();
        return;
      }

      _state = GemmaState.loading;
      notifyListeners();

      _model = await FlutterGemma.getActiveModel(
        maxTokens: 2048,
        preferredBackend: PreferredBackend.cpu,
      ).timeout(const Duration(seconds: 90), onTimeout: () {
        throw Exception('Model loading timed out');
      });

      _state = GemmaState.ready;
    } catch (e) {
      debugPrint('[ResQ] GemmaService init: $e');
      _state = GemmaState.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<bool> _ensureModelInstalled() async {
    try {
      await FlutterGemma.getActiveModel(maxTokens: 1);
      return true;
    } catch (e) {
      debugPrint('[ResQ] No active model: $e');
    }

    final paths = <String>[];
    final appDir = await getApplicationDocumentsDirectory();
    paths.add('${appDir.path}/$_modelName');

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) paths.add('${extDir.path}/$_modelName');
      } catch (e) {
        debugPrint('[ResQ] No external storage: $e');
      }
    }

    for (final p in paths) {
      if (File(p).existsSync()) {
        try {
          await FlutterGemma.installModel(
            modelType: ModelType.gemma4,
            fileType: ModelFileType.litertlm,
          ).fromFile(p).install();
          debugPrint('[ResQ] Model installed from: $p');
          return true;
        } catch (e) {
          debugPrint('[ResQ] Install failed from $p: $e');
        }
      }
    }

    debugPrint('[ResQ] No model file found in any path');
    return false;
  }

  Future<String?> downloadModel({
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_modelName');

      if (await file.exists()) {
        await FlutterGemma.installModel(
          modelType: ModelType.gemma4,
          fileType: ModelFileType.litertlm,
        ).fromFile(file.path).install();
        return null;
      }

      final tmpFile = File('${file.path}.tmp');
      int existingBytes = 0;
      if (tmpFile.existsSync()) {
        existingBytes = tmpFile.lengthSync();
      }

      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(_modelUrl));
        if (existingBytes > 0) {
          request.headers.set('Range', 'bytes=$existingBytes-');
        }
        final response = await request.close();

        int totalBytes;
        RandomAccessFile raf;

        if (response.statusCode == 206) {
          final contentRange = response.headers.value('content-range');
          if (contentRange != null && contentRange.contains('/')) {
            totalBytes = int.parse(contentRange.split('/').last);
          } else {
            totalBytes = existingBytes + response.contentLength;
          }
          raf = tmpFile.openSync(mode: FileMode.append);
        } else if (response.statusCode == 200) {
          totalBytes = response.contentLength;
          existingBytes = 0;
          raf = tmpFile.openSync(mode: FileMode.write);
        } else {
          throw HttpException(
              'Download failed with status ${response.statusCode}');
        }

        int downloaded = existingBytes;
        await for (final chunk in response) {
          raf.writeFromSync(chunk);
          downloaded += chunk.length;
          if (totalBytes > 0 && onProgress != null) {
            onProgress(downloaded / totalBytes);
          }
        }
        await raf.close();

        if (file.existsSync()) file.deleteSync();
        tmpFile.renameSync(file.path);
      } finally {
        client.close();
      }

      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(file.path).install();

      return null;
    } catch (e) {
      debugPrint('[ResQ] Download error: $e');
      return e.toString();
    }
  }

  Future<String> generateGuidance({
    required String context,
    String? imagePath,
    String? audioPath,
  }) async {
    if (_model == null) {
      await initialize();
      if (_model == null) return '';
    }
    final model = _model!;

    final prompt = '''
You are an emergency response assistant. Based on the following emergency context, provide structured guidance. Format your response as JSON:

{
  "assessment": "Brief current assessment of the situation",
  "actions": ["Action 1", "Action 2"],
  "avoid": ["Avoid this", "Avoid that"],
  "monitor": ["Monitor sign 1", "Monitor sign 2"],
  "seekCare": "When to seek immediate medical care"
}

Emergency context: $context

Respond ONLY with valid JSON.
''';

    try {
      final hasImage = imagePath != null && File(imagePath).existsSync();

      final session = await model.createSession(
        temperature: 0.0,
        topK: 1,
        maxOutputTokens: 1024,
        enableVisionModality: hasImage,
      );

      if (hasImage) {
        final bytes = await File(imagePath).readAsBytes();
        await session.addQueryChunk(Message.withImage(
          text: prompt,
          imageBytes: bytes,
          isUser: true,
        ));
      } else {
        await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      }

      final result = await session.getResponse();
      debugPrint('[ResQ] Guidance generated (${result.length} chars)');
      return result;
    } catch (e) {
      debugPrint('[ResQ] Guidance failed: $e');
      return '';
    }
  }

  Future<InferenceChat> createEmergencyChat({
    MedicalProfile? profile,
    List<EmergencyFacility> facilities = const [],
  }) async {
    final m = _model;
    if (m == null) throw Exception('Model not loaded');
    return m.createChat(
      modelType: ModelType.gemma4,
      supportsFunctionCalls: true,
      toolChoice: ToolChoice.auto,
      maxOutputTokens: 1024,
      tools: resqTools,
      systemInstruction: 'You are ResQ, a calm, direct emergency response '
          'assistant for people in urgent situations. You provide structured '
          'guidance for first aid and emergency care. Use the tools to get '
          'real information before answering — never guess medical details, '
          'profile data, or facility names. Keep replies clear, actionable, '
          'and step-by-step. Prioritise life-saving actions. Do not panic '
          'the user. Ask clarifying questions if the emergency is unclear.',
    );
  }

  Future<AgentTurn> agentGuidance({
    required String emergencyDescription,
    String? imagePath,
    String? audioPath,
    MedicalProfile? profile,
    List<EmergencyFacility> facilities = const [],
  }) async {
    final chat = await createEmergencyChat(
      profile: profile,
      facilities: facilities,
    );
    final executor = ResQToolExecutor(
      medicalProfile: profile,
      facilities: facilities,
    );
    final agent = ResQAgent(chat, executor);

    final parts = <String>[
      'Emergency description: $emergencyDescription',
    ];
    if (audioPath != null && audioPath.isNotEmpty) {
      parts.add('(The user also provided a voice recording of the emergency.)');
    }

    final prompt = '''
${parts.join('\n')}

Provide structured emergency guidance as JSON. Include only the card types
that are relevant to this specific emergency:

{
  "cards": [
    {
      "title": "Card title (e.g. Assessment, Immediate Actions, Pain Management)",
      "color": "hex colour code (e.g. #2563EB)",
      "type": "text or list",
      "content": "text string, or for list type an array of strings",
      "icon": "Material icon name (e.g. psychology_outlined)"
    }
  ]
}

Choose card titles and content that are specific to this emergency. Do not
include irrelevant cards. Use the tools to get the patient's medical profile
and nearby facilities before writing the guidance.
Respond ONLY with valid JSON.''';

    return agent.ask(prompt);
  }

  Future<String> generateSummary({
    required String context,
    required String guidance,
    String? imagePath,
    String? profileInfo,
  }) async {
    if (_model == null) return '';

    final model = _model!;
    final prompt = '''
Generate a professional medical summary for healthcare providers. Include date and time, description of emergency, observed symptoms, visible findings, actions already taken, medical profile, AI assessment, and recommended next steps.

Emergency context: $context
Guidance provided: $guidance
Medical profile: ${profileInfo ?? 'None'}

Write in clear, professional language. Be concise.
''';

    try {
      final session = await model.createSession(
        temperature: 0.0,
        topK: 1,
        maxOutputTokens: 1024,
      );

      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      final result = await session.getResponse();
      debugPrint('[ResQ] Summary generated (${result.length} chars)');
      return result;
    } catch (e) {
      debugPrint('[ResQ] Summary failed: $e');
      return '';
    }
  }

  Future<String> analyzeEmergency({
    required String userDescription,
    String? imagePath,
    String? audioPath,
  }) async {
    if (_model == null) {
      await initialize();
      if (_model == null) return '';
    }
    final model = _model!;

    final prompt = '''
You are assisting someone in an emergency situation. Determine the likely emergency context from the description below.
Respond with JSON: {"type": "emergency type", "severity": "low/medium/high/critical", "context": "brief analysis", "nextQuestion": "one most important follow-up question"}

User description: $userDescription

Respond ONLY with valid JSON.
''';

    try {
      final hasImage = imagePath != null && File(imagePath).existsSync();

      final session = await model.createSession(
        temperature: 0.0,
        topK: 1,
        maxOutputTokens: 512,
        enableVisionModality: hasImage,
      );

      if (hasImage) {
        final bytes = await File(imagePath).readAsBytes();
        await session.addQueryChunk(Message.withImage(
          text: prompt,
          imageBytes: bytes,
          isUser: true,
        ));
      } else {
        await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      }

      final result = await session.getResponse();
      debugPrint('[ResQ] Analysis generated (${result.length} chars)');
      return result;
    } catch (e) {
      debugPrint('[ResQ] Analysis failed: $e');
      return '';
    }
  }
}
