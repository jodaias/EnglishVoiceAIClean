import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'seed_data.dart';

class AppDatabase {
  static const int version = 1;
  static const String dbName = 'learning_path_v1.db';

  static final AppDatabase instance = AppDatabase._();

  AppDatabase._();

  Database? _database;

  Future<Database> open() async {
    if (_database != null) {
      return _database!;
    }

    final fullPath = kIsWeb ? dbName : p.join(await getDatabasesPath(), dbName);

    _database = await openDatabase(
      fullPath,
      version: version,
      onCreate: (db, _) async {
        await _createSchema(db);
        await seedInitialLearningContent(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _runMigrations(db,
            oldVersion: oldVersion, newVersion: newVersion);
      },
    );

    return _database!;
  }

  Future<void> close() async {
    final db = _database;
    if (db == null) {
      return;
    }
    await db.close();
    _database = null;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE learning_units (
        id TEXT PRIMARY KEY,
        title_en TEXT NOT NULL,
        title_pt TEXT NOT NULL,
        icon_asset TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        difficulty TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE lessons (
        id TEXT PRIMARY KEY,
        unit_id TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        FOREIGN KEY(unit_id) REFERENCES learning_units(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        lesson_id TEXT NOT NULL,
        type TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        content_json TEXT NOT NULL,
        FOREIGN KEY(lesson_id) REFERENCES lessons(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE unit_progress (
        unit_id TEXT PRIMARY KEY,
        is_unlocked INTEGER NOT NULL,
        crowns INTEGER NOT NULL,
        FOREIGN KEY(unit_id) REFERENCES learning_units(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE lesson_progress (
        lesson_id TEXT PRIMARY KEY,
        unit_id TEXT NOT NULL,
        is_completed INTEGER NOT NULL,
        best_score INTEGER NOT NULL,
        xp_earned INTEGER NOT NULL,
        completed_at TEXT,
        attempts INTEGER NOT NULL,
        FOREIGN KEY(lesson_id) REFERENCES lessons(id) ON DELETE CASCADE,
        FOREIGN KEY(unit_id) REFERENCES learning_units(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE user_stats (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        total_xp INTEGER NOT NULL,
        available_hearts INTEGER NOT NULL,
        hearts_refill_at TEXT,
        streak_days INTEGER NOT NULL,
        last_completed_date_key TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE review_queue (
        exercise_id TEXT PRIMARY KEY,
        due_at TEXT NOT NULL,
        interval_days INTEGER NOT NULL,
        last_reviewed_at TEXT,
        fail_count INTEGER NOT NULL,
        FOREIGN KEY(exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_learning_units_order ON learning_units(order_index)',
    );
    await db.execute(
      'CREATE INDEX idx_lessons_unit_order ON lessons(unit_id, order_index)',
    );
    await db.execute(
      'CREATE INDEX idx_exercises_lesson ON exercises(lesson_id)',
    );
    await db.execute(
      'CREATE INDEX idx_lesson_progress_unit ON lesson_progress(unit_id)',
    );
    await db.execute(
      'CREATE INDEX idx_review_queue_due_at ON review_queue(due_at)',
    );
  }

  Future<void> _runMigrations(
    Database db, {
    required int oldVersion,
    required int newVersion,
  }) async {
    if (oldVersion < 1 && newVersion >= 1) {
      await _createSchema(db);
      await seedInitialLearningContent(db);
    }
  }
}
