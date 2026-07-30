import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../features/emergency/data/models/emergency_session.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(sessionHistoryProvider);

    return AppScaffold(
      title: 'Care History',
      child: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return _buildEmptyState(context, theme);
          }
          return _buildHistoryList(context, theme, sessions);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: AppIcon(
              Icons.history_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'No Previous Sessions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your emergency history will appear here after you complete an emergency session.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    ThemeData theme,
    List<EmergencySession> sessions,
  ) {
    final dateFormatter = DateFormat('MMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final date = dateFormatter.format(session.createdAt);
        final time = timeFormatter.format(session.createdAt);
        final type = session.emergencyType.isNotEmpty
            ? session.emergencyType
            : 'General Emergency';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                context.push(
                  AppRouter.sessionDetail.replaceAll(
                    ':sessionId',
                    '${session.id}',
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AppIcon(
                        _getTypeIcon(type),
                        size: 24,
                        color: _getTypeColor(type),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$date at $time',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppIcon(
                      Icons.chevron_right_rounded,
                      color: AppColors.outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'bleeding':
      case 'burn':
        return AppColors.error;
      case 'fracture':
      case 'fall':
        return AppColors.warning;
      case 'allergic reaction':
      case 'asthma attack':
        return AppColors.tertiary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bleeding':
        return Icons.bloodtype_rounded;
      case 'burn':
        return Icons.local_fire_department_rounded;
      case 'fracture':
      case 'fall':
        return Icons.medical_services_rounded;
      case 'allergic reaction':
        return Icons.sick_rounded;
      case 'asthma attack':
        return Icons.air_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }
}
