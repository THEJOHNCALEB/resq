import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/guidance_card.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../features/emergency/data/models/emergency_session.dart';

class SessionDetailPage extends ConsumerWidget {
  final int sessionId;

  const SessionDetailPage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(sessionHistoryProvider);

    return AppScaffold(
      title: 'Session Detail',
      child: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (sessions) {
          final session = sessions.where((s) => s.id == sessionId).firstOrNull;
          if (session == null) {
            return const Center(child: Text('Session not found'));
          }
          return _buildSessionDetail(context, theme, session);
        },
      ),
    );
  }

  Widget _buildSessionDetail(
    BuildContext context,
    ThemeData theme,
    EmergencySession session,
  ) {
    final dateFormatter = DateFormat('MMMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildMetadataCard(theme, session, dateFormatter, timeFormatter),
        const SizedBox(height: 12),
        if (session.emergencyDescription.isNotEmpty)
          _buildTextSection(
            theme,
            'Description',
            Icons.description_outlined,
            session.emergencyDescription,
          ),
        if (session.aiAssessment.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildTextSection(
            theme,
            'Assessment',
            Icons.psychology_outlined,
            session.aiAssessment,
          ),
        ],
        if (session.immediateActions.isNotEmpty) ...[
          const SizedBox(height: 12),
          GuidanceCard(
            title: 'Actions Taken',
            icon: Icons.checklist_rounded,
            color: AppColors.safe,
            items: session.immediateActions,
          ),
        ],
        if (session.thingsToAvoid.isNotEmpty) ...[
          const SizedBox(height: 12),
          GuidanceCard(
            title: 'Things Avoided',
            icon: Icons.close_rounded,
            color: AppColors.error,
            items: session.thingsToAvoid,
          ),
        ],
        if (session.monitor.isNotEmpty) ...[
          const SizedBox(height: 12),
          GuidanceCard(
            title: 'Monitored',
            icon: Icons.visibility_rounded,
            color: AppColors.warning,
            items: session.monitor,
          ),
        ],
        if (session.summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildTextSection(
            theme,
            'Medical Summary',
            Icons.description_outlined,
            session.summary,
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMetadataCard(
    ThemeData theme,
    EmergencySession session,
    DateFormat dateFormatter,
    DateFormat timeFormatter,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AppIcon(
                    Icons.description_outlined,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  session.emergencyType.isNotEmpty
                      ? session.emergencyType
                      : 'General Emergency',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildMetadataRow(theme, 'Date', dateFormatter.format(session.createdAt)),
            const SizedBox(height: 8),
            _buildMetadataRow(theme, 'Time', timeFormatter.format(session.createdAt)),
            const SizedBox(height: 8),
            _buildMetadataRow(theme, 'Status', 'Completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextSection(
    ThemeData theme,
    String title,
    IconData icon,
    String content,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppIcon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
