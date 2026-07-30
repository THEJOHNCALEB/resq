import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

enum GemmaState { checking, loading, ready, error }

class GemmaService extends ChangeNotifier {
  GemmaState _state = GemmaState.checking;
  String _error = '';

  GemmaState get state => _state;
  String get error => _error;
  bool get modelLoaded => _state == GemmaState.ready;

  static const _modelName = 'gemma-4-E2B-it.litertlm';
  static const _modelUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';

  Future<void> initialize() async {
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

      await FlutterGemma.getActiveModel(
        maxTokens: 2048,
        preferredBackend: PreferredBackend.cpu,
      );

      _state = GemmaState.ready;
    } catch (e) {
      _state = GemmaState.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<bool> _ensureModelInstalled() async {
    try {
      await FlutterGemma.getActiveModel(maxTokens: 1);
      return true;
    } catch (_) {}

    final paths = <String>[];
    final appDir = await getApplicationDocumentsDirectory();
    paths.add('${appDir.path}/$_modelName');

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) paths.add('${extDir.path}/$_modelName');
      } catch (_) {}
    }

    for (final p in paths) {
      if (File(p).existsSync()) {
        try {
          await FlutterGemma.installModel(
            modelType: ModelType.gemma4,
            fileType: ModelFileType.litertlm,
          ).fromFile(p).install();
          return true;
        } catch (_) {}
      }
    }

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

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(_modelUrl));
      final response = await request.close();

      final total = response.contentLength;
      var downloaded = 0;
      final tempFile = File('${file.path}.tmp');
      final sink = tempFile.openWrite();

      await for (final chunk in response) {
        downloaded += chunk.length;
        sink.add(chunk);
        if (total > 0 && onProgress != null) {
          onProgress(downloaded / total);
        }
      }
      await sink.close();
      client.close();

      await tempFile.rename(file.path);

      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(file.path).install();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> analyzeEmergency({
    required String userDescription,
    String? imagePath,
    String? audioTranscription,
  }) async {
    final model = await FlutterGemma.getActiveModel(maxTokens: 2048);
    final chat = await model.createChat(temperature: 0.7);

    final prompt = _buildEmergencyPrompt(
      description: userDescription,
      imagePath: imagePath,
      audioTranscription: audioTranscription,
    );

    await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
    final response = await chat.generateChatResponse();
    return switch (response) {
      TextResponse(:final token) => token,
      _ => '',
    };
  }

  Future<String> generateGuidance({required String context}) async {
    final model = await FlutterGemma.getActiveModel(maxTokens: 2048);
    final chat = await model.createChat(temperature: 0.7);

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

    await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
    final response = await chat.generateChatResponse();
    return switch (response) {
      TextResponse(:final token) => token,
      _ => '',
    };
  }

  Future<String> generateSummary({
    required String context,
    required String guidance,
    String? imagePath,
    String? profileInfo,
  }) async {
    final model = await FlutterGemma.getActiveModel(maxTokens: 2048);
    final chat = await model.createChat(temperature: 0.7);

    final prompt = '''
Generate a professional medical summary for healthcare providers. Include date and time, description of emergency, observed symptoms, visible findings, actions already taken, medical profile, AI assessment, and recommended next steps.

Emergency context: $context
Guidance provided: $guidance
Medical profile: ${profileInfo ?? 'None'}

Write in clear, professional language. Be concise.
''';

    await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
    final response = await chat.generateChatResponse();
    return switch (response) {
      TextResponse(:final token) => token,
      _ => '',
    };
  }

  String _buildEmergencyPrompt({
    required String description,
    String? imagePath,
    String? audioTranscription,
  }) {
    final parts = <String>[
      'You are assisting someone in an emergency situation.',
      'Determine the likely emergency context from the description below.',
      'Respond with JSON: {"type": "emergency type", "severity": "low/medium/high/critical", "context": "brief analysis", "nextQuestion": "one most important follow-up question"}',
      '',
      'User description: $description',
    ];

    if (audioTranscription != null && audioTranscription.isNotEmpty) {
      parts.add('Voice description: $audioTranscription');
    }

    if (imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync()) {
      parts.add('The user has also shared an image of the situation.');
    }

    parts.add('Respond ONLY with valid JSON.');
    return parts.join('\n');
  }
}
