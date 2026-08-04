import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../shared/widgets/app_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/calm_button.dart';
import '../../../../shared/widgets/guidance_card.dart';
import '../../../../shared/providers/app_providers.dart';

class SummaryPage extends ConsumerWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final emergency = ref.watch(currentEmergencyProvider);
    final profile = ref.watch(profileProvider).valueOrNull;

    if (emergency == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Medical Summary')),
        body: const Center(child: Text('No emergency data available')),
      );
    }

    final dateFormatter = DateFormat('MMMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medical Summary'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _buildHeader(context, theme, emergency, dateFormatter, timeFormatter),
                  const SizedBox(height: 16),
                  if (profile != null) ...[
                    GuidanceCard(
                      title: 'Medical Profile',
                      icon: Icons.person_outline_rounded,
                      color: AppColors.primary,
                      items: [
                        'Name: ${profile.name}',
                        'Age: ${profile.age}',
                        'Blood Group: ${profile.bloodGroup}',
                        if (profile.allergies.isNotEmpty) 'Allergies: ${profile.allergies.join(", ")}',
                        if (profile.medications.isNotEmpty) 'Medication: ${profile.medications.join(", ")}',
                        if (profile.conditions.isNotEmpty) 'Conditions: ${profile.conditions.join(", ")}',
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (emergency.emergencyDescription.isNotEmpty)
                    _SummarySection(
                      title: 'Emergency Description',
                      content: emergency.emergencyDescription,
                      icon: Icons.description_outlined,
                    ),
                  const SizedBox(height: 12),
                  if (emergency.aiAssessment.isNotEmpty) ...[
                    _SummarySection(
                      title: 'AI Assessment',
                      content: emergency.aiAssessment,
                      icon: Icons.psychology_outlined,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (emergency.immediateActions.isNotEmpty)
                    GuidanceCard(
                      title: 'Actions Taken',
                      icon: Icons.checklist_rounded,
                      color: AppColors.safe,
                      items: emergency.immediateActions,
                    ),
                  if (emergency.thingsToAvoid.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    GuidanceCard(
                      title: 'Things Avoided',
                      icon: Icons.close_rounded,
                      color: AppColors.error,
                      items: emergency.thingsToAvoid,
                    ),
                  ],
                  if (emergency.followUpQuestions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    GuidanceCard(
                      title: 'Additional Information',
                      icon: Icons.question_answer_rounded,
                      color: AppColors.tertiary,
                      items: List.generate(
                        emergency.followUpQuestions.length,
                        (i) => 'Q: ${emergency.followUpQuestions[i]}\nA: ${emergency.followUpAnswers.length > i ? emergency.followUpAnswers[i] : "N/A"}',
                      ),
                    ),
                  ],
                  if (emergency.summary.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _SummarySection(
                      title: 'Comprehensive Summary',
                      content: emergency.summary,
                      icon: Icons.description_outlined,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildDisclaimer(theme),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            _buildBottomBar(context, ref, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    dynamic emergency,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medical Summary',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'For healthcare professionals',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow(theme, 'Date', dateFormatter.format(emergency.createdAt)),
            const SizedBox(height: 8),
            _buildInfoRow(theme, 'Time', timeFormatter.format(emergency.createdAt)),
            const SizedBox(height: 8),
            _buildInfoRow(
              theme,
              'Emergency Type',
              emergency.emergencyType.isNotEmpty ? emergency.emergencyType : 'General Emergency',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
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

  Widget _buildDisclaimer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withAlpha(40),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          AppIcon(Icons.info_outline_rounded, size: 20, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This is an AI-generated summary. It should be reviewed by a healthcare professional and does not replace professional medical judgment.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(color: AppColors.background),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CalmButton(
            label: 'Continue to Care',
            icon: Icons.send_rounded,
            isPrimary: true,
            isFullWidth: true,
            onPressed: () {
              if (context.mounted) {
                context.go(AppRouter.continueToCare);
              }
            },
          ),
          const SizedBox(height: 12),
          CalmButton(
            label: 'Share Report',
            icon: Icons.share_outlined,
            isPrimary: false,
            isFullWidth: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report sharing initiated...')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _SummarySection({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            MarkdownBody(
              data: content,
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant, height: 1.6),
                h1: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                h2: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                h3: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                strong: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
