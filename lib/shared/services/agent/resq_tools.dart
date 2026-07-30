import 'package:flutter_gemma/flutter_gemma.dart';
import '../../../features/medical_profile/data/models/medical_profile.dart';
import '../../../features/continue_to_care/data/models/emergency_facility.dart';

const List<Tool> resqTools = [
  Tool(
    name: 'get_medical_profile',
    description:
        'Get the stored medical profile of the person needing help. Use this '
        'to check allergies, medications, conditions, blood type, and '
        'emergency contacts before giving any guidance.',
    parameters: {
      'type': 'object',
      'properties': <String, dynamic>{},
      'required': <String>[],
    },
  ),
  Tool(
    name: 'get_nearby_facilities',
    description:
        'Get the nearest hospitals, clinics, and emergency facilities from '
        'the local offline database. Use this to tell the user exactly where '
        'to go for professional care.',
    parameters: {
      'type': 'object',
      'properties': {
        'limit': {
          'type': 'integer',
          'description': 'Maximum number of facilities to return. Default 3.',
        },
      },
      'required': <String>[],
    },
  ),
];

class ResQToolExecutor {
  ResQToolExecutor({
    this.medicalProfile,
    this.facilities = const [],
  });

  final MedicalProfile? medicalProfile;
  final List<EmergencyFacility> facilities;

  String run(String name, Map<String, dynamic> args) {
    switch (name) {
      case 'get_medical_profile':
        return _formatProfile();

      case 'get_nearby_facilities':
        final limit = _asInt(args['limit']) ?? 3;
        return _formatFacilities(limit);

      default:
        return 'error=unknown tool: $name';
    }
  }

  String _formatProfile() {
    final p = medicalProfile;
    if (p == null) return 'No medical profile stored on this device.';
    final parts = <String>[];
    if (p.name.isNotEmpty) parts.add('name=${p.name}');
    if (p.age > 0) parts.add('age=${p.age}');
    if (p.bloodGroup.isNotEmpty) parts.add('blood_group=${p.bloodGroup}');
    if (p.allergies.isNotEmpty) {
      parts.add('allergies=${p.allergies.join("; ")}');
    }
    if (p.medications.isNotEmpty) {
      parts.add('medications=${p.medications.join("; ")}');
    }
    if (p.conditions.isNotEmpty) {
      parts.add('conditions=${p.conditions.join("; ")}');
    }
    if (p.emergencyContacts.isNotEmpty) {
      parts.add('emergency_contacts=${p.emergencyContacts.join("; ")}');
    }
    if (p.additionalNotes.isNotEmpty) {
      parts.add('notes=${p.additionalNotes}');
    }
    return parts.isEmpty ? 'Profile exists but is empty.' : parts.join(', ');
  }

  String _formatFacilities(int limit) {
    if (facilities.isEmpty) {
      return 'No facilities in local database. Advise the user to find the nearest hospital.';
    }
    final limited = facilities.take(limit).toList();
    return limited.map((f) {
      final dist =
          f.distanceKm > 0 ? ' (${f.distanceKm.toStringAsFixed(1)} km)' : '';
      final phone = f.phone.isNotEmpty ? ' Phone: ${f.phone}' : '';
      return '${f.name} — ${f.type}$dist — ${f.address}$phone';
    }).join(' | ');
  }

  int? _asInt(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse('$v'));
}
