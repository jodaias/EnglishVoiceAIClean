import 'lesson_progress.dart';

class UnitProgress {
  final String unitId;
  final Map<String, LessonProgress> lessons;
  final bool isUnlocked;
  final int crowns;

  const UnitProgress({
    required this.unitId,
    required this.lessons,
    required this.isUnlocked,
    required this.crowns,
  });

  factory UnitProgress.empty(String unitId, {required bool isUnlocked}) {
    return UnitProgress(
      unitId: unitId,
      lessons: const <String, LessonProgress>{},
      isUnlocked: isUnlocked,
      crowns: 0,
    );
  }

  UnitProgress copyWith({
    String? unitId,
    Map<String, LessonProgress>? lessons,
    bool? isUnlocked,
    int? crowns,
  }) {
    return UnitProgress(
      unitId: unitId ?? this.unitId,
      lessons: lessons ?? this.lessons,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      crowns: crowns ?? this.crowns,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unitId': unitId,
      'lessons': lessons.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'isUnlocked': isUnlocked,
      'crowns': crowns,
    };
  }

  factory UnitProgress.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'];
    final lessons = <String, LessonProgress>{};

    if (rawLessons is Map) {
      for (final entry in rawLessons.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is Map) {
          lessons[key] = LessonProgress.fromJson(
            value.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      }
    }

    return UnitProgress(
      unitId: (json['unitId'] ?? '').toString(),
      lessons: lessons,
      isUnlocked: json['isUnlocked'] == true,
      crowns: (json['crowns'] as num?)?.toInt() ?? 0,
    );
  }
}
