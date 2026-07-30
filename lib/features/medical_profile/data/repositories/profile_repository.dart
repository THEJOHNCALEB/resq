import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/medical_profile.dart';

class ProfileRepository {
  static const _key = 'medical_profile';
  final _storage = const FlutterSecureStorage();

  Future<MedicalProfile?> getProfile() async {
    final json = await _storage.read(key: _key);
    if (json == null) return null;
    try {
      return MedicalProfile.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(MedicalProfile profile) async {
    await _storage.write(key: _key, value: jsonEncode(profile.toJson()));
  }

  Future<void> deleteProfile() async {
    await _storage.delete(key: _key);
  }

  Future<bool> hasProfile() async {
    return await _storage.containsKey(key: _key);
  }
}
