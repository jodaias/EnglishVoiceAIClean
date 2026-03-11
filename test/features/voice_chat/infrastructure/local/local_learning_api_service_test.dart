import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/review_queue_item.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/local/local_learning_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'database/test_db_helper.dart';

void main() {
  test('local learning api reads seeded units and writes progress/review',
      () async {
    final db = await openInMemoryTestDatabase();
    final api = LocalLearningApiService(databaseOpener: () async => db);

    final units = await api.getUnits();
    expect(units.length, greaterThanOrEqualTo(2));
    expect(units.any((unit) => unit.id == 'unit_greetings'), isTrue);

    final lessons = await api.getLessonsForUnit('unit_greetings');
    expect(lessons, hasLength(4));

    final exercises = await api.getExercisesForLesson('lesson_greetings_1');
    expect(exercises, hasLength(6));

    await api.saveLessonProgress(
      unitId: 'unit_greetings',
      progress: LessonProgress.empty('lesson_greetings_1').copyWith(
        isCompleted: true,
        bestScore: 90,
        xpEarned: 70,
        attempts: 2,
      ),
      earnedXpDelta: 70,
    );

    final unitProgress = await api.getUnitProgress('unit_greetings');
    expect(unitProgress.crowns, 1);

    final user = await api.getUserStats();
    expect(user.totalXp, 70);

    await api.updateReviewItem(
      ReviewQueueItem(
        exerciseId: 'g_1_1',
        dueAt: DateTime(2026, 3, 11, 10),
        intervalDays: 1,
        lastReviewedAt: null,
        failCount: 1,
      ),
    );
    final queue = await api.getReviewQueue(until: DateTime(2026, 3, 11, 11));
    expect(queue, hasLength(0));

    await db.close();
  });
}
