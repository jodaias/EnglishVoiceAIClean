import 'unit_progress.dart';

class UserProgress {
  final Map<String, UnitProgress> units;
  final int totalXp;
  final int availableHearts;
  final DateTime? heartsRefillAt;
  final int streakDays;
  final String? lastCompletedDateKey;

  const UserProgress({
    required this.units,
    required this.totalXp,
    required this.availableHearts,
    required this.heartsRefillAt,
    required this.streakDays,
    required this.lastCompletedDateKey,
  });

  const UserProgress.initial()
      : units = const <String, UnitProgress>{},
        totalXp = 0,
        availableHearts = 5,
        heartsRefillAt = null,
        streakDays = 0,
        lastCompletedDateKey = null;

  UserProgress copyWith({
    Map<String, UnitProgress>? units,
    int? totalXp,
    int? availableHearts,
    DateTime? heartsRefillAt,
    bool clearHeartsRefillAt = false,
    int? streakDays,
    String? lastCompletedDateKey,
    bool clearLastCompletedDateKey = false,
  }) {
    return UserProgress(
      units: units ?? this.units,
      totalXp: totalXp ?? this.totalXp,
      availableHearts: availableHearts ?? this.availableHearts,
      heartsRefillAt:
          clearHeartsRefillAt ? null : (heartsRefillAt ?? this.heartsRefillAt),
      streakDays: streakDays ?? this.streakDays,
      lastCompletedDateKey: clearLastCompletedDateKey
          ? null
          : (lastCompletedDateKey ?? this.lastCompletedDateKey),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'units': units.map((key, value) => MapEntry(key, value.toJson())),
      'totalXp': totalXp,
      'availableHearts': availableHearts,
      'heartsRefillAt': heartsRefillAt?.toIso8601String(),
      'streakDays': streakDays,
      'lastCompletedDateKey': lastCompletedDateKey,
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final rawUnits = json['units'];
    final units = <String, UnitProgress>{};

    if (rawUnits is Map) {
      for (final entry in rawUnits.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is Map) {
          units[key] = UnitProgress.fromJson(
            value.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      }
    }

    return UserProgress(
      units: units,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      availableHearts: (json['availableHearts'] as num?)?.toInt() ?? 5,
      heartsRefillAt:
          DateTime.tryParse((json['heartsRefillAt'] ?? '').toString()),
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      lastCompletedDateKey: json['lastCompletedDateKey']?.toString(),
    );
  }
}
