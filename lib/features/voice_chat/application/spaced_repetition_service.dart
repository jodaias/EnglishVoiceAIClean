import '../domain/entities/review_queue_item.dart';
import 'learning_api_service.dart';

class SpacedRepetitionService {
  final LearningApiService learningApiService;
  final Set<String>? trackableExerciseIds;

  const SpacedRepetitionService({
    required this.learningApiService,
    this.trackableExerciseIds,
  });

  Future<void> registerLessonResults({
    required Map<String, bool> exerciseResults,
    DateTime? now,
  }) async {
    for (final entry in exerciseResults.entries) {
      await registerExerciseResult(
        exerciseId: entry.key,
        isCorrect: entry.value,
        now: now,
      );
    }
  }

  Future<void> registerExerciseResult({
    required String exerciseId,
    required bool isCorrect,
    DateTime? now,
  }) async {
    if (exerciseId.trim().isEmpty) {
      return;
    }

    final allowed = trackableExerciseIds;
    if (allowed != null && !allowed.contains(exerciseId)) {
      return;
    }

    final reviewedAt = now ?? DateTime.now();
    final existing = await _getExistingItem(exerciseId: exerciseId);

    if (!isCorrect) {
      final failCount = (existing?.failCount ?? 0) + 1;
      final failedItem = ReviewQueueItem(
        exerciseId: exerciseId,
        dueAt: reviewedAt.add(const Duration(days: 1)),
        intervalDays: 1,
        lastReviewedAt: reviewedAt,
        failCount: failCount,
      );
      await learningApiService.upsertReviewItem(failedItem);
      return;
    }

    if (existing == null) {
      return;
    }

    if (existing.intervalDays <= 1) {
      await learningApiService.updateReviewItem(
        existing.copyWith(
          intervalDays: 3,
          dueAt: reviewedAt.add(const Duration(days: 3)),
          lastReviewedAt: reviewedAt,
          failCount: existing.failCount > 0 ? existing.failCount - 1 : 0,
        ),
      );
      return;
    }

    if (existing.intervalDays <= 3) {
      await learningApiService.updateReviewItem(
        existing.copyWith(
          intervalDays: 7,
          dueAt: reviewedAt.add(const Duration(days: 7)),
          lastReviewedAt: reviewedAt,
          failCount: existing.failCount > 0 ? existing.failCount - 1 : 0,
        ),
      );
      return;
    }

    await learningApiService.removeReviewItem(exerciseId);
  }

  Future<ReviewQueueItem?> _getExistingItem(
      {required String exerciseId}) async {
    final farFuture = DateTime.fromMillisecondsSinceEpoch(253402300799000);
    final queue = await learningApiService.getReviewQueue(until: farFuture);
    for (final item in queue) {
      if (item.exerciseId == exerciseId) {
        return item;
      }
    }
    return null;
  }
}
