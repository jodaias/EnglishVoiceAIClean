import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../domain/entities/exercise_type.dart';
import '../../../../domain/entities/lesson_exercise.dart';
import '../../../../domain/entities/reading_listening_exercise.dart';

class ExercisesDao {
  final Database db;

  const ExercisesDao(this.db);

  Future<List<LessonExercise>> listByLessonId(String lessonId) async {
    final rows = await db.query(
      'exercises',
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
      orderBy: 'id ASC',
    );
    return rows.map(_exerciseFromRow).toList(growable: false);
  }

  Future<LessonExercise?> getById(String exerciseId) async {
    final rows = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [exerciseId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _exerciseFromRow(rows.first);
  }

  Future<void> insert({
    required String lessonId,
    required LessonExercise exercise,
  }) async {
    await db.insert('exercises', {
      'id': exercise.id,
      'lesson_id': lessonId,
      'type': exercise.type.name,
      'difficulty': exercise.difficulty.name,
      'content_json': jsonEncode(exercise.content),
    });
  }

  LessonExercise _exerciseFromRow(Map<String, Object?> row) {
    final type = ExerciseTypeX.fromStorage((row['type'] ?? '').toString());

    final difficultyRaw = (row['difficulty'] ?? '').toString();
    final difficulty = ReadingListeningDifficulty.values.firstWhere(
      (value) => value.name == difficultyRaw,
      orElse: () => ReadingListeningDifficulty.beginner,
    );

    final contentRaw = (row['content_json'] ?? '{}').toString();
    final decoded = jsonDecode(contentRaw);
    final content = decoded is Map
        ? decoded.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};

    return LessonExercise(
      id: (row['id'] ?? '').toString(),
      type: type,
      difficulty: difficulty,
      content: content,
    );
  }
}
