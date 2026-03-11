import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/review_queue_item.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/local/database/daos/spaced_repetition_dao.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_db_helper.dart';

void main() {
  test('enqueues pending items and updates review interval', () async {
    final db = await openInMemoryTestDatabase();
    final dao = SpacedRepetitionDao(db);

    final due = DateTime(2026, 3, 11, 10);
    await dao.enqueue(
      ReviewQueueItem(
        exerciseId: 'g_1_1',
        dueAt: due,
        intervalDays: 1,
        lastReviewedAt: null,
        failCount: 1,
      ),
    );

    final pending = await dao.listPending(until: DateTime(2026, 3, 11, 10, 1));
    expect(pending, hasLength(1));

    await dao.updateAfterReview(
      pending.first.copyWith(
        dueAt: DateTime(2026, 3, 14),
        intervalDays: 3,
        lastReviewedAt: DateTime(2026, 3, 11, 10, 2),
        failCount: 0,
      ),
    );

    final none = await dao.listPending(until: DateTime(2026, 3, 12));
    expect(none, isEmpty);

    await db.close();
  });
}
