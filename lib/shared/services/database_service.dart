import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  DatabaseService._();
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  Database? _database;

  Database get database {
    if (_database == null) throw StateError('Database not initialized');
    return _database!;
  }

  bool get isInitialized => _database != null;

  Future<void> initialize() async {
    if (_database != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'resq.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medical_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL DEFAULT '',
        age INTEGER NOT NULL DEFAULT 0,
        blood_group TEXT NOT NULL DEFAULT '',
        allergies TEXT NOT NULL DEFAULT '[]',
        medications TEXT NOT NULL DEFAULT '[]',
        conditions TEXT NOT NULL DEFAULT '[]',
        emergency_contacts TEXT NOT NULL DEFAULT '[]',
        address TEXT NOT NULL DEFAULT '',
        additional_notes TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE emergency_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        emergency_description TEXT NOT NULL DEFAULT '',
        image_paths TEXT NOT NULL DEFAULT '[]',
        audio_path TEXT NOT NULL DEFAULT '',
        emergency_type TEXT NOT NULL DEFAULT '',
        ai_assessment TEXT NOT NULL DEFAULT '',
        immediate_actions TEXT NOT NULL DEFAULT '[]',
        things_to_avoid TEXT NOT NULL DEFAULT '[]',
        monitor TEXT NOT NULL DEFAULT '[]',
        when_to_seek_care TEXT NOT NULL DEFAULT '',
        follow_up_questions TEXT NOT NULL DEFAULT '[]',
        follow_up_answers TEXT NOT NULL DEFAULT '[]',
        summary TEXT NOT NULL DEFAULT '',
        is_completed INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
