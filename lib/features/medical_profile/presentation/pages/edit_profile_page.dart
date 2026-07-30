import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/medical_profile.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _bloodCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medsCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  final _contactsCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider).whenData((p) {
        if (p != null) {
          _nameCtrl.text = p.name;
          _ageCtrl.text = p.age > 0 ? '${p.age}' : '';
          _bloodCtrl.text = p.bloodGroup;
          _allergiesCtrl.text = p.allergies.join(', ');
          _medsCtrl.text = p.medications.join(', ');
          _conditionsCtrl.text = p.conditions.join(', ');
          _contactsCtrl.text = p.emergencyContacts.join(', ');
          _addressCtrl.text = p.address;
          _notesCtrl.text = p.additionalNotes;
        }
      });
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _bloodCtrl.dispose();
    _allergiesCtrl.dispose();
    _medsCtrl.dispose();
    _conditionsCtrl.dispose();
    _contactsCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;

    setState(() => _saving = true);

    final p = MedicalProfile()
      ..name = _nameCtrl.text.trim()
      ..age = int.tryParse(_ageCtrl.text.trim()) ?? 0
      ..bloodGroup = _bloodCtrl.text.trim().toUpperCase()
      ..allergies = _split(_allergiesCtrl.text)
      ..medications = _split(_medsCtrl.text)
      ..conditions = _split(_conditionsCtrl.text)
      ..emergencyContacts = _split(_contactsCtrl.text)
      ..address = _addressCtrl.text.trim()
      ..additionalNotes = _notesCtrl.text.trim();

    await ref.read(profileProvider.notifier).saveProfile(p);

    setState(() => _saving = false);
    if (mounted) context.pop();
  }

  List<String> _split(String text) {
    return text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medical Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _section('Personal'),
          const SizedBox(height: 12),
          _field('Full Name', _nameCtrl, TextInputType.name, required: true),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field('Age', _ageCtrl, TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field('Blood Group', _bloodCtrl, TextInputType.text, hint: 'A+, B-, O+')),
          ]),
          const SizedBox(height: 28),
          _section('Medical'),
          const SizedBox(height: 12),
          _field('Allergies', _allergiesCtrl, TextInputType.text, hint: 'Penicillin, peanuts'),
          const SizedBox(height: 12),
          _field('Medications', _medsCtrl, TextInputType.text, hint: 'Separate with commas'),
          const SizedBox(height: 12),
          _field('Conditions', _conditionsCtrl, TextInputType.text, hint: 'Asthma, diabetes'),
          const SizedBox(height: 28),
          _section('Emergency Contacts'),
          const SizedBox(height: 12),
          _field('Contacts', _contactsCtrl, TextInputType.text, hint: 'Name: +2348012345678', maxLines: 2),
          const SizedBox(height: 12),
          _field('Address', _addressCtrl, TextInputType.text, hint: 'Your address'),
          const SizedBox(height: 28),
          _section('Additional'),
          const SizedBox(height: 12),
          _field('Notes', _notesCtrl, TextInputType.text, hint: 'Other relevant information', maxLines: 3),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, letterSpacing: 0.5));
  }

  Widget _field(String label, TextEditingController ctrl, TextInputType type, {String? hint, int maxLines = 1, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.outline, fontSize: 14),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
