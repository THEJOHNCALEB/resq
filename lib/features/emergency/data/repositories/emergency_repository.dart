import 'dart:convert';
import '../models/emergency_session.dart';
import '../../../../shared/services/database_service.dart';

class EmergencyRepository {
  final DatabaseService _db;

  EmergencyRepository(this._db);

  Future<int> createSession(EmergencySession session) async {
    final id = await _db.database.insert('emergency_sessions', _toRow(session));
    return id;
  }

  Future<EmergencySession?> getSession(int id) async {
    final results = await _db.database.query(
      'emergency_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return _fromRow(results.first);
  }

  Future<void> updateSession(EmergencySession session) async {
    if (session.id == null) return;
    await _db.database.update(
      'emergency_sessions',
      _toRow(session),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<EmergencySession>> getAllSessions() async {
    final results = await _db.database.query(
      'emergency_sessions',
      orderBy: 'created_at DESC',
    );
    return results.map(_fromRow).toList();
  }

  Future<List<EmergencySession>> getCompletedSessions() async {
    final results = await _db.database.query(
      'emergency_sessions',
      where: 'is_completed = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return results.map(_fromRow).toList();
  }

  Future<EmergencySession?> getMostRecentSession() async {
    final results = await _db.database.query(
      'emergency_sessions',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return _fromRow(results.first);
  }

  Future<void> deleteSession(int id) async {
    await _db.database.delete(
      'emergency_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getSessionCount() async {
    final count = await _db.database.rawQuery(
      'SELECT COUNT(*) as cnt FROM emergency_sessions',
    );
    return count.first['cnt'] as int;
  }

  Map<String, dynamic> _toRow(EmergencySession s) {
    return {
      if (s.id != null) 'id': s.id,
      'created_at': s.createdAt.toIso8601String(),
      'emergency_description': s.emergencyDescription,
      'image_paths': json.encode(s.imagePaths),
      'audio_path': s.audioPath,
      'emergency_type': s.emergencyType,
      'ai_assessment': s.aiAssessment,
      'immediate_actions': json.encode(s.immediateActions),
      'things_to_avoid': json.encode(s.thingsToAvoid),
      'monitor': json.encode(s.monitor),
      'when_to_seek_care': s.whenToSeekCare,
      'follow_up_questions': json.encode(s.followUpQuestions),
      'follow_up_answers': json.encode(s.followUpAnswers),
      'summary': s.summary,
      'is_completed': s.isCompleted ? 1 : 0,
    };
  }

  EmergencySession _fromRow(Map<String, dynamic> row) {
    return EmergencySession(
      id: row['id'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      emergencyDescription: row['emergency_description'] as String,
      imagePaths: List<String>.from(json.decode(row['image_paths'] as String)),
      audioPath: row['audio_path'] as String,
      emergencyType: row['emergency_type'] as String,
      aiAssessment: row['ai_assessment'] as String,
      immediateActions: List<String>.from(json.decode(row['immediate_actions'] as String)),
      thingsToAvoid: List<String>.from(json.decode(row['things_to_avoid'] as String)),
      monitor: List<String>.from(json.decode(row['monitor'] as String)),
      whenToSeekCare: row['when_to_seek_care'] as String,
      followUpQuestions: List<String>.from(json.decode(row['follow_up_questions'] as String)),
      followUpAnswers: List<String>.from(json.decode(row['follow_up_answers'] as String)),
      summary: row['summary'] as String,
      isCompleted: (row['is_completed'] as int) == 1,
    );
  }
}
