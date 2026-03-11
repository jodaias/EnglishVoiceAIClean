import '../domain/entities/user_progress.dart';

abstract class LearningProgressRepository {
  Future<UserProgress> getUserProgress();
  Future<void> saveUserProgress(UserProgress progress);
}
