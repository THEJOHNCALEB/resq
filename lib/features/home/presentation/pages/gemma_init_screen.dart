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
  bool _checking = true;
  String _error = '';

  void _showErrorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _ErrorSheet(
        error: _error,
        onRetry: () {
          Navigator.pop(context);
          _download();
        },
        onSkip: () {
          Navigator.pop(context);
          context.go(AppRouter.home);
        },
      ),
    );
  }

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
        _checking = false;
      });
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      context.go(AppRouter.home);
      return;
    }

    setState(() {
      _checking = false;
      _failed = false;
    });
  }

  void _afterDownloadFailed(String err) {
    final friendly =
        err.contains('network') ||
            err.contains('Socket') ||
            err.contains('connection')
        ? 'Network error. Check your connection and try again.'
        : err.contains('storage') ||
              err.contains('space') ||
              err.contains('disk')
        ? 'Not enough storage. Free up space and try again.'
        : 'Download failed. Check your connection and retry.';
    setState(() {
      _failed = true;
      _downloading = false;
      _error = friendly;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _showErrorSheet());
  }

  Future<void> _download() async {
    final gemma = ref.read(gemmaServiceProvider);

    setState(() {
      _downloading = true;
      _failed = false;
      _progress = 0;
      _status = 'Preparing your offline companion...';
    });

    final error = await gemma.downloadModel(
      onProgress: (p) {
        if (!mounted) return;

        String msg;
        if (p < 0.1) {
          msg = 'Getting your offline experience ready...';
        } else if (p < 0.4) {
          msg = 'Downloading emergency intelligence...';
        } else if (p < 0.7) {
          msg = 'Almost halfway there...';
        } else if (p < 0.9) {
          msg = 'Finishing up... ${(p * 100).toStringAsFixed(0)}%';
        } else if (p < 1.0) {
          msg = 'Just a moment...';
        } else {
          msg = 'Download complete';
        }

        setState(() {
          _progress = p;
          _status = msg;
        });
      },
    );

    if (!mounted) return;

    if (error == null) {
      setState(() {
        _progress = 1.0;
        _status = 'Setting everything up...';
      });

      await gemma.initialize();

      if (!mounted) return;

      if (gemma.modelLoaded) {
        setState(() => _status = 'You are all set');
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        context.go(AppRouter.home);
      } else {
        _afterDownloadFailed('Could not activate AI model. Restart the app.');
      }
    } else {
      _afterDownloadFailed(error);
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
                  if (_checking) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: AppColors.primary.withAlpha(20),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Checking offline intelligence...',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (!_checking && _downloading) ...[
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
                  if (!_checking &&
                      !_failed &&
                      !_downloading &&
                      _progress < 1) ...[
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.storage_rounded,
                              size: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '~2.4 GB',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.lock_outline,
                              size: 12,
                              color: AppColors.safe,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Apache 2.0',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.safe,
                              ),
                            ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Download AI Model'),
                      ),
                    ),
                  ],
                  if (_failed && !_downloading) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _download,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry download'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRouter.home),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Continue'),
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

class _ErrorSheet extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  const _ErrorSheet({
    required this.error,
    required this.onRetry,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.cloud_download_rounded,
              size: 28,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Download Interrupted',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your progress is saved — the download will\nresume from where it stopped.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.warning,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Resume download'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSkip,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Continue without AI'),
            ),
          ),
        ],
      ),
    );
  }
}
