import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/privacy_monitor.dart';
import 'shared/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PrivacyMonitor.instance.install();

  await DatabaseService.instance.initialize();

  const token = String.fromEnvironment('HUGGINGFACE_TOKEN');

  await FlutterGemma.initialize(
    inferenceEngines: const [LiteRtLmEngine()],
    huggingFaceToken: token.isNotEmpty ? token : null,
  );

  runApp(const ProviderScope(child: ResQApp()));
}
