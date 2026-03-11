import '../../application/learning_api_service.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_progress.dart';
import '../../domain/entities/lesson_exercise.dart';
import '../../domain/entities/learning_unit.dart';
import '../../domain/entities/review_queue_item.dart';
import '../../domain/entities/unit_progress.dart';
import '../../domain/entities/user_progress.dart';
import 'database/app_database.dart';
import 'database/daos/exercises_dao.dart';
import 'database/daos/learning_units_dao.dart';
import 'database/daos/spaced_repetition_dao.dart';
import 'database/daos/user_progress_dao.dart';
import 'package:sqflite/sqflite.dart';

class LocalLearningApiService implements LearningApiService {
  final AppDatabase appDatabase;
  final Future<Database> Function()? databaseOpener;

  LocalLearningApiService({
    AppDatabase? appDatabase,
    this.databaseOpener,
  }) : appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> _openDb() {
    final opener = databaseOpener;
    if (opener != null) {
      return opener();
    }
    return appDatabase.open();
  }

  @override
  Future<List<LearningUnit>> getUnits() async {
    final db = await _openDb();
    return LearningUnitsDao(db).listUnitsOrdered();
  }

  @override
  Future<List<Lesson>> getLessonsForUnit(String unitId) async {
    final db = await _openDb();
    final units = await LearningUnitsDao(db).listUnitsWithLessons();
    final unit = units.where((item) => item.id == unitId).firstOrNull;
    return unit?.lessons ?? const <Lesson>[];
  }

  @override
  Future<List<LessonExercise>> getExercisesForLesson(String lessonId) async {
    final db = await _openDb();
    return ExercisesDao(db).listByLessonId(lessonId);
  }

  @override
  Future<void> saveLessonProgress({
    required String unitId,
    required LessonProgress progress,
    required int earnedXpDelta,
  }) async {
    final db = await _openDb();
    await UserProgressDao(db).saveLessonProgress(
      unitId: unitId,
      progress: progress,
      earnedXpDelta: earnedXpDelta,
    );
  }

  @override
  Future<UnitProgress> getUnitProgress(String unitId) async {
    final db = await _openDb();
    return UserProgressDao(db).getUnitProgress(unitId);
  }

  @override
  Future<UserProgress> getUserStats() async {
    final db = await _openDb();
    return UserProgressDao(db).getUserProgress();
  }

  @override
  Future<List<ReviewQueueItem>> getReviewQueue({DateTime? until}) async {
    final db = await _openDb();
    return SpacedRepetitionDao(db).listPending(until: until);
  }

  @override
  Future<void> upsertReviewItem(ReviewQueueItem item) async {
    final db = await _openDb();
    await SpacedRepetitionDao(db).enqueue(item);
  }

  @override
  Future<void> updateReviewItem(ReviewQueueItem item) async {
    final db = await _openDb();
    await SpacedRepetitionDao(db).updateAfterReview(item);
  }

  @override
  Future<void> removeReviewItem(String exerciseId) async {
    final db = await _openDb();
    await SpacedRepetitionDao(db).deleteByExerciseId(exerciseId);
  }
}

extension _FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
}
