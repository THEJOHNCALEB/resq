import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../core/privacy_monitor.dart';

class HomeTab extends ConsumerStatefulWidget {
  final VoidCallback onStartEmergency;

  const HomeTab({super.key, required this.onStartEmergency});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showPrivacy() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PrivacySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemma = ref.watch(gemmaServiceProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ResQ',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -1,
                        fontSize: 28,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: gemma.modelLoaded ? AppColors.safe : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          gemma.modelLoaded ? 'Gemma 4' : 'Offline',
                          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _showPrivacy,
                  child: ListenableBuilder(
                    listenable: PrivacyMonitor.instance,
                    builder: (context, _) {
                      final count = PrivacyMonitor.instance.count;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: count == 0 ? AppColors.safe.withAlpha(15) : AppColors.error.withAlpha(15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, size: 12, color: count == 0 ? AppColors.safe : AppColors.error),
                            const SizedBox(width: 4),
                            Text(
                              count == 0 ? '0' : '$count',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: count == 0 ? AppColors.safe : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(scale: _pulseAnimation.value, child: child),
            child: GestureDetector(
              onTap: widget.onStartEmergency,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emergency,
                  boxShadow: [
                    BoxShadow(color: AppColors.emergency.withAlpha(50), blurRadius: 28, spreadRadius: 6),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppIcon(Icons.warning_rounded, color: Colors.white, size: 42),
                    const SizedBox(height: 4),
                    Text(
                      'Start\nEmergency',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, height: 1.2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Tap for immediate guidance', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                _FeatureChip(icon: Icons.wifi_off_rounded, label: 'Offline'),
                const SizedBox(width: 10),
                _FeatureChip(icon: Icons.psychology_outlined, label: 'Gemma 4'),
                const SizedBox(width: 10),
                _FeatureChip(icon: Icons.lock_outline_rounded, label: 'Private'),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AppColors.primary.withAlpha(10), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PrivacySheet extends StatelessWidget {
  const _PrivacySheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: ListenableBuilder(
        listenable: PrivacyMonitor.instance,
        builder: (context, _) {
          final count = PrivacyMonitor.instance.count;
          final hosts = PrivacyMonitor.instance.hosts;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: count == 0 ? AppColors.safe.withAlpha(15) : AppColors.error.withAlpha(15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(count == 0 ? Icons.shield_rounded : Icons.warning_rounded, size: 28, color: count == 0 ? AppColors.safe : AppColors.error),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(count == 0 ? 'Privacy Verified' : '$count Request${count > 1 ? 's' : ''}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(count == 0 ? 'No data has ever left this device.' : 'Network activity detected', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.primary.withAlpha(8), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How this works', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Text('Every HTTP request is intercepted and counted. After the initial model download, the counter should remain at zero. This is a live measurement, not a claim.', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant, height: 1.5)),
                  ],
                ),
              ),
              if (hosts.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Requested hosts', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...hosts.map((h) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(h, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11)))),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Got it'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
