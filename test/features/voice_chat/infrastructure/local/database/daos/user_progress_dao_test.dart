import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/local/database/daos/user_progress_dao.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_db_helper.dart';

void main() {
  test('saves lesson progress and updates aggregate stats', () async {
    final db = await openInMemoryTestDatabase();
    final dao = UserProgressDao(db);

    await dao.saveLessonProgress(
      unitId: 'unit_greetings',
      progress: LessonProgress.empty('lesson_greetings_1').copyWith(
        isCompleted: true,
        bestScore: 95,
        xpEarned: 80,
        attempts: 1,
      ),
      earnedXpDelta: 80,
    );

    final unit = await dao.getUnitProgress('unit_greetings');
    expect(unit.lessons['lesson_greetings_1']?.bestScore, 95);
    expect(unit.crowns, 1);

    final user = await dao.getUserProgress();
    expect(user.totalXp, 80);

    await dao.updateHearts(availableHearts: 0, refillAt: DateTime.now());
    await dao.updateStreak(streakDays: 4, lastCompletedDateKey: '2026-03-11');

    final updated = await dao.getUserProgress();
    expect(updated.availableHearts, 0);
    expect(updated.streakDays, 4);

    await db.close();
  });
}
