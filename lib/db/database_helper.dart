import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'smriti.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Patients table — one row per patient profile on this device
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        preferred_language TEXT NOT NULL DEFAULT 'en',
        daily_routine TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Game sessions table — one row per round played, across all 4 games
    await db.execute('''
      CREATE TABLE game_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        game_type TEXT NOT NULL,
        difficulty_tier INTEGER NOT NULL DEFAULT 1,
        accuracy REAL NOT NULL,
        response_time_seconds REAL NOT NULL,
        correct_answers INTEGER NOT NULL,
        total_answers INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');

    // Reminders table — medicine, hydration, activity, appointment reminders
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        scheduled_time TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        completed_at TEXT,
        synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');
  }

  // ---------- Patients ----------

  Future<int> insertPatient(Map<String, dynamic> patient) async {
    final db = await database;
    return await db.insert('patients', patient);
  }

  Future<List<Map<String, dynamic>>> getPatients() async {
    final db = await database;
    return await db.query('patients');
  }

  // Ensures at least one patient exists so a game session has someone to
  // attach to. Real patient-profile creation belongs to a caregiver
  // onboarding flow that doesn't exist yet — this stands in for it.
  Future<void> updatePatientRoutine(int patientId, String dailyRoutine) async {
    final db = await database;
    await db.update(
      'patients',
      {'daily_routine': dailyRoutine},
      where: 'id = ?',
      whereArgs: [patientId],
    );
  }

  Future<int> getOrCreateDefaultPatient() async {
    final patients = await getPatients();
    if (patients.isNotEmpty) {
      return patients.first['id'] as int;
    }
    return await insertPatient({
      'name': 'Patient',
      'preferred_language': 'en',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ---------- Game sessions ----------

  Future<int> insertGameSession(Map<String, dynamic> session) async {
    final db = await database;
    return await db.insert('game_sessions', session);
  }

  // Last N rounds for a patient — used by the Tier 0 rule engine
  Future<List<Map<String, dynamic>>> getRecentSessions(
    int patientId,
    String gameType, {
    int limit = 5,
  }) async {
    final db = await database;
    return await db.query(
      'game_sessions',
      where: 'patient_id = ? AND game_type = ?',
      whereArgs: [patientId, gameType],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSessions() async {
    final db = await database;
    return await db.query('game_sessions', where: 'synced = 0');
  }

  Future<void> markSessionSynced(int id) async {
    final db = await database;
    await db.update(
      'game_sessions',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------- Reminders ----------

  Future<int> insertReminder(Map<String, dynamic> reminder) async {
    final db = await database;
    return await db.insert('reminders', reminder);
  }

  Future<List<Map<String, dynamic>>> getRemindersForPatient(
    int patientId,
  ) async {
    final db = await database;
    return await db.query(
      'reminders',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'scheduled_time ASC',
    );
  }

  Future<int> markReminderStatus(
    int reminderId,
    String status, {
    String? completedAt,
  }) async {
    final db = await database;
    return await db.update(
      'reminders',
      // Resetting synced back to 0 is what makes this change actually
      // reach Supabase — without it, a reminder that already synced once
      // (as "pending") would never be picked up again by
      // getUnsyncedReminders() after being marked done, since that only
      // looks for synced = 0. This was a real bug: status changes were
      // silently never syncing at all.
      {'status': status, 'completed_at': completedAt, 'synced': 0},
      where: 'id = ?',
      whereArgs: [reminderId],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedReminders() async {
    final db = await database;
    return await db.query('reminders', where: 'synced = 0');
  }

  Future<void> markReminderSynced(int id) async {
    final db = await database;
    await db.update(
      'reminders',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}