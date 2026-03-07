class DailyChallengeHistory {
  final List<String> completedDateKeys;

  const DailyChallengeHistory({required this.completedDateKeys});

  int get totalCompletedDays => completedDateKeys.length;

  int completedInLastDays({required DateTime now, required int days}) {
    if (days <= 0) {
      return 0;
    }

    final dateSet = completedDateKeys.toSet();
    var count = 0;
    for (var offset = 0; offset < days; offset += 1) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: offset));
      if (dateSet.contains(_dateKey(day))) {
        count += 1;
      }
    }

    return count;
  }

  int currentStreakDays(DateTime now) {
    final dateSet = completedDateKeys.toSet();
    var streak = 0;
    var cursor = DateTime(now.year, now.month, now.day);

    while (dateSet.contains(_dateKey(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  DailyChallengeHistory addDateKey(String dateKey) {
    final updated = <String>{...completedDateKeys, dateKey}.toList()..sort();
    return DailyChallengeHistory(completedDateKeys: updated);
  }

  Map<String, dynamic> toJson() {
    return {
      'completedDateKeys': completedDateKeys,
    };
  }

  factory DailyChallengeHistory.fromJson(Map<String, dynamic> json) {
    final rawList = json['completedDateKeys'];
    if (rawList is List) {
      return DailyChallengeHistory(
        completedDateKeys: rawList.map((item) => item.toString()).toList(),
      );
    }

    return const DailyChallengeHistory(completedDateKeys: <String>[]);
  }

  static String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
