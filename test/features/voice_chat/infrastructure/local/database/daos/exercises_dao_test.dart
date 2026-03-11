import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/exercise_type.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/reading_listening_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/local/database/daos/exercises_dao.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_db_helper.dart';

void main() {
  test('lists and inserts exercises by lesson', () async {
    final db = await openInMemoryTestDatabase();
    final dao = ExercisesDao(db);

    final existing = await dao.listByLessonId('lesson_greetings_1');
    expect(existing, hasLength(6));

    await dao.insert(
      lessonId: 'lesson_greetings_1',
      exercise: const LessonExercise(
        id: 'custom_ex_1',
        type: ExerciseType.trueOrFalse,
        difficulty: ReadingListeningDifficulty.beginner,
        content: <String, dynamic>{'correctAnswer': true},
      ),
    );

    final inserted = await dao.getById('custom_ex_1');
    expect(inserted, isNotNull);
    expect(inserted?.type, ExerciseType.trueOrFalse);

    await db.close();
  });
}
