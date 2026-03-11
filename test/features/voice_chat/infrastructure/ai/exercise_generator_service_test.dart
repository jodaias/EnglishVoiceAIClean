import 'dart:convert';

import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/exercise_type.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/reading_listening_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/ai/exercise_generation_cache.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/ai/exercise_generator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns cached exercise before calling prompt executor', () async {
    final cache = _InMemoryExerciseCache();
    final cached = LessonExercise(
      id: 'cached_1',
      type: ExerciseType.multipleChoice,
      difficulty: ReadingListeningDifficulty.beginner,
      content: <String, dynamic>{
        'promptEn': 'Cached prompt',
        'promptPt': 'Prompt em cache',
        'optionsEn': <String>['A', 'B', 'C'],
        'optionsPt': <String>['A', 'B', 'C'],
        'correctOptionIndex': 0,
      },
    );
    await cache.put(
      'type=multipleChoice|difficulty=beginner|topic=test_topic',
      cached,
    );

    var called = false;
    final service = ExerciseGeneratorService(
      cache: cache,
      executePrompt: (_) async {
        called = true;
        return '{}';
      },
    );

    final result = await service.generateExercise(
      type: ExerciseType.multipleChoice,
      difficulty: ReadingListeningDifficulty.beginner,
      topic: 'test topic',
    );

    expect(called, isFalse);
    expect(result.id, 'cached_1');
  });

  test('parses generated json and validates by type', () async {
    final service = ExerciseGeneratorService(
      cache: _InMemoryExerciseCache(),
      executePrompt: (_) async {
        final map = <String, dynamic>{
          'id': 'gen_1',
          'promptEn': 'Choose one',
          'promptPt': 'Escolha uma',
          'optionsEn': <String>['A', 'B', 'C'],
          'optionsPt': <String>['A', 'B', 'C'],
          'correctOptionIndex': 1,
        };
        return jsonEncode(map);
      },
    );

    final result = await service.generateExercise(
      type: ExerciseType.multipleChoice,
      difficulty: ReadingListeningDifficulty.beginner,
      topic: 'airport',
      useCache: false,
    );

    expect(result.id, 'gen_1');
    expect(result.type, ExerciseType.multipleChoice);
    expect(result.content['correctOptionIndex'], 1);
  });

  test('throws when generator returns invalid structure', () async {
    final service = ExerciseGeneratorService(
      cache: _InMemoryExerciseCache(),
      executePrompt: (_) async {
        final map = <String, dynamic>{
          'id': 'bad_1',
          'promptEn': 'Question',
          'promptPt': 'Pergunta',
          'optionsEn': <String>['Only one'],
          'optionsPt': <String>['Apenas uma'],
          'correctOptionIndex': 0,
        };
        return jsonEncode(map);
      },
    );

    expect(
      () => service.generateExercise(
        type: ExerciseType.multipleChoice,
        difficulty: ReadingListeningDifficulty.beginner,
        topic: 'shopping',
        useCache: false,
      ),
      throwsFormatException,
    );
  });

  test('generates surprise lesson with requested exercise count', () async {
    final service = ExerciseGeneratorService(
      cache: _InMemoryExerciseCache(),
      executePrompt: (prompt) async {
        if (prompt.contains('"correctOptionIndex"')) {
          return jsonEncode(<String, dynamic>{
            'id': 'gen_option',
            'promptEn': 'Pick one',
            'promptPt': 'Escolha uma',
            'optionsEn': <String>['A', 'B', 'C'],
            'optionsPt': <String>['A', 'B', 'C'],
            'correctOptionIndex': 0,
          });
        }
        if (prompt.contains('"correctTokens"')) {
          return jsonEncode(<String, dynamic>{
            'id': 'gen_order',
            'promptEn': 'Order words',
            'promptPt': 'Ordene palavras',
            'correctTokens': <String>['we', 'are', 'ready'],
          });
        }
        return jsonEncode(<String, dynamic>{
          'id': 'gen_text',
          'promptEn': 'Type this',
          'promptPt': 'Digite isso',
          'acceptedAnswers': <String>['answer'],
        });
      },
    );

    final list = await service.generateSurpriseLesson(
      topic: 'travel',
      difficulty: ReadingListeningDifficulty.intermediate,
      exerciseCount: 3,
    );

    expect(list, hasLength(3));
    expect(list.first.difficulty, ReadingListeningDifficulty.intermediate);
  });
}

class _InMemoryExerciseCache implements ExerciseGenerationCache {
  final Map<String, LessonExercise> _store = <String, LessonExercise>{};

  @override
  Future<LessonExercise?> get(String key) async => _store[key];

  @override
  Future<void> put(String key, LessonExercise exercise) async {
    _store[key] = exercise;
  }
}
