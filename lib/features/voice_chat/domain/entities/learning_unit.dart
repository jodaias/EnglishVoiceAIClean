import 'lesson.dart';
import 'reading_listening_exercise.dart';

class LearningUnit {
  final String id;
  final String titleEn;
  final String titlePt;
  final String iconAsset;
  final int orderIndex;
  final ReadingListeningDifficulty difficulty;
  final List<Lesson> lessons;

  const LearningUnit({
    required this.id,
    required this.titleEn,
    required this.titlePt,
    required this.iconAsset,
    required this.orderIndex,
    required this.difficulty,
    required this.lessons,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleEn': titleEn,
      'titlePt': titlePt,
      'iconAsset': iconAsset,
      'orderIndex': orderIndex,
      'difficulty': difficulty.name,
      'lessons': lessons.map((item) => item.toJson()).toList(),
    };
  }

  factory LearningUnit.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'];
    final lessons = rawLessons is List
        ? rawLessons
            .whereType<Map>()
            .map((item) => Lesson.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value))))
            .toList(growable: false)
        : const <Lesson>[];

    final rawDifficulty = (json['difficulty'] ?? '').toString();
    final difficulty = ReadingListeningDifficulty.values.firstWhere(
      (value) => value.name == rawDifficulty,
      orElse: () => ReadingListeningDifficulty.beginner,
    );

    return LearningUnit(
      id: (json['id'] ?? '').toString(),
      titleEn: (json['titleEn'] ?? '').toString(),
      titlePt: (json['titlePt'] ?? '').toString(),
      iconAsset: (json['iconAsset'] ?? '').toString(),
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      difficulty: difficulty,
      lessons: lessons,
    );
  }
}
