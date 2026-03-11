import 'package:english_voice_ai_clean/features/voice_chat/application/learning_api_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/spaced_repetition_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/learning_unit.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/reading_listening_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/review_queue_item.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/unit_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/user_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('failed answer is queued with 1-day interval', () async {
    final api = _FakeLearningApiService();
    final service = SpacedRepetitionService(
      learningApiService: api,
      trackableExerciseIds: <String>{'e1'},
    );
    final now = DateTime(2026, 3, 11, 10);

    await service.registerExerciseResult(
      exerciseId: 'e1',
      isCorrect: false,
      now: now,
    );

    final item = api.itemsById['e1'];
    expect(item, isNotNull);
    expect(item!.intervalDays, 1);
    expect(item.failCount, 1);
    expect(item.dueAt, now.add(const Duration(days: 1)));
  });

  test('correct answers advance interval and then remove item', () async {
    final api = _FakeLearningApiService();
    api.itemsById['e1'] = ReviewQueueItem(
      exerciseId: 'e1',
      dueAt: DateTime(2026, 3, 11),
      intervalDays: 1,
      lastReviewedAt: null,
      failCount: 2,
    );

    final service = SpacedRepetitionService(
      learningApiService: api,
      trackableExerciseIds: <String>{'e1'},
    );

    await service.registerExerciseResult(
      exerciseId: 'e1',
      isCorrect: true,
      now: DateTime(2026, 3, 11),
    );
    expect(api.itemsById['e1']!.intervalDays, 3);

    await service.registerExerciseResult(
      exerciseId: 'e1',
      isCorrect: true,
      now: DateTime(2026, 3, 12),
    );
    expect(api.itemsById['e1']!.intervalDays, 7);

    await service.registerExerciseResult(
      exerciseId: 'e1',
      isCorrect: true,
      now: DateTime(2026, 3, 13),
    );
    expect(api.itemsById.containsKey('e1'), isFalse);
  });
}

class _FakeLearningApiService implements LearningApiService {
  final Map<String, ReviewQueueItem> itemsById = <String, ReviewQueueItem>{};

  @override
  Future<List<LearningUnit>> getUnits() async => const <LearningUnit>[];

  @override
  Future<List<Lesson>> getLessonsForUnit(String unitId) async =>
      const <Lesson>[];

  @override
  Future<List<LessonExercise>> getExercisesForLesson(String lessonId) async =>
      const <LessonExercise>[];

  @override
  Future<void> saveLessonProgress({
    required String unitId,
    required LessonProgress progress,
    required int earnedXpDelta,
  }) async {}

  @override
  Future<UnitProgress> getUnitProgress(String unitId) async =>
      UnitProgress.empty(unitId, isUnlocked: true);

  @override
  Future<UserProgress> getUserStats() async => const UserProgress.initial();

  @override
  Future<List<ReviewQueueItem>> getReviewQueue({DateTime? until}) async {
    final cutoff = until ?? DateTime.now();
    return itemsById.values
        .where((item) => !item.dueAt.isAfter(cutoff))
        .toList(growable: false);
  }

  @override
  Future<void> upsertReviewItem(ReviewQueueItem item) async {
    itemsById[item.exerciseId] = item;
  }

  @override
  Future<void> updateReviewItem(ReviewQueueItem item) async {
    itemsById[item.exerciseId] = item;
  }

  @override
  Future<void> removeReviewItem(String exerciseId) async {
    itemsById.remove(exerciseId);
  }
}
