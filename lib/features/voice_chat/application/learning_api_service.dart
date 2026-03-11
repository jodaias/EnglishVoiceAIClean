import '../domain/entities/lesson.dart';
import '../domain/entities/lesson_progress.dart';
import '../domain/entities/lesson_exercise.dart';
import '../domain/entities/learning_unit.dart';
import '../domain/entities/review_queue_item.dart';
import '../domain/entities/unit_progress.dart';
import '../domain/entities/user_progress.dart';

abstract class LearningApiService {
  Future<List<LearningUnit>> getUnits();
  Future<List<Lesson>> getLessonsForUnit(String unitId);
  Future<List<LessonExercise>> getExercisesForLesson(String lessonId);

  Future<void> saveLessonProgress({
    required String unitId,
    required LessonProgress progress,
    required int earnedXpDelta,
  });

  Future<UnitProgress> getUnitProgress(String unitId);
  Future<UserProgress> getUserStats();

  Future<List<ReviewQueueItem>> getReviewQueue({DateTime? until});
  Future<void> updateReviewItem(ReviewQueueItem item);
}
