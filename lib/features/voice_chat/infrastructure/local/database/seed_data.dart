import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../application/lesson_content_catalog.dart';

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
}
