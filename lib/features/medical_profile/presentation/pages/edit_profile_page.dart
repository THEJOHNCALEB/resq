import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/calm_button.dart';
import '../../data/models/medical_profile.dart';
import '../../../../shared/providers/app_providers.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;
  late TextEditingController _conditionsController;
  late TextEditingController _contactsController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _bloodGroupController = TextEditingController();
    _allergiesController = TextEditingController();
    _medicationsController = TextEditingController();
    _conditionsController = TextEditingController();
    _contactsController = TextEditingController();
    _addressController = TextEditingController();
    _notesController = TextEditingController();

    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    ref.read(profileProvider).whenData((profile) {
      if (profile != null) {
        _nameController.text = profile.name;
        _ageController.text = profile.age > 0 ? '${profile.age}' : '';
        _bloodGroupController.text = profile.bloodGroup;
        _allergiesController.text = profile.allergies.join(', ');
        _medicationsController.text = profile.medications.join(', ');
        _conditionsController.text = profile.conditions.join(', ');
        _contactsController.text = profile.emergencyContacts.join(', ');
        _addressController.text = profile.address;
        _notesController.text = profile.additionalNotes;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _conditionsController.dispose();
    _contactsController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final profile = MedicalProfile()
      ..name = _nameController.text.trim()
      ..age = int.tryParse(_ageController.text.trim()) ?? 0
      ..bloodGroup = _bloodGroupController.text.trim().toUpperCase()
      ..allergies = _parseList(_allergiesController.text)
      ..medications = _parseList(_medicationsController.text)
      ..conditions = _parseList(_conditionsController.text)
      ..emergencyContacts = _parseList(_contactsController.text)
      ..address = _addressController.text.trim()
      ..additionalNotes = _notesController.text.trim();

    await ref.read(profileProvider.notifier).saveProfile(profile);

    setState(() => _isSaving = false);

    if (mounted) {
      context.pop();
    }
  }

  List<String> _parseList(String text) {
    return text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Edit Profile',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _buildSectionTitle(context, 'Personal Information'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
              required: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _ageController,
                    label: 'Age',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                    required: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _bloodGroupController,
                    label: 'Blood Group',
                    icon: Icons.bloodtype_outlined,
                    hint: 'A+, B-, O+, etc.',
                    required: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildSectionTitle(context, 'Medical Information'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _allergiesController,
              label: 'Allergies',
              icon: Icons.warning_amber_rounded,
              hint: 'Penicillin, Latex, Peanuts, etc.',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _medicationsController,
              label: 'Current Medication',
              icon: Icons.medication_rounded,
              hint: 'Separate with commas',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _conditionsController,
              label: 'Medical Conditions',
              icon: Icons.local_hospital_rounded,
              hint: 'Diabetes, Asthma, Hypertension, etc.',
            ),
            const SizedBox(height: 28),
            _buildSectionTitle(context, 'Emergency Contacts'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _contactsController,
              label: 'Contacts',
              icon: Icons.phone_outlined,
              hint: 'Name: +1234567890, Name: +0987654321',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              icon: Icons.location_on_outlined,
              hint: 'Your current address',
            ),
            const SizedBox(height: 28),
            _buildSectionTitle(context, 'Additional'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _notesController,
              label: 'Additional Notes',
              icon: Icons.notes_rounded,
              hint: 'Any other relevant medical information',
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            CalmButton(
              label: 'Save Profile',
              icon: Icons.check_rounded,
              isPrimary: true,
              isFullWidth: true,
              isLoading: _isSaving,
              onPressed: _saveProfile,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        prefixIcon: AppIcon(icon, size: 22),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
    );
  }
}
