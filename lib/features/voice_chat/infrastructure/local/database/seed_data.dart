import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../application/lesson_content_catalog.dart';
import '../../../domain/entities/exercise_type.dart';

Future<void> seedInitialLearningContent(Database db) async {
  final existing = Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM learning_units'),
  );
  if ((existing ?? 0) > 0) {
    return;
  }

  final catalog = LessonContentCatalog().loadDefaultUnits();

  final batch = db.batch();
  for (final unit in catalog) {
    batch.insert('learning_units', {
      'id': unit.id,
      'title_en': unit.titleEn,
      'title_pt': unit.titlePt,
      'icon_asset': unit.iconAsset,
      'order_index': unit.orderIndex,
      'difficulty': unit.difficulty.name,
    });

    batch.insert('unit_progress', {
      'unit_id': unit.id,
      'is_unlocked': unit.orderIndex == 0 ? 1 : 0,
      'crowns': 0,
    });

    for (final lesson in unit.lessons) {
      batch.insert('lessons', {
        'id': lesson.id,
        'unit_id': lesson.unitId,
        'order_index': lesson.orderIndex,
      });

      batch.insert('lesson_progress', {
        'lesson_id': lesson.id,
        'unit_id': lesson.unitId,
        'is_completed': 0,
        'best_score': 0,
        'xp_earned': 0,
        'completed_at': null,
        'attempts': 0,
      });

      for (final exercise in lesson.exercises) {
        batch.insert('exercises', {
          'id': exercise.id,
          'lesson_id': lesson.id,
          'type': exercise.type.name,
          'difficulty': exercise.difficulty.name,
          'content_json': jsonEncode(exercise.content),
        });
      }
    }
  }

  batch.insert('user_stats', {
    'id': 1,
    'total_xp': 0,
    'available_hearts': 5,
    'hearts_refill_at': null,
    'streak_days': 0,
    'last_completed_date_key': null,
  });

  await batch.commit(noResult: true);
  await _backfillEnglishListeningTranscripts(db);
}

Future<void> ensureLearningContentBackfill(Database db) async {
  final catalog = LessonContentCatalog().loadDefaultUnits();

  final batch = db.batch();
  for (final unit in catalog) {
    batch.insert(
      'learning_units',
      {
        'id': unit.id,
        'title_en': unit.titleEn,
        'title_pt': unit.titlePt,
        'icon_asset': unit.iconAsset,
        'order_index': unit.orderIndex,
        'difficulty': unit.difficulty.name,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'unit_progress',
      {
        'unit_id': unit.id,
        'is_unlocked': unit.orderIndex == 0 ? 1 : 0,
        'crowns': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    for (final lesson in unit.lessons) {
      batch.insert(
        'lessons',
        {
          'id': lesson.id,
          'unit_id': lesson.unitId,
          'order_index': lesson.orderIndex,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      batch.insert(
        'lesson_progress',
        {
          'lesson_id': lesson.id,
          'unit_id': lesson.unitId,
          'is_completed': 0,
          'best_score': 0,
          'xp_earned': 0,
          'completed_at': null,
          'attempts': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      for (final exercise in lesson.exercises) {
        batch.insert(
          'exercises',
          {
            'id': exercise.id,
            'lesson_id': lesson.id,
            'type': exercise.type.name,
            'difficulty': exercise.difficulty.name,
            'content_json': jsonEncode(exercise.content),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  batch.insert(
    'user_stats',
    {
      'id': 1,
      'total_xp': 0,
      'available_hearts': 5,
      'hearts_refill_at': null,
      'streak_days': 0,
      'last_completed_date_key': null,
    },
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );

  await batch.commit(noResult: true);
  await _backfillEnglishListeningTranscripts(db);
}

Future<void> _backfillEnglishListeningTranscripts(Database db) async {
  final rows = await db.query(
    'exercises',
    columns: <String>['id', 'content_json'],
    where: 'type = ?',
    whereArgs: <Object>[ExerciseType.listenAndType.name],
  );

  for (final row in rows) {
    final id = row['id']?.toString() ?? '';
    final contentRaw = row['content_json']?.toString() ?? '{}';
    if (id.isEmpty || contentRaw.isEmpty) {
      continue;
    }

    final decoded = jsonDecode(contentRaw);
    if (decoded is! Map) {
      continue;
    }

    final content = Map<String, dynamic>.from(decoded as Map);
    final audioTextEn = (content['audioTextEn'] ?? '').toString().trim();
    if (audioTextEn.isNotEmpty) {
      continue;
    }

    final promptEn = (content['promptEn'] ?? '').toString().trim();
    final extractedEn = _extractTranscript(promptEn);
    if (extractedEn.isEmpty) {
      continue;
    }

    content['audioTextEn'] = extractedEn;

    await db.update(
      'exercises',
      <String, Object?>{'content_json': jsonEncode(content)},
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }
}

String _extractTranscript(String text) {
  if (text.isEmpty) {
    return '';
  }

  final colon = text.indexOf(':');
  if (colon >= 0 && colon + 1 < text.length) {
    final candidate = text.substring(colon + 1).trim();
    if (candidate.isNotEmpty) {
      return candidate;
    }
  }

  return text;
}
