import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/guidance_card.dart';
import '../../../../shared/providers/app_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);

    return AppScaffold(
      title: 'Medical Profile',
      actions: [
        TextButton.icon(
          onPressed: () {
            context.push(AppRouter.editProfile);
          },
          icon: AppIcon(Icons.edit_outlined, size: 18),
          label: const Text('Edit'),
        ),
      ],
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (profile) {
          if (profile == null || !profile.isComplete) {
            return _buildEmptyState(context, theme);
          }
          return _buildProfileContent(context, theme, profile);
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
              Icons.person_outline_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'No Medical Profile',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create a medical profile to help emergency services understand your needs faster.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.push(AppRouter.editProfile),
            icon: AppIcon(Icons.add_rounded),
            label: const Text('Create Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    ThemeData theme,
    dynamic profile,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        StatusCard(
          title: 'Name',
          value: profile.name,
          icon: Icons.person_outline_rounded,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatusCard(
                title: 'Age',
                value: '${profile.age} years',
                icon: Icons.cake_outlined,
                color: AppColors.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatusCard(
                title: 'Blood Group',
                value: profile.bloodGroup,
                icon: Icons.bloodtype_outlined,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        if (profile.allergies.isNotEmpty) ...[
          const SizedBox(height: 12),
          GuidanceCard(
            title: 'Allergies',
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
            items: profile.allergies,
          ),
        ],
        if (profile.medications.isNotEmpty) ...[
          const SizedBox(height: 12),
          GuidanceCard(
            title: 'Current Medication',
            icon: Icons.medication_rounded,
            color: AppColors.primary,
            items: profile.medications,
          ),
        ],
        if (profile.conditions.isNotEmpty) ...[
          const SizedBox(height: 12),
          GuidanceCard(
            title: 'Medical Conditions',
            icon: Icons.local_hospital_rounded,
            color: AppColors.tertiary,
            items: profile.conditions,
          ),
        ],
        if (profile.emergencyContacts.isNotEmpty) ...[
          const SizedBox(height: 12),
          GuidanceCard(
            title: 'Emergency Contacts',
            icon: Icons.phone_outlined,
            color: AppColors.safe,
            items: profile.emergencyContacts,
          ),
        ],
        if (profile.address.isNotEmpty) ...[
          const SizedBox(height: 12),
          StatusCard(
            title: 'Address',
            value: profile.address,
            icon: Icons.location_on_outlined,
            color: AppColors.secondary,
          ),
        ],
        if (profile.additionalNotes.isNotEmpty) ...[
          const SizedBox(height: 12),
          GuidanceCard(
            title: 'Additional Notes',
            icon: Icons.notes_rounded,
            color: AppColors.onSurfaceVariant,
            items: [profile.additionalNotes],
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}
