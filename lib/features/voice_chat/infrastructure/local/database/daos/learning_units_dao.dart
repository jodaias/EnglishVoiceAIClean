import 'package:sqflite/sqflite.dart';

import '../../../../domain/entities/learning_unit.dart';
import '../../../../domain/entities/lesson.dart';
import '../../../../domain/entities/reading_listening_exercise.dart';
import 'exercises_dao.dart';

class LearningUnitsDao {
  final Database db;

  const LearningUnitsDao(this.db);

  Future<List<LearningUnit>> listUnitsOrdered() async {
    final rows = await db.query('learning_units', orderBy: 'order_index ASC');
    return rows.map((row) => _unitFromRow(row, const <Lesson>[])).toList();
  }

  Future<LearningUnit?> getById(String unitId) async {
    final rows = await db.query(
      'learning_units',
      where: 'id = ?',
      whereArgs: [unitId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _unitFromRow(rows.first, const <Lesson>[]);
  }

  Future<List<LearningUnit>> listUnitsWithLessons() async {
    final units = await listUnitsOrdered();
    final result = <LearningUnit>[];
    for (final unit in units) {
      final lessons = await _lessonsForUnit(unit.id);
      result.add(
        LearningUnit(
          id: unit.id,
          titleEn: unit.titleEn,
          titlePt: unit.titlePt,
          iconAsset: unit.iconAsset,
          orderIndex: unit.orderIndex,
          difficulty: unit.difficulty,
          lessons: lessons,
        ),
      );
    }
    return result;
  }

  Future<List<Lesson>> _lessonsForUnit(String unitId) async {
    final rows = await db.query(
      'lessons',
      where: 'unit_id = ?',
      whereArgs: [unitId],
      orderBy: 'order_index ASC',
    );

    final exercisesDao = ExercisesDao(db);
    final lessons = <Lesson>[];
    for (final row in rows) {
      final lessonId = (row['id'] ?? '').toString();
      final exercises = await exercisesDao.listByLessonId(lessonId);
      lessons.add(
        Lesson(
          id: lessonId,
          unitId: (row['unit_id'] ?? '').toString(),
          orderIndex: (row['order_index'] as num?)?.toInt() ?? 0,
          exercises: exercises,
        ),
      );
    }
    return lessons;
  }

  LearningUnit _unitFromRow(Map<String, Object?> row, List<Lesson> lessons) {
    final difficultyRaw = (row['difficulty'] ?? '').toString();
    final difficulty = ReadingListeningDifficulty.values.firstWhere(
      (value) => value.name == difficultyRaw,
      orElse: () => ReadingListeningDifficulty.beginner,
    );

    return LearningUnit(
      id: (row['id'] ?? '').toString(),
      titleEn: (row['title_en'] ?? '').toString(),
      titlePt: (row['title_pt'] ?? '').toString(),
      iconAsset: (row['icon_asset'] ?? '').toString(),
      orderIndex: (row['order_index'] as num?)?.toInt() ?? 0,
      difficulty: difficulty,
      lessons: lessons,
    );
  }
}
