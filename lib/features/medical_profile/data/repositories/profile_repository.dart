import 'dart:convert';
import '../models/medical_profile.dart';
import '../../../../shared/services/database_service.dart';

class ProfileRepository {
  final DatabaseService _db;

  ProfileRepository(this._db);

  Future<MedicalProfile?> getProfile() async {
    final results = await _db.database.query(
      'medical_profile',
      limit: 1,
    );

    if (results.isEmpty) return null;

    final row = results.first;
    return MedicalProfile()
      ..name = row['name'] as String
      ..age = row['age'] as int
      ..bloodGroup = row['blood_group'] as String
      ..allergies = List<String>.from(json.decode(row['allergies'] as String))
      ..medications = List<String>.from(json.decode(row['medications'] as String))
      ..conditions = List<String>.from(json.decode(row['conditions'] as String))
      ..emergencyContacts = List<String>.from(json.decode(row['emergency_contacts'] as String))
      ..address = row['address'] as String
      ..additionalNotes = row['additional_notes'] as String;
  }

  Future<void> saveProfile(MedicalProfile profile) async {
    final existing = await getProfile();
    final data = {
      'name': profile.name,
      'age': profile.age,
      'blood_group': profile.bloodGroup,
      'allergies': json.encode(profile.allergies),
      'medications': json.encode(profile.medications),
      'conditions': json.encode(profile.conditions),
      'emergency_contacts': json.encode(profile.emergencyContacts),
      'address': profile.address,
      'additional_notes': profile.additionalNotes,
    };

    if (existing != null) {
      await _db.database.update(
        'medical_profile',
        data,
        where: 'id = ?',
        whereArgs: [1],
      );
    } else {
      await _db.database.insert('medical_profile', data);
    }
  }

  Future<void> deleteProfile() async {
    await _db.database.delete('medical_profile');
  }

  Future<bool> hasProfile() async {
    final count = await _db.database.rawQuery(
      'SELECT COUNT(*) as cnt FROM medical_profile',
    );
    return (count.first['cnt'] as int) > 0;
  }
}
