import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/calm_button.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/emergency_facility.dart';

class ContinueToCarePage extends ConsumerStatefulWidget {
  const ContinueToCarePage({super.key});

  @override
  ConsumerState<ContinueToCarePage> createState() => _ContinueToCarePageState();
}

class _ContinueToCarePageState extends ConsumerState<ContinueToCarePage> {
  List<EmergencyFacility> _facilities = [];
  bool _isLoadingFacilities = true;

  @override
  void initState() {
    super.initState();
    _loadFacilities();
  }

  Future<void> _loadFacilities() async {
    final locationService = ref.read(locationServiceProvider);
    final facilitiesService = ref.read(emergencyFacilitiesServiceProvider);

    await locationService.getCurrentLocation();
    await facilitiesService.loadFacilities();

    setState(() {
      _facilities = facilitiesService.getSortedByDistance();
      _isLoadingFacilities = false;
    });
  }

  Future<void> _openMaps() async {
    final facilitiesService = ref.read(emergencyFacilitiesServiceProvider);
    final nearest = facilitiesService.getNearestFacility();

    Uri url;
    if (nearest != null && nearest.latitude != 0 && nearest.longitude != 0) {
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query='
        '${Uri.encodeComponent(nearest.name)}'
        '&center=${nearest.latitude},${nearest.longitude}',
      );
    } else {
      url = Uri.parse('https://www.google.com/maps/search/hospital+near+me');
    }

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showNoInternet();
    }
  }

  void _showNoInternet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No internet connection. Displaying locally stored facilities.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Continue To Care'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 20),
                  _buildActionCard(
                    context,
                    theme,
                    icon: Icons.description_outlined,
                    title: 'Medical Summary',
                    subtitle: 'View the generated medical report',
                    onTap: () => context.push(AppRouter.summary),
                  ),
                  const SizedBox(height: 10),
                  _buildActionCard(
                    context,
                    theme,
                    icon: Icons.phone_outlined,
                    title: 'Call Emergency Contact',
                    subtitle: 'Contact your emergency person',
                    onTap: () {
                      final profile = ref.read(profileProvider).valueOrNull;
                      if (profile != null && profile.emergencyContacts.isNotEmpty) {
                        final firstContact = profile.emergencyContacts.first;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling $firstContact...')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No emergency contact set')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildActionCard(
                    context,
                    theme,
                    icon: Icons.share_outlined,
                    title: 'Share Report',
                    subtitle: 'Send the report to someone',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report sharing...')),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nearby Medical Facilities',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOpenMapsButton(theme),
                  const SizedBox(height: 12),
                  if (_isLoadingFacilities)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_facilities.isEmpty)
                    _buildEmptyFacilities(theme)
                  else
                    ..._facilities.map((f) => _buildFacilityCard(theme, f)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            _buildBottomBar(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: AppIcon(
                Icons.favorite_rounded,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'re doing great.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here are your next steps to continue care.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onPrimaryContainer,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppIcon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
    );
  }

  Widget _buildOpenMapsButton(ThemeData theme) {
    return CalmButton(
      label: 'Open Google Maps',
      icon: Icons.map_outlined,
      isPrimary: false,
      isFullWidth: true,
      onPressed: _openMaps,
    );
  }

  Widget _buildEmptyFacilities(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          AppIcon(Icons.location_off_outlined, size: 40, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'No facilities loaded',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'Add facilities to assets/data/emergency_facilities.json',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(ThemeData theme, EmergencyFacility facility) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AppIcon(
                      facility.type == 'Hospital'
                          ? Icons.local_hospital_rounded
                          : facility.type == 'Pharmacy'
                              ? Icons.local_pharmacy_rounded
                              : Icons.medical_services_rounded,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          facility.type,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (facility.distanceKm > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.safe.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${facility.distanceKm.toStringAsFixed(1)} km',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.safe,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (facility.address.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    AppIcon(Icons.location_on_outlined, size: 16, color: AppColors.outline),
                    const SizedBox(width: 6),
                    Text(
                      facility.address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              if (facility.phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    AppIcon(Icons.phone_outlined, size: 16, color: AppColors.outline),
                    const SizedBox(width: 6),
                    Text(
                      facility.phone,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
              if (facility.hours.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    AppIcon(Icons.access_time_rounded, size: 16, color: AppColors.outline),
                    const SizedBox(width: 6),
                    Text(
                      facility.hours,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(color: AppColors.background),
      child: CalmButton(
        label: 'Return Home',
        icon: Icons.home_rounded,
        isPrimary: true,
        isFullWidth: true,
        onPressed: () => context.go(AppRouter.home),
      ),
    );
  }
}
