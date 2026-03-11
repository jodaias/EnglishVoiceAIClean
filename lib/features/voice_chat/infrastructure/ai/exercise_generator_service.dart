import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/exercise_type.dart';
import '../../domain/entities/lesson_exercise.dart';
import '../../domain/entities/reading_listening_exercise.dart';
import 'exercise_generation_cache.dart';

typedef ExercisePromptExecutor = Future<String> Function(String prompt);

class ExerciseGeneratorService {
  final ExerciseGenerationCache cache;
  final ExercisePromptExecutor _executePrompt;

  ExerciseGeneratorService({
    ExerciseGenerationCache? cache,
    ExercisePromptExecutor? executePrompt,
  })  : cache = cache ?? HiveExerciseGenerationCache(),
        _executePrompt = executePrompt ?? _defaultGeminiPromptExecutor;

  Future<LessonExercise> generateExercise({
    required ExerciseType type,
    required ReadingListeningDifficulty difficulty,
    required String topic,
    bool useCache = true,
  }) async {
    final key = _cacheKey(type, difficulty, topic);

    if (useCache) {
      final fromCache = await cache.get(key);
      if (fromCache != null) {
        return fromCache;
      }
    }

    final prompt = _buildPrompt(
      type: type,
      difficulty: difficulty,
      topic: topic,
    );

    final raw = await _executePrompt(prompt);
    final jsonMap = _extractJsonMap(raw);
    final exercise = _mapToLessonExercise(
      jsonMap: jsonMap,
      type: type,
      difficulty: difficulty,
      topic: topic,
    );

    _validateExercise(exercise);
    await cache.put(key, exercise);
    return exercise;
  }

  Future<List<LessonExercise>> generateSurpriseLesson({
    required String topic,
    required ReadingListeningDifficulty difficulty,
    int exerciseCount = 6,
  }) async {
    final orderedTypes = <ExerciseType>[
      ExerciseType.multipleChoice,
      ExerciseType.listenAndSelect,
      ExerciseType.listenAndType,
      ExerciseType.wordOrder,
      ExerciseType.translate,
      ExerciseType.trueOrFalse,
      ExerciseType.matchPairs,
      ExerciseType.speakTheSentence,
      ExerciseType.fillInTheBlank,
    ];

    final result = <LessonExercise>[];
    for (var i = 0; i < exerciseCount; i += 1) {
      final type = orderedTypes[i % orderedTypes.length];
      final exercise = await generateExercise(
        type: type,
        difficulty: difficulty,
        topic: '$topic #${i + 1}',
      );
      result.add(exercise);
    }
    return result;
  }

  String _cacheKey(
    ExerciseType type,
    ReadingListeningDifficulty difficulty,
    String topic,
  ) {
    final normalizedTopic = topic.trim().toLowerCase().replaceAll(' ', '_');
    return 'type=${type.name}|difficulty=${difficulty.name}|topic=$normalizedTopic';
  }

  String _buildPrompt({
    required ExerciseType type,
    required ReadingListeningDifficulty difficulty,
    required String topic,
  }) {
    final schema = _schemaFor(type);
    final rules = _typeRules(type);

    return '''
You are generating one bilingual lesson exercise for a language-learning app.
Return JSON only, without markdown.

Constraints:
- Exercise type: ${type.name}
- Difficulty: ${difficulty.name}
- Topic: $topic
- Include both English and Portuguese (Brazil) prompts.
- Keep the content practical for spoken-learning sessions.

Type rules:
$rules

Expected JSON schema:
$schema
''';
  }

  Map<String, dynamic> _extractJsonMap(String raw) {
    final trimmed = raw.trim();
    final first = trimmed.indexOf('{');
    final last = trimmed.lastIndexOf('}');
    if (first == -1 || last == -1 || last <= first) {
      throw const FormatException(
          'Generator did not return valid JSON object.');
    }

    final candidate = trimmed.substring(first, last + 1);
    final decoded = jsonDecode(candidate);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Generator JSON is not an object.');
    }
    return decoded;
  }

  LessonExercise _mapToLessonExercise({
    required Map<String, dynamic> jsonMap,
    required ExerciseType type,
    required ReadingListeningDifficulty difficulty,
    required String topic,
  }) {
    final content = <String, dynamic>{
      'promptEn': (jsonMap['promptEn'] ?? '').toString(),
      'promptPt': (jsonMap['promptPt'] ?? '').toString(),
    };

    switch (type) {
      case ExerciseType.multipleChoice:
      case ExerciseType.listenAndSelect:
      case ExerciseType.fillInTheBlank:
        content['optionsEn'] = _asStringList(jsonMap['optionsEn']);
        content['optionsPt'] = _asStringList(jsonMap['optionsPt']);
        content['correctOptionIndex'] =
            _asInt(jsonMap['correctOptionIndex']) ?? 0;
        break;
      case ExerciseType.listenAndType:
      case ExerciseType.translate:
        content['acceptedAnswers'] = _asStringList(jsonMap['acceptedAnswers']);
        break;
      case ExerciseType.wordOrder:
        content['correctTokens'] = _asStringList(jsonMap['correctTokens']);
        break;
      case ExerciseType.matchPairs:
        content['correctPairs'] = _asStringMap(jsonMap['correctPairs']);
        break;
      case ExerciseType.speakTheSentence:
        content['referenceText'] = (jsonMap['referenceText'] ?? '').toString();
        content['minAccuracy'] = _asInt(jsonMap['minAccuracy']) ?? 85;
        break;
      case ExerciseType.trueOrFalse:
        content['correctAnswer'] = _asBool(jsonMap['correctAnswer']) ?? true;
        break;
    }

    final generatedId = (jsonMap['id'] ?? '').toString().trim();
    return LessonExercise(
      id: generatedId.isEmpty
          ? 'gen_${type.name}_${topic.toLowerCase().replaceAll(' ', '_')}'
          : generatedId,
      type: type,
      difficulty: difficulty,
      content: content,
    );
  }

  void _validateExercise(LessonExercise exercise) {
    final promptEn = (exercise.content['promptEn'] ?? '').toString().trim();
    final promptPt = (exercise.content['promptPt'] ?? '').toString().trim();

    if (promptEn.isEmpty || promptPt.isEmpty) {
      throw const FormatException(
          'Generated exercise is missing bilingual prompts.');
    }

    switch (exercise.type) {
      case ExerciseType.multipleChoice:
      case ExerciseType.listenAndSelect:
      case ExerciseType.fillInTheBlank:
        final optionsEn = _asStringList(exercise.content['optionsEn']);
        final optionsPt = _asStringList(exercise.content['optionsPt']);
        final correct = _asInt(exercise.content['correctOptionIndex']) ?? -1;
        if (optionsEn.length < 3 || optionsPt.length < 3) {
          throw const FormatException('Option exercise requires 3+ options.');
        }
        if (correct < 0 ||
            correct >= optionsEn.length ||
            correct >= optionsPt.length) {
          throw const FormatException(
              'Option exercise has invalid correct option index.');
        }
        break;
      case ExerciseType.listenAndType:
      case ExerciseType.translate:
        if (_asStringList(exercise.content['acceptedAnswers']).isEmpty) {
          throw const FormatException(
              'Text exercise requires accepted answers.');
        }
        break;
      case ExerciseType.wordOrder:
        if (_asStringList(exercise.content['correctTokens']).length < 3) {
          throw const FormatException(
              'Word order exercise requires 3+ tokens.');
        }
        break;
      case ExerciseType.matchPairs:
        if (_asStringMap(exercise.content['correctPairs']).length < 3) {
          throw const FormatException(
              'Match pairs exercise requires 3+ pairs.');
        }
        break;
      case ExerciseType.speakTheSentence:
        final reference =
            (exercise.content['referenceText'] ?? '').toString().trim();
        if (reference.isEmpty) {
          throw const FormatException(
              'Speak exercise requires reference text.');
        }
        break;
      case ExerciseType.trueOrFalse:
        if (!_isBool(exercise.content['correctAnswer'])) {
          throw const FormatException(
              'True/False exercise requires boolean answer.');
        }
        break;
    }
  }

  static Future<String> _defaultGeminiPromptExecutor(String prompt) async {
    final apiKey = (dotenv.env['GEMINI_API_KEY'] ?? '').trim();
    final model = (dotenv.env['GEMINI_MODEL'] ?? '').trim().isEmpty
        ? 'gemini-2.5-flash'
        : (dotenv.env['GEMINI_MODEL'] ?? '').trim();

    if (apiKey.isEmpty) {
      throw const FormatException('GEMINI_API_KEY is missing.');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    });

    final response = await http.post(
      url,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw FormatException(
          'Gemini request failed: HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final text = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (text == null) {
      throw const FormatException('Gemini response has no text.');
    }

    return text.toString();
  }

  List<String> _asStringList(Object? raw) {
    if (raw is List) {
      return raw
          .map((item) => item.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  Map<String, String> _asStringMap(Object? raw) {
    if (raw is! Map) {
      return const <String, String>{};
    }

    final result = <String, String>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString().trim();
      final value = entry.value.toString().trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        result[key] = value;
      }
    }
    return result;
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse((value ?? '').toString());
  }

  bool? _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    final raw = (value ?? '').toString().trim().toLowerCase();
    if (raw == 'true') {
      return true;
    }
    if (raw == 'false') {
      return false;
    }
    return null;
  }

  bool _isBool(Object? value) => value is bool;

  String _schemaFor(ExerciseType type) {
    switch (type) {
      case ExerciseType.multipleChoice:
      case ExerciseType.listenAndSelect:
      case ExerciseType.fillInTheBlank:
        return '''
{
  "id": "string",
  "promptEn": "string",
  "promptPt": "string",
  "optionsEn": ["...", "...", "..."],
  "optionsPt": ["...", "...", "..."],
  "correctOptionIndex": 0
}
''';
      case ExerciseType.listenAndType:
      case ExerciseType.translate:
        return '''
{
  "id": "string",
  "promptEn": "string",
  "promptPt": "string",
  "acceptedAnswers": ["..."]
}
''';
      case ExerciseType.wordOrder:
        return '''
{
  "id": "string",
  "promptEn": "string",
  "promptPt": "string",
  "correctTokens": ["...", "...", "..."]
}
''';
      case ExerciseType.matchPairs:
        return '''
{
  "id": "string",
  "promptEn": "string",
  "promptPt": "string",
  "correctPairs": {"key": "value", "key2": "value2", "key3": "value3"}
}
''';
      case ExerciseType.speakTheSentence:
        return '''
{
  "id": "string",
  "promptEn": "string",
  "promptPt": "string",
  "referenceText": "string",
  "minAccuracy": 85
}
''';
      case ExerciseType.trueOrFalse:
        return '''
{
  "id": "string",
  "promptEn": "string",
  "promptPt": "string",
  "correctAnswer": true
}
''';
    }
  }

  String _typeRules(ExerciseType type) {
    switch (type) {
      case ExerciseType.multipleChoice:
        return '- 3 options, one correct answer, clear contextual question.';
      case ExerciseType.listenAndSelect:
        return '- Prompt should represent listenable sentence and 3 options.';
      case ExerciseType.listenAndType:
        return '- Include practical dictated sentence and accepted answers.';
      case ExerciseType.fillInTheBlank:
        return '- Include blank context represented naturally and options.';
      case ExerciseType.wordOrder:
        return '- Provide 3+ tokens in correct order array.';
      case ExerciseType.translate:
        return '- Include source sentence and accepted translations.';
      case ExerciseType.matchPairs:
        return '- Provide at least 3 bilingual pairs.';
      case ExerciseType.speakTheSentence:
        return '- Provide a sentence to speak and realistic minAccuracy.';
      case ExerciseType.trueOrFalse:
        return '- Provide factual short statement and boolean answer.';
    }
  }
}
