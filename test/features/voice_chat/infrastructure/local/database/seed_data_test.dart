import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:english_voice_ai_clean/features/voice_chat/application/lesson_content_catalog.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/local/database/seed_data.dart';

import 'test_db_helper.dart';

void main() {
  test('seed inserts integrity baseline for units, lessons and exercises',
      () async {
    final db = await openInMemoryTestDatabase();
    final catalog = LessonContentCatalog().loadDefaultUnits();
    final expectedUnits = catalog.length;
    final expectedLessons =
        catalog.fold<int>(0, (sum, unit) => sum + unit.lessons.length);
    final expectedExercises = catalog.fold<int>(
      0,
      (sum, unit) =>
          sum +
          unit.lessons.fold<int>(
            0,
            (lessonSum, lesson) => lessonSum + lesson.exercises.length,
          ),
    );

    Future<int> count(String table) async {
      return Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM $table')) ??
          0;
    }

    expect(await count('learning_units'), expectedUnits);
    expect(await count('lessons'), expectedLessons);
    expect(await count('exercises'), expectedExercises);
    expect(await count('unit_progress'), expectedUnits);
    expect(await count('lesson_progress'), expectedLessons);

    await db.close();
  });

  test('backfill restores lessons and exercises on partial legacy content',
      () async {
    final db = await openInMemoryTestDatabase();
    final catalog = LessonContentCatalog().loadDefaultUnits();
    final expectedUnits = catalog.length;
    final expectedLessons =
        catalog.fold<int>(0, (sum, unit) => sum + unit.lessons.length);
    final expectedExercises = catalog.fold<int>(
      0,
      (sum, unit) =>
          sum +
          unit.lessons.fold<int>(
            0,
            (lessonSum, lesson) => lessonSum + lesson.exercises.length,
          ),
    );

    Future<int> count(String table) async {
      return Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM $table')) ??
          0;
    }

    await db.delete('exercises');
    await db.delete('lesson_progress');
    await db.delete('lessons');

    expect(await count('learning_units'), expectedUnits);
    expect(await count('lessons'), 0);
    expect(await count('exercises'), 0);

    await ensureLearningContentBackfill(db);

    expect(await count('learning_units'), expectedUnits);
    expect(await count('lessons'), expectedLessons);
    expect(await count('exercises'), expectedExercises);
    expect(await count('lesson_progress'), expectedLessons);

    await db.close();
  });
}
