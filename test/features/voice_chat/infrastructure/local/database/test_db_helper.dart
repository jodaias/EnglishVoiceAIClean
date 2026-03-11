import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/local/database/seed_data.dart';

Future<Database> openInMemoryTestDatabase({bool seed = true}) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onCreate: (database, _) async {
      await database.execute('''
        CREATE TABLE learning_units (
          id TEXT PRIMARY KEY,
          title_en TEXT NOT NULL,
          title_pt TEXT NOT NULL,
          icon_asset TEXT NOT NULL,
          order_index INTEGER NOT NULL,
          difficulty TEXT NOT NULL
        )
      ''');
      await database.execute('''
        CREATE TABLE lessons (
          id TEXT PRIMARY KEY,
          unit_id TEXT NOT NULL,
          order_index INTEGER NOT NULL
        )
      ''');
      await database.execute('''
        CREATE TABLE exercises (
          id TEXT PRIMARY KEY,
          lesson_id TEXT NOT NULL,
          type TEXT NOT NULL,
          difficulty TEXT NOT NULL,
          content_json TEXT NOT NULL
        )
      ''');
      await database.execute('''
        CREATE TABLE unit_progress (
          unit_id TEXT PRIMARY KEY,
          is_unlocked INTEGER NOT NULL,
          crowns INTEGER NOT NULL
        )
      ''');
      await database.execute('''
        CREATE TABLE lesson_progress (
          lesson_id TEXT PRIMARY KEY,
          unit_id TEXT NOT NULL,
          is_completed INTEGER NOT NULL,
          best_score INTEGER NOT NULL,
          xp_earned INTEGER NOT NULL,
          completed_at TEXT,
          attempts INTEGER NOT NULL
        )
      ''');
      await database.execute('''
        CREATE TABLE user_stats (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          total_xp INTEGER NOT NULL,
          available_hearts INTEGER NOT NULL,
          hearts_refill_at TEXT,
          streak_days INTEGER NOT NULL,
          last_completed_date_key TEXT
        )
      ''');
      await database.execute('''
        CREATE TABLE review_queue (
          exercise_id TEXT PRIMARY KEY,
          due_at TEXT NOT NULL,
          interval_days INTEGER NOT NULL,
          last_reviewed_at TEXT,
          fail_count INTEGER NOT NULL
        )
      ''');

      if (seed) {
        await seedInitialLearningContent(database);
      }
    },
  );

  return db;
}
