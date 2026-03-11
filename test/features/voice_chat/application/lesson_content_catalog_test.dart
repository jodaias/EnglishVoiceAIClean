import 'package:english_voice_ai_clean/features/voice_chat/application/lesson_content_catalog.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/exercise_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads two starter units with expected lesson and exercise volume', () {
    final catalog = LessonContentCatalog();
    final units = catalog.loadDefaultUnits();

    expect(units, hasLength(2));
    expect(units[0].id, 'unit_greetings');
    expect(units[1].id, 'unit_cafe');

    expect(units[0].lessons, hasLength(3));
    expect(units[1].lessons, hasLength(3));

    final unit1Count = units[0].lessons.fold<int>(
          0,
          (sum, lesson) => sum + lesson.exercises.length,
        );
    final unit2Count = units[1].lessons.fold<int>(
          0,
          (sum, lesson) => sum + lesson.exercises.length,
        );

    expect(unit1Count, 18);
    expect(unit2Count, 18);
  });

  test('covers all exercise types in starter catalog', () {
    final catalog = LessonContentCatalog();
    final units = catalog.loadDefaultUnits();
    final coveredTypes = <ExerciseType>{};

    for (final unit in units) {
      for (final lesson in unit.lessons) {
        for (final exercise in lesson.exercises) {
          coveredTypes.add(exercise.type);
          expect(exercise.id.trim().isNotEmpty, isTrue);
          expect(exercise.content.isNotEmpty, isTrue);
        }
      }
    }

    expect(coveredTypes, containsAll(ExerciseType.values));
  });
}
