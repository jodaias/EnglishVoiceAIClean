import 'lesson_exercise.dart';

class Lesson {
  final String id;
  final String unitId;
  final int orderIndex;
  final List<LessonExercise> exercises;

  const Lesson({
    required this.id,
    required this.unitId,
    required this.orderIndex,
    required this.exercises,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitId': unitId,
      'orderIndex': orderIndex,
      'exercises': exercises.map((item) => item.toJson()).toList(),
    };
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'];
    final exercises = rawExercises is List
        ? rawExercises
            .whereType<Map>()
            .map((item) => LessonExercise.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value))))
            .toList(growable: false)
        : const <LessonExercise>[];

    return Lesson(
      id: (json['id'] ?? '').toString(),
      unitId: (json['unitId'] ?? '').toString(),
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      exercises: exercises,
    );
  }
}
