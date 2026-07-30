import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/providers/app_providers.dart';

class GemmaInitScreen extends ConsumerStatefulWidget {
  const GemmaInitScreen({super.key});

  @override
  ConsumerState<GemmaInitScreen> createState() => _GemmaInitScreenState();
}

class _GemmaInitScreenState extends ConsumerState<GemmaInitScreen>
    with SingleTickerProviderStateMixin {
  bool _done = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideUp = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Permission.storage.request();

    final gemma = ref.read(gemmaServiceProvider);
    await gemma.initialize();

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() => _done = true);

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    context.go(AppRouter.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeIn.value,
              child: Transform.translate(
                offset: Offset(0, _slideUp.value),
                child: child,
              ),
            );
          },
          child: Center(
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
                if (!_done)
                  SizedBox(
                    width: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: AppColors.primary.withAlpha(20),
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
