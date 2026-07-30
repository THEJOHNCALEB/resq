import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'app.dart';
import 'shared/services/database_service.dart';
import 'shared/services/gemma_service.dart';
import 'shared/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService.instance.initialize();

  await FlutterGemma.initialize();

  final gemmaService = GemmaService();
  await gemmaService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        gemmaServiceProvider.overrideWith((ref) => gemmaService),
      ],
      child: const ResQApp(),
    ),
  );
}
