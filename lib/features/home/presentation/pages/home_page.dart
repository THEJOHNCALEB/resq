import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/providers/app_providers.dart';
import 'home_tab.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _tab = 0;

  void _startEmergency() {
    ref.read(currentEmergencyProvider.notifier).startNewSession();
    context.push(AppRouter.emergencyFlow);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _tab,
        children: [
          HomeTab(onStartEmergency: _startEmergency),
          _buildHistoryTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer(
      builder: (context, ref, _) {
        final sessions = ref.watch(sessionHistoryProvider).valueOrNull ?? [];

        if (sessions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const AppIcon(Icons.history_rounded, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  const Text('No past sessions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Your emergency history will appear here', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: sessions.length.clamp(0, 3),
          itemBuilder: (context, i) {
            final s = sessions[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const AppIcon(Icons.medical_services_rounded, size: 20, color: AppColors.primary),
                ),
                title: Text(s.emergencyType.isNotEmpty ? s.emergencyType : 'Emergency', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                subtitle: Text('${s.createdAt.day}/${s.createdAt.month}/${s.createdAt.year}', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return Consumer(
      builder: (context, ref, _) {
        final profile = ref.watch(profileProvider).valueOrNull;
        final theme = Theme.of(context);

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            if (profile != null && profile.isComplete) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.primary.withAlpha(15), borderRadius: BorderRadius.circular(16)), child: const AppIcon(Icons.person_outline_rounded, size: 28, color: AppColors.primary)),
                      const SizedBox(height: 12),
                      Text(profile.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${profile.age} yrs  ·  ${profile.bloodGroup}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                      if (profile.allergies.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(spacing: 6, runSpacing: 6, children: profile.allergies.map((a) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.warning.withAlpha(15), borderRadius: BorderRadius.circular(8)), child: Text(a, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.warning)))).toList()),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => context.push(AppRouter.profile), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('View Full Profile'))),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.primary.withAlpha(12), borderRadius: BorderRadius.circular(18)), child: const AppIcon(Icons.person_outline_rounded, size: 32, color: AppColors.primary)),
                      const SizedBox(height: 20),
                      const Text('No profile yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Add your medical information for better emergency guidance', textAlign: TextAlign.center, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                      const SizedBox(height: 20),
                      FilledButton.icon(onPressed: () => context.push(AppRouter.editProfile), icon: const AppIcon(Icons.add_rounded, size: 18), label: const Text('Create Profile'), style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            selected: _tab == 2,
            onTap: () => setState(() => _tab = 2),
          ),
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: _tab == 0,
            isCenter: true,
            onTap: () => setState(() => _tab = 0),
          ),
          _NavItem(
            icon: Icons.history_rounded,
            label: 'History',
            selected: _tab == 1,
            onTap: () => setState(() => _tab = 1),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isCenter;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.isCenter = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? AppColors.primary : AppColors.outline;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCenter ? 24 : 20,
          vertical: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Container(
                width: 28,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(height: 3),
            const SizedBox(height: 6),
            AppIcon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
