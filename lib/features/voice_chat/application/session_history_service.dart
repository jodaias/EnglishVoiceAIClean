import '../domain/entities/practice_session_record.dart';

class WeeklyProgressSnapshot {
  final int practicedMinutes;
  final int activeDays;
  final String mostUsedFocus;
  final int currentStreakDays;
  final int consistencyPercent;
  final String consistencyLabel;

  const WeeklyProgressSnapshot({
    required this.practicedMinutes,
    required this.activeDays,
    required this.mostUsedFocus,
    required this.currentStreakDays,
    required this.consistencyPercent,
    required this.consistencyLabel,
  });
}

class SessionHistoryService {
  WeeklyProgressSnapshot buildWeeklySnapshot({
    required List<PracticeSessionRecord> sessions,
    required DateTime now,
  }) {
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    final weekly = sessions
        .where((entry) => !entry.endedAt.isBefore(weekStart))
        .toList(growable: false);

    final practicedMinutes =
        weekly.fold<int>(0, (sum, item) => sum + (item.elapsedSeconds ~/ 60));

    final uniqueDays =
        weekly.map((entry) => _dateOnly(entry.endedAt)).toSet().length;
    final consistencyPercent = ((uniqueDays / 7) * 100).round();

    final focusUsage = <String, int>{};
    for (final session in weekly) {
      focusUsage.update(session.practiceFocus, (count) => count + 1,
          ifAbsent: () => 1);
    }

    String mostUsedFocus = 'No focus data yet';
    if (focusUsage.isNotEmpty) {
      final sorted = focusUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      mostUsedFocus = sorted.first.key;
    }

    return WeeklyProgressSnapshot(
      practicedMinutes: practicedMinutes,
      activeDays: uniqueDays,
      mostUsedFocus: mostUsedFocus,
      currentStreakDays: _currentStreakDays(sessions: sessions, now: now),
      consistencyPercent: consistencyPercent,
      consistencyLabel: _consistencyLabel(consistencyPercent),
    );
  }

  String _consistencyLabel(int percent) {
    if (percent >= 86) {
      return 'Excellent consistency';
    }
    if (percent >= 57) {
      return 'Good consistency';
    }
    if (percent >= 29) {
      return 'Building consistency';
    }
    return 'Start with short daily sessions';
  }

  int _currentStreakDays({
    required List<PracticeSessionRecord> sessions,
    required DateTime now,
  }) {
    final daySet = sessions.map((entry) => _dateOnly(entry.endedAt)).toSet();

    var streak = 0;
    var cursor = _dateOnly(now);
    while (daySet.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
