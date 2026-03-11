import 'package:sqflite/sqflite.dart';

import '../../../../domain/entities/review_queue_item.dart';

class SpacedRepetitionDao {
  final Database db;

  const SpacedRepetitionDao(this.db);

  Future<void> enqueue(ReviewQueueItem item) async {
    await db.insert(
      'review_queue',
      {
        'exercise_id': item.exerciseId,
        'due_at': item.dueAt.toIso8601String(),
        'interval_days': item.intervalDays,
        'last_reviewed_at': item.lastReviewedAt?.toIso8601String(),
        'fail_count': item.failCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ReviewQueueItem>> listPending({DateTime? until}) async {
    final threshold = (until ?? DateTime.now()).toIso8601String();
    final rows = await db.query(
      'review_queue',
      where: 'due_at <= ?',
      whereArgs: [threshold],
      orderBy: 'due_at ASC',
    );
    return rows.map(_mapItem).toList(growable: false);
  }

  Future<void> updateAfterReview(ReviewQueueItem item) async {
    await db.update(
      'review_queue',
      {
        'due_at': item.dueAt.toIso8601String(),
        'interval_days': item.intervalDays,
        'last_reviewed_at': item.lastReviewedAt?.toIso8601String(),
        'fail_count': item.failCount,
      },
      where: 'exercise_id = ?',
      whereArgs: [item.exerciseId],
    );
  }

  ReviewQueueItem _mapItem(Map<String, Object?> row) {
    return ReviewQueueItem(
      exerciseId: (row['exercise_id'] ?? '').toString(),
      dueAt: DateTime.tryParse((row['due_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      intervalDays: (row['interval_days'] as num?)?.toInt() ?? 1,
      lastReviewedAt:
          DateTime.tryParse((row['last_reviewed_at'] ?? '').toString()),
      failCount: (row['fail_count'] as num?)?.toInt() ?? 0,
    );
  }
}
