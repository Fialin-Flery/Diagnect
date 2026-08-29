import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'package:diagnect/models/report_model.dart';
import 'package:diagnect/models/medical_history_model.dart';


class LocalDatabase {
  LocalDatabase._privateConstructor();

  static final LocalDatabase instance =
  LocalDatabase._privateConstructor();

  Database? _database;

// =========================================================
// DATABASE
// =========================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

// =========================================================
// INIT
// =========================================================

  Future<Database> _initDatabase() async {
    final databasePath =
    await getDatabasesPath();

    final dbPath = path.join(
      databasePath,
      'diagnect.db',
    );

    return openDatabase(
      dbPath,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

// =========================================================
// CREATE
// =========================================================

  Future<void> _onCreate(
      Database db,
      int version,
      ) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        verification_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY,
        user_id TEXT,
        name TEXT,
        date_of_birth TEXT,
        blood_group TEXT,
        abha_number TEXT,
        profile_completed INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        hospital TEXT,
        type TEXT NOT NULL,
        description TEXT,
        file_path TEXT,
        file_paths TEXT,
        file_type TEXT,
        report_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE medical_histories (
        id INTEGER PRIMARY KEY,
        user_id TEXT NOT NULL UNIQUE,
        height_cm REAL,
        weight_kg REAL,
        sex TEXT,
        allergies TEXT,
        chronic_conditions TEXT,
        current_medications TEXT,
        hiv_aids INTEGER,
        smoking INTEGER,
        alcohol INTEGER,
        emergency_contact TEXT,
        additional_notes TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT
      )
    ''');
  }

// =========================================================
// UPGRADE
// =========================================================

  Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
/*
     * Version 2:
     * Add reports table.
     */

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reports (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT,
          title TEXT NOT NULL,
          hospital TEXT,
          type TEXT NOT NULL,
          description TEXT,
          file_path TEXT,
          report_date TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

/*
     * Version 3:
     * Multi-file report support.
     */

    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE reports ADD COLUMN user_id TEXT',
        );
      } catch (_) {}

      try {
        await db.execute(
          'ALTER TABLE reports ADD COLUMN file_paths TEXT',
        );
      } catch (_) {}

      try {
        await db.execute(
          'ALTER TABLE reports ADD COLUMN file_type TEXT',
        );
      } catch (_) {}
    }

/*
     * Version 4:
     * Make sure multi-file columns exist.
     */

    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE reports ADD COLUMN file_paths TEXT',
        );
      } catch (_) {}

      try {
        await db.execute(
          'ALTER TABLE reports ADD COLUMN file_type TEXT',
        );
      } catch (_) {}
    }

/*
     * Version 5:
     * Medical history.
     */

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS medical_histories (
          id INTEGER PRIMARY KEY,
          user_id TEXT NOT NULL UNIQUE,
          height_cm REAL,
          weight_kg REAL,
          sex TEXT,
          allergies TEXT,
          chronic_conditions TEXT,
          current_medications TEXT,
          hiv_aids INTEGER,
          smoking INTEGER,
          alcohol INTEGER,
          emergency_contact TEXT,
          additional_notes TEXT,
          completed INTEGER NOT NULL DEFAULT 0,
          updated_at TEXT
        )
      ''');
    }
  }

// =========================================================
// SESSION
// =========================================================

  Future<void> saveSession({
    required String userId,
    String? verificationId,
  }) async {
    final db = await database;

    await db.delete('sessions');

    await db.insert(
      'sessions',
      {
        'user_id': userId,
        'verification_id':
        verificationId,
        'created_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      },
    );
  }

  Future<Map<String, dynamic>?>
  getSession() async {
    final db = await database;

    final result = await db.query(
      'sessions',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

// =========================================================
// PROFILE
// =========================================================

  Future<void> saveProfile(
      Map<String, dynamic> profile,
      ) async {
    final db = await database;

    final userId =
    profile['user_id']?.toString();

    await db.insert(
      'profiles',
      {
        'id': 1,
        'user_id': userId,
        'name':
        profile['name']?.toString(),
        'date_of_birth':
        profile['date_of_birth']
            ?.toString(),
        'blood_group':
        profile['blood_group']
            ?.toString(),
        'abha_number':
        profile['abha_number']
            ?.toString(),
        'profile_completed':
        profile['profile_completed']
            == true
            ? 1
            : 0,
        'updated_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      },
      conflictAlgorithm:
      ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?>
  getProfile() async {
    final db = await database;

    final result = await db.query(
      'profiles',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    final row = result.first;

    return {
      'user_id': row['user_id'],
      'name': row['name'],
      'date_of_birth':
      row['date_of_birth'],
      'blood_group':
      row['blood_group'],
      'abha_number':
      row['abha_number'],
      'profile_completed':
      row['profile_completed'] == 1,
      'updated_at':
      row['updated_at'],
    };
  }

// =========================================================
// MEDICAL HISTORY
// =========================================================

  Future<void> saveMedicalHistory(
      MedicalHistoryModel history,
      String userId,
      ) async {
    final db = await database;

    await db.insert(
      'medical_histories',
      {
        'id': 1,

        'user_id':
        userId,

        'height_cm':
        history.heightCm,

        'weight_kg':
        history.weightKg,

        'sex':
        history.sex,

        'allergies':
        jsonEncode(
          history.allergies,
        ),

        'chronic_conditions':
        history.chronicConditions,

        'current_medications':
        history.currentMedications,

        'hiv_aids':
        history.hivAids == null
            ? null
            : history.hivAids!
            ? 1
            : 0,

        'smoking':
        history.smoking == null
            ? null
            : history.smoking!
            ? 1
            : 0,

        'alcohol':
        history.alcohol == null
            ? null
            : history.alcohol!
            ? 1
            : 0,

        'emergency_contact':
        history.emergencyContact,

        'additional_notes':
        history.additionalNotes,

        'completed':
        history.completed
            ? 1
            : 0,

        'updated_at':
        history.updatedAt ??
            DateTime.now()
                .toUtc()
                .toIso8601String(),
      },
      conflictAlgorithm:
      ConflictAlgorithm.replace,
    );
  }

  Future<MedicalHistoryModel?>
  getMedicalHistory(
      String userId,
      ) async {
    final db = await database;

    final result = await db.query(
      'medical_histories',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    final row = result.first;

    List<String> allergies = [];

    final rawAllergies =
    row['allergies'];

    if (rawAllergies != null) {
      try {
        final decoded =
        jsonDecode(
          rawAllergies.toString(),
        );

        if (decoded is List) {
          allergies =
              decoded
                  .map(
                    (item) =>
                    item.toString(),
              )
                  .where(
                    (item) =>
                item.trim().isNotEmpty,
              )
                  .toList();
        }
      } catch (_) {}
    }

    return MedicalHistoryModel(
      id:
      row['id'] as int?,

      userId:
      row['user_id']?.toString(),

      heightCm:
      _toDouble(
        row['height_cm'],
      ),

      weightKg:
      _toDouble(
        row['weight_kg'],
      ),

      sex:
      row['sex']?.toString(),

      allergies:
      allergies,

      chronicConditions:
      row['chronic_conditions']
          ?.toString(),

      currentMedications:
      row['current_medications']
          ?.toString(),

      hivAids:
      _toNullableBool(
        row['hiv_aids'],
      ),

      smoking:
      _toNullableBool(
        row['smoking'],
      ),

      alcohol:
      _toNullableBool(
        row['alcohol'],
      ),

      emergencyContact:
      row['emergency_contact']
          ?.toString(),

      additionalNotes:
      row['additional_notes']
          ?.toString(),

      completed:
      row['completed'] == 1,

      updatedAt:
      row['updated_at']
          ?.toString(),
    );
  }

  Future<void> deleteMedicalHistory(
      String userId,
      ) async {
    final db = await database;

    await db.delete(
      'medical_histories',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  double? _toDouble(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  bool? _toNullableBool(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is bool) {
      return value;
    }

    return null;
  }

// =========================================================
// REPORTS
// =========================================================

  Future<int> insertReport(
      ReportModel report,
      ) async {
    final db = await database;

    return db.insert(
      'reports',
      report.toMap(),
      conflictAlgorithm:
      ConflictAlgorithm.replace,
    );
  }

  Future<List<ReportModel>> getReports(
      String userId,
      ) async {
    final db = await database;

    final result = await db.query(
      'reports',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy:
      'report_date DESC, id DESC',
    );

    return result
        .map(
      ReportModel.fromMap,
    )
        .toList();
  }

  Future<void> deleteReport(
      int id,
      String userId,
      ) async {
    final db = await database;

    await db.delete(
      'reports',
      where:
      'id = ? AND user_id = ?',
      whereArgs: [
        id,
        userId,
      ],
    );
  }

// =========================================================
// CLEAR SESSION ONLY
// =========================================================

  Future<void> clearSessionData() async {
    final db = await database;

/*
     * IMPORTANT:
     *
     * Do NOT delete:
     * - profiles
     * - medical histories
     * - reports
     *
     * They belong to the authenticated user
     * and can be reused after login.
     */

    await db.delete(
      'sessions',
    );
  }

// =========================================================
// FULL RESET
// =========================================================

  Future<void> clearAll() async {
    final db = await database;

    await db.delete(
      'sessions',
    );

    await db.delete(
      'profiles',
    );

    await db.delete(
      'medical_histories',
    );

    await db.delete(
      'reports',
    );
  }

// =========================================================
// CLOSE
// =========================================================

  Future<void> close() async {
    final db = await database;

    await db.close();

    _database = null;
  }
}
