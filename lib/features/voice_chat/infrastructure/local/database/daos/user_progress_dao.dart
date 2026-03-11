import 'package:sqflite/sqflite.dart';

import '../../../../domain/entities/lesson_progress.dart';
import '../../../../domain/entities/unit_progress.dart';
import '../../../../domain/entities/user_progress.dart';

class UserProgressDao {
  final Database db;

  const UserProgressDao(this.db);

  Future<void> saveLessonProgress({
    required String unitId,
    required LessonProgress progress,
    required int earnedXpDelta,
  }) async {
    await db.transaction((txn) async {
      await txn.insert(
        'lesson_progress',
        {
          'lesson_id': progress.lessonId,
          'unit_id': unitId,
          'is_completed': progress.isCompleted ? 1 : 0,
          'best_score': progress.bestScore,
          'xp_earned': progress.xpEarned,
          'completed_at': progress.completedAt?.toIso8601String(),
          'attempts': progress.attempts,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.rawUpdate(
        'UPDATE user_stats SET total_xp = total_xp + ? WHERE id = 1',
        [earnedXpDelta],
      );

      if (progress.isCompleted) {
        await txn.rawUpdate(
          'UPDATE unit_progress SET crowns = MIN(crowns + 1, 5) WHERE unit_id = ?',
          [unitId],
        );
      }
    });
  }

  Future<UnitProgress> getUnitProgress(String unitId) async {
    final unitRows = await db.query(
      'unit_progress',
      where: 'unit_id = ?',
      whereArgs: [unitId],
      limit: 1,
    );

    final lessonRows = await db.query(
      'lesson_progress',
      where: 'unit_id = ?',
      whereArgs: [unitId],
    );

    final lessons = <String, LessonProgress>{};
    for (final row in lessonRows) {
      final lesson = LessonProgress(
        lessonId: (row['lesson_id'] ?? '').toString(),
        isCompleted: (row['is_completed'] as num?)?.toInt() == 1,
        bestScore: (row['best_score'] as num?)?.toInt() ?? 0,
        xpEarned: (row['xp_earned'] as num?)?.toInt() ?? 0,
        completedAt: DateTime.tryParse((row['completed_at'] ?? '').toString()),
        attempts: (row['attempts'] as num?)?.toInt() ?? 0,
      );
      lessons[lesson.lessonId] = lesson;
    }

    if (unitRows.isEmpty) {
      return UnitProgress.empty(unitId, isUnlocked: false).copyWith(
        lessons: lessons,
      );
    }

    final unit = unitRows.first;
    return UnitProgress(
      unitId: (unit['unit_id'] ?? unitId).toString(),
      lessons: lessons,
      isUnlocked: (unit['is_unlocked'] as num?)?.toInt() == 1,
      crowns: (unit['crowns'] as num?)?.toInt() ?? 0,
    );
  }

  Future<UserProgress> getUserProgress() async {
    final unitRows = await db.query('unit_progress');
    final lessonRows = await db.query('lesson_progress');
    final statsRows = await db.query('user_stats', where: 'id = 1', limit: 1);

    final lessonsByUnit = <String, Map<String, LessonProgress>>{};
    for (final row in lessonRows) {
      final unitId = (row['unit_id'] ?? '').toString();
      final lesson = LessonProgress(
        lessonId: (row['lesson_id'] ?? '').toString(),
        isCompleted: (row['is_completed'] as num?)?.toInt() == 1,
        bestScore: (row['best_score'] as num?)?.toInt() ?? 0,
        xpEarned: (row['xp_earned'] as num?)?.toInt() ?? 0,
        completedAt: DateTime.tryParse((row['completed_at'] ?? '').toString()),
        attempts: (row['attempts'] as num?)?.toInt() ?? 0,
      );
      final map =
          lessonsByUnit.putIfAbsent(unitId, () => <String, LessonProgress>{});
      map[lesson.lessonId] = lesson;
    }

    final units = <String, UnitProgress>{};
    for (final row in unitRows) {
      final unitId = (row['unit_id'] ?? '').toString();
      units[unitId] = UnitProgress(
        unitId: unitId,
        lessons: lessonsByUnit[unitId] ?? const <String, LessonProgress>{},
        isUnlocked: (row['is_unlocked'] as num?)?.toInt() == 1,
        crowns: (row['crowns'] as num?)?.toInt() ?? 0,
      );
    }

    final stats = statsRows.isEmpty ? null : statsRows.first;
    return UserProgress(
      units: units,
      totalXp: (stats?['total_xp'] as num?)?.toInt() ?? 0,
      availableHearts: (stats?['available_hearts'] as num?)?.toInt() ?? 5,
      heartsRefillAt:
          DateTime.tryParse((stats?['hearts_refill_at'] ?? '').toString()),
      streakDays: (stats?['streak_days'] as num?)?.toInt() ?? 0,
      lastCompletedDateKey: stats?['last_completed_date_key']?.toString(),
    );
  }

  Future<void> updateHearts({
    required int availableHearts,
    DateTime? refillAt,
  }) async {
    await db.update(
      'user_stats',
      {
        'available_hearts': availableHearts,
        'hearts_refill_at': refillAt?.toIso8601String(),
      },
      where: 'id = 1',
    );
  }

  Future<void> applyHeartsRefillIfDue(DateTime now) async {
    final rows = await db.query('user_stats', where: 'id = 1', limit: 1);
    if (rows.isEmpty) {
      return;
    }
    final refillAt =
        DateTime.tryParse((rows.first['hearts_refill_at'] ?? '').toString());
    if (refillAt == null || now.isBefore(refillAt)) {
      return;
    }

    await db.update(
      'user_stats',
      {'available_hearts': 5, 'hearts_refill_at': null},
      where: 'id = 1',
    );
  }

  Future<void> updateStreak({
    required int streakDays,
    required String? lastCompletedDateKey,
  }) async {
    await db.update(
      'user_stats',
      {
        'streak_days': streakDays,
        'last_completed_date_key': lastCompletedDateKey,
      },
      where: 'id = 1',
    );
  }
}
