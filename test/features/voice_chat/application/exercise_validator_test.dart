import 'package:english_voice_ai_clean/features/voice_chat/application/exercise_validator.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/exercise_type.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/reading_listening_exercise.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = ExerciseValidator();

  LessonExercise buildExercise({
    required ExerciseType type,
    required Map<String, dynamic> content,
  }) {
    return LessonExercise(
      id: 'test',
      type: type,
      difficulty: ReadingListeningDifficulty.beginner,
      content: content,
    );
  }

  test('validates option based exercise', () {
    final exercise = buildExercise(
      type: ExerciseType.multipleChoice,
      content: <String, dynamic>{'correctOptionIndex': 1},
    );

    final result = validator.validate(exercise: exercise, userAnswer: 1);
    final wrong = validator.validate(exercise: exercise, userAnswer: 0);

    expect(result.isCorrect, isTrue);
    expect(wrong.isCorrect, isFalse);
  });

  test('validates listen and type with fuzzy tolerance', () {
    final exercise = buildExercise(
      type: ExerciseType.listenAndType,
      content: <String, dynamic>{
        'acceptedAnswers': <String>['How are you today'],
      },
    );

    final result = validator.validate(
      exercise: exercise,
      userAnswer: 'how are you tody',
    );

    expect(result.isCorrect, isTrue);
  });

  test('validates word order', () {
    final exercise = buildExercise(
      type: ExerciseType.wordOrder,
      content: <String, dynamic>{
        'correctTokens': <String>['i', 'am', 'ready'],
      },
    );

    final result = validator.validate(
      exercise: exercise,
      userAnswer: <String>['i', 'am', 'ready'],
    );
    final wrong = validator.validate(
      exercise: exercise,
      userAnswer: <String>['ready', 'i', 'am'],
    );

    expect(result.isCorrect, isTrue);
    expect(wrong.isCorrect, isFalse);
  });

  test('validates match pairs map', () {
    final exercise = buildExercise(
      type: ExerciseType.matchPairs,
      content: <String, dynamic>{
        'correctPairs': <String, String>{
          'bill': 'conta',
          'table': 'mesa',
        },
      },
    );

    final result = validator.validate(
      exercise: exercise,
      userAnswer: <String, String>{
        'bill': 'conta',
        'table': 'mesa',
      },
    );

    expect(result.isCorrect, isTrue);
  });

  test('validates speak sentence by pronunciation accuracy', () {
    final exercise = buildExercise(
      type: ExerciseType.speakTheSentence,
      content: <String, dynamic>{
        'referenceText': 'Nice to meet you',
        'minAccuracy': 85,
      },
    );

    final result = validator.validate(
      exercise: exercise,
      userAnswer: 'random input',
      pronunciationAccuracyPercent: 90,
    );

    expect(result.isCorrect, isTrue);
  });

  test('validates true or false with boolean answer', () {
    final exercise = buildExercise(
      type: ExerciseType.trueOrFalse,
      content: <String, dynamic>{'correctAnswer': true},
    );

    final result = validator.validate(exercise: exercise, userAnswer: true);
    final wrong = validator.validate(exercise: exercise, userAnswer: false);

    expect(result.isCorrect, isTrue);
    expect(wrong.isCorrect, isFalse);
  });
}
