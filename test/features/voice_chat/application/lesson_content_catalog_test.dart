import 'package:english_voice_ai_clean/features/voice_chat/application/lesson_content_catalog.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/exercise_type.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/reading_listening_exercise.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads ten units with expected progression structure', () {
    final catalog = LessonContentCatalog();
    final units = catalog.loadDefaultUnits();

    expect(units, hasLength(10));
    expect(units[0].id, 'unit_greetings');
    expect(units[1].id, 'unit_cafe');
    expect(units[2].id, 'unit_getting_around');
    expect(units[9].id, 'unit_telling_stories');

    final beginnerUnits = units
        .where((unit) => unit.difficulty == ReadingListeningDifficulty.beginner)
        .toList(growable: false);
    final intermediateUnits = units
        .where((unit) =>
            unit.difficulty == ReadingListeningDifficulty.intermediate)
        .toList(growable: false);

    expect(beginnerUnits, hasLength(5));
    expect(intermediateUnits, hasLength(5));

    for (final unit in units) {
      expect(unit.lessons, hasLength(4));
      for (final lesson in unit.lessons) {
        expect(lesson.exercises, hasLength(6));
      }
    }
  });

  test('starter units keep exact 24-exercise volume each', () {
    final catalog = LessonContentCatalog();
    final units = catalog.loadDefaultUnits();

    expect(units[0].lessons, hasLength(4));
    expect(units[1].lessons, hasLength(4));

    final unit1Count = units[0].lessons.fold<int>(
          0,
          (sum, lesson) => sum + lesson.exercises.length,
        );
    final unit2Count = units[1].lessons.fold<int>(
          0,
          (sum, lesson) => sum + lesson.exercises.length,
        );

    expect(unit1Count, 24);
    expect(unit2Count, 24);
  });

  test('covers all exercise types and validates bilingual exercise content',
      () {
    final catalog = LessonContentCatalog();
    final units = catalog.loadDefaultUnits();
    final coveredTypes = <ExerciseType>{};

    for (final unit in units) {
      for (final lesson in unit.lessons) {
        for (final exercise in lesson.exercises) {
          coveredTypes.add(exercise.type);
          expect(exercise.id.trim().isNotEmpty, isTrue);
          expect(exercise.content.isNotEmpty, isTrue);

          final promptEn = (exercise.content['promptEn'] ?? '').toString();
          final promptPt = (exercise.content['promptPt'] ?? '').toString();
          expect(promptEn.trim().isNotEmpty, isTrue);
          expect(promptPt.trim().isNotEmpty, isTrue);

          switch (exercise.type) {
            case ExerciseType.multipleChoice:
            case ExerciseType.listenAndSelect:
            case ExerciseType.fillInTheBlank:
              final optionsEn = exercise.content['optionsEn'];
              final optionsPt = exercise.content['optionsPt'];
              expect(optionsEn is List && optionsEn.length >= 3, isTrue);
              expect(optionsPt is List && optionsPt.length >= 3, isTrue);
              expect(exercise.content['correctOptionIndex'] is int, isTrue);
              break;
            case ExerciseType.listenAndType:
              expect((exercise.content['audioTextEn'] ?? '').toString().trim(),
                  isNotEmpty);
              expect((exercise.content['audioTextPt'] ?? '').toString().trim(),
                  isNotEmpty);
              final audioEn = exercise.content['audioTextEn'].toString();
              final audioPt = exercise.content['audioTextPt'].toString();
              expect(audioEn.contains(':'), isFalse);
              expect(audioPt.contains(':'), isFalse);
              final acceptedAnswers = exercise.content['acceptedAnswers'];
              expect(acceptedAnswers is List && acceptedAnswers.isNotEmpty,
                  isTrue);
              break;
            case ExerciseType.translate:
              final acceptedAnswers = exercise.content['acceptedAnswers'];
              expect(acceptedAnswers is List && acceptedAnswers.isNotEmpty,
                  isTrue);
              break;
            case ExerciseType.wordOrder:
              final tokens = exercise.content['correctTokens'];
              expect(tokens is List && tokens.length >= 3, isTrue);
              break;
            case ExerciseType.matchPairs:
              final pairs = exercise.content['correctPairs'];
              expect(pairs is Map && pairs.length >= 3, isTrue);
              if (pairs is Map) {
                final values = pairs.values.map((e) => e.toString()).toList();
                expect(values.toSet().length, values.length);
              }
              break;
            case ExerciseType.speakTheSentence:
              final ref = (exercise.content['referenceText'] ?? '').toString();
              expect(ref.trim().isNotEmpty, isTrue);
              expect(exercise.content['minAccuracy'] is int, isTrue);
              break;
            case ExerciseType.trueOrFalse:
              expect(exercise.content['correctAnswer'] is bool, isTrue);
              break;
          }
        }
      }
    }

    expect(coveredTypes, containsAll(ExerciseType.values));
  });
}
