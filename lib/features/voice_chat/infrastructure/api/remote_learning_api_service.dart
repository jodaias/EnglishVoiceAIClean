import '../../application/learning_api_service.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_progress.dart';
import '../../domain/entities/lesson_exercise.dart';
import '../../domain/entities/learning_unit.dart';
import '../../domain/entities/review_queue_item.dart';
import '../../domain/entities/unit_progress.dart';
import '../../domain/entities/user_progress.dart';

class RemoteLearningApiService implements LearningApiService {
  const RemoteLearningApiService();

  @override
  Future<List<LearningUnit>> getUnits() async {
    throw UnimplementedError('Remote API service is not implemented yet.');
  }

  @override
  Future<List<Lesson>> getLessonsForUnit(String unitId) async {
    throw UnimplementedError('Remote API service is not implemented yet.');
  }

  @override
  Future<List<LessonExercise>> getExercisesForLesson(String lessonId) async {
    throw UnimplementedError('Remote API service is not implemented yet.');
  }

  @override
  Future<void> saveLessonProgress({
    required String unitId,
    required LessonProgress progress,
    required int earnedXpDelta,
  }) async {
    throw UnimplementedError('Remote API service is not implemented yet.');
  }

  @override
  Future<UnitProgress> getUnitProgress(String unitId) async {
    throw UnimplementedError('Remote API service is not implemented yet.');
  }

  @override
  Future<UserProgress> getUserStats() async {
    throw UnimplementedError('Remote API service is not implemented yet.');
  }

  @override
  Future<List<ReviewQueueItem>> getReviewQueue({DateTime? until}) async {
    throw UnimplementedError('Remote API service is not implemented yet.');
  }

  @override
  Future<void> updateReviewItem(ReviewQueueItem item) async {
    throw UnimplementedError('Remote API service is not implemented yet.');
  }
}
