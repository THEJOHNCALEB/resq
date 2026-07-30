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
  String _status = 'Preparing...';
  double _progress = 0;
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final gemma = ref.read(gemmaServiceProvider);

    setState(() {
      _status = 'Checking for AI model...';
      _progress = 0.15;
    });

    await gemma.initialize();

    if (!mounted) return;

    if (gemma.modelLoaded) {
      setState(() {
        _status = 'AI ready';
        _progress = 1.0;
      });
    } else {
      setState(() {
        _status = 'Downloading AI model...';
        _progress = 0.2;
      });

      final error = await gemma.downloadModel(
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _progress = 0.2 + p * 0.7;
              _status = 'Downloading AI model... ${(p * 100).round()}%';
            });
          }
        },
      );

      if (!mounted) return;

      if (error == null) {
        setState(() {
          _status = 'Download complete. Loading...';
          _progress = 0.95;
        });
        await gemma.initialize();
        setState(() {
          _status = 'AI ready';
          _progress = 1.0;
        });
      } else {
        setState(() {
          _status = 'Could not download model';
          _showRetry = true;
          _progress = 1.0;
        });
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (gemma.modelLoaded) {
      context.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ResQ',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -2,
                    fontSize: 72,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Offline Emergency Intelligence',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 4,
                      backgroundColor: AppColors.primary.withAlpha(20),
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _status,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (_showRetry) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _showRetry = false;
                        _progress = 0;
                      });
                      _init();
                    },
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go(AppRouter.home),
                    child: const Text('Continue offline'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
