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

    await Future.delayed(const Duration(milliseconds: 400));

    await gemma.initialize();

    if (!mounted) return;

    if (gemma.modelLoaded) {
      setState(() {
        _progress = 1.0;
        _status = 'Ready';
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      context.go(AppRouter.home);
      return;
    }

    setState(() {
      _status = 'Model not found';
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
              ? '$speed  ·  ${(p * 100).toStringAsFixed(0)}%'
              : '${(p * 100).toStringAsFixed(0)}%';
        });
      },
    );

    if (!mounted) return;

    if (error == null) {
      setState(() {
        _progress = 1.0;
        _status = 'Installing...';
      });

      await gemma.initialize();

      if (!mounted) return;

      if (gemma.modelLoaded) {
        setState(() => _status = 'Ready');
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        context.go(AppRouter.home);
      } else {
        setState(() {
          _failed = true;
          _downloading = false;
          _error = 'Could not activate AI model. Restart the app.';
        });
      }
    } else {
      final friendly = error.contains('network') || error.contains('Socket') || error.contains('connection')
          ? 'Network error. Check your connection and try again.'
          : error.contains('storage') || error.contains('space') || error.contains('disk')
              ? 'Not enough storage. Free up space and try again.'
              : 'Download failed. Check your connection and retry.';
      setState(() {
        _failed = true;
        _downloading = false;
        _error = friendly;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ResQ',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: -2,
                      fontSize: 64,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Offline Emergency Intelligence',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 32,
              right: 32,
              bottom: 48,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_downloading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        minHeight: 4,
                        backgroundColor: AppColors.primary.withAlpha(20),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _status,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (_failed && !_downloading) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.error.withAlpha(30)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _error.isNotEmpty ? _error : 'Could not load AI model',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _download,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextButton(
                                  onPressed: () => context.go(AppRouter.home),
                                  child: const Text('Skip'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!_failed && !_downloading && _progress < 1) ...[
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.storage_rounded, size: 12, color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 6),
                            const Text('~2.4 GB', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                            const SizedBox(width: 10),
                            const Icon(Icons.lock_outline, size: 12, color: AppColors.safe),
                            const SizedBox(width: 4),
                            const Text('Apache 2.0', style: TextStyle(fontSize: 11, color: AppColors.safe)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _download,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Download AI Model'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
