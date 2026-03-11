import 'exercise_type.dart';
import 'reading_listening_exercise.dart';

class LessonExercise {
  final String id;
  final ExerciseType type;
  final ReadingListeningDifficulty difficulty;
  final Map<String, dynamic> content;

  const LessonExercise({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'difficulty': difficulty.name,
      'content': content,
    };
  }

  factory LessonExercise.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? '').toString();
    final rawDifficulty = (json['difficulty'] ?? '').toString();

    final type = ExerciseType.values.firstWhere(
      (value) => value.name == rawType,
      orElse: () => ExerciseType.multipleChoice,
    );

    final difficulty = ReadingListeningDifficulty.values.firstWhere(
      (value) => value.name == rawDifficulty,
      orElse: () => ReadingListeningDifficulty.beginner,
    );

    final rawContent = json['content'];
    final content =
        rawContent is Map<String, dynamic> ? rawContent : <String, dynamic>{};

    return LessonExercise(
      id: (json['id'] ?? '').toString(),
      type: type,
      difficulty: difficulty,
      content: content,
    );
  }
}
