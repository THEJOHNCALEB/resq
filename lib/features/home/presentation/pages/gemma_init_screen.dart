import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/providers/app_providers.dart';

class GemmaInitScreen extends ConsumerStatefulWidget {
  const GemmaInitScreen({super.key});

  @override
  ConsumerState<GemmaInitScreen> createState() => _GemmaInitScreenState();
}

class _GemmaInitScreenState extends ConsumerState<GemmaInitScreen> {
  String _status = '';
  double _progress = 0;
  bool _downloading = false;
  bool _failed = false;
  String _error = '';
  DateTime? _downloadStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final gemma = ref.read(gemmaServiceProvider);

    setState(() => _status = 'Checking for AI model...');
    await Future.delayed(const Duration(milliseconds: 400));

    await gemma.initialize();

    if (!mounted) return;

    if (gemma.modelLoaded) {
      setState(() {
        _progress = 1.0;
        _status = 'AI ready';
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      context.go(AppRouter.home);
      return;
    }

    setState(() {
      _status = 'Gemma 4 model not found';
      _failed = true;
    });
  }

  Future<void> _download() async {
    final gemma = ref.read(gemmaServiceProvider);

    setState(() {
      _downloading = true;
      _failed = false;
      _progress = 0;
      _status = 'Connecting...';
      _downloadStart = DateTime.now();
    });

    final error = await gemma.downloadModel(
      onProgress: (p) {
        if (!mounted) return;
        final elapsed = DateTime.now().difference(_downloadStart!).inSeconds;
        final speed = elapsed > 0 && p > 0
            ? '${((2.4 * p) / elapsed * 60).toStringAsFixed(0)} MB/min'
            : '';

        setState(() {
          _progress = p;
          _status = speed.isNotEmpty
              ? '$speed  -  ${(p * 100).toStringAsFixed(0)}%'
              : 'Downloading... ${(p * 100).toStringAsFixed(0)}%';
        });
      },
    );

    if (!mounted) return;

    if (error == null) {
      setState(() {
        _progress = 1.0;
        _status = 'Installing model...';
      });

      await gemma.initialize();

      if (!mounted) return;

      if (gemma.modelLoaded) {
        setState(() => _status = 'AI ready');
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        context.go(AppRouter.home);
      } else {
        setState(() {
          _failed = true;
          _downloading = false;
          _error = 'Model installed but failed to load. Try restarting.';
        });
      }
    } else {
      setState(() {
        _failed = true;
        _downloading = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Gemma 4 E2B',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'ResQ needs the AI model to analyse emergencies.\n'
                  'It runs entirely on this device.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Text(
                    '~2.4 GB  -  Apache 2.0',
                    style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              if (_downloading) ...[
                Text(
                  _status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 8,
                    backgroundColor: AppColors.primary.withAlpha(20),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${(_progress * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              if (_failed && !_downloading) ...[
                if (_error.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.error.withAlpha(40)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              if (!_downloading)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _failed ? _download : _download,
                    icon: Icon(
                      _failed ? Icons.refresh_rounded : Icons.download_rounded,
                      size: 18,
                    ),
                    label: Text(_failed ? 'Retry download' : 'Download model'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'One-time download from Hugging Face.\nAfter this, everything stays on your device.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              if (_failed)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: TextButton(
                      onPressed: () => context.go(AppRouter.home),
                      child: const Text('Continue without AI'),
                    ),
                  ),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
