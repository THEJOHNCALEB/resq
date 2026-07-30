import 'package:flutter_test/flutter_test.dart';
import 'package:resq/features/emergency/data/models/emergency_session.dart';
import 'package:resq/features/medical_profile/data/models/medical_profile.dart';

void main() {
  group('EmergencySession', () {
    test('creates session with defaults', () {
      final session = EmergencySession();
      expect(session.emergencyDescription, isEmpty);
      expect(session.imagePaths, isEmpty);
      expect(session.isCompleted, isFalse);
      expect(session.immediateActions, isEmpty);
    });

    test('toJson and fromJson roundtrip', () {
      final session = EmergencySession(
        emergencyDescription: 'Snake bite on right ankle',
        emergencyType: 'Snake or Animal Bite',
        immediateActions: ['Keep calm', 'Immobilise limb'],
        thingsToAvoid: ['Do not apply tourniquet'],
        monitor: ['Swelling', 'Breathing'],
        whenToSeekCare: 'Seek immediate care if breathing difficulty',
        isCompleted: true,
      );

      final json = session.toJson();
      final restored = EmergencySession.fromJson(json);

      expect(restored.emergencyDescription, 'Snake bite on right ankle');
      expect(restored.emergencyType, 'Snake or Animal Bite');
      expect(restored.immediateActions, ['Keep calm', 'Immobilise limb']);
      expect(restored.isCompleted, isTrue);
    });
  });

  group('MedicalProfile', () {
    test('isComplete requires name, age, blood group', () {
      final profile = MedicalProfile();
      expect(profile.isComplete, isFalse);

      profile.name = 'Amina';
      profile.age = 24;
      expect(profile.isComplete, isFalse);

      profile.bloodGroup = 'O+';
      expect(profile.isComplete, isTrue);
    });

    test('toJson and fromJson preserve lists', () {
      final profile = MedicalProfile()
        ..name = 'Ibrahim'
        ..age = 21
        ..bloodGroup = 'A+'
        ..allergies = ['Penicillin', 'Peanuts']
        ..medications = ['Paracetamol']
        ..conditions = ['Asthma'];

      final json = profile.toJson();
      final restored = MedicalProfile.fromJson(json);

      expect(restored.name, 'Ibrahim');
      expect(restored.allergies, ['Penicillin', 'Peanuts']);
      expect(restored.medications, ['Paracetamol']);
      expect(restored.conditions, ['Asthma']);
    });
  });
}
