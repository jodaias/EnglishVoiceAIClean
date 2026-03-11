import '../domain/entities/exercise_type.dart';
import '../domain/entities/lesson_exercise.dart';

class ExerciseValidationResult {
  final bool isCorrect;
  final String normalizedUserAnswer;

  const ExerciseValidationResult({
    required this.isCorrect,
    required this.normalizedUserAnswer,
  });
}

class ExerciseValidator {
  const ExerciseValidator();

  ExerciseValidationResult validate({
    required LessonExercise exercise,
    required Object? userAnswer,
    int pronunciationAccuracyPercent = 0,
  }) {
    switch (exercise.type) {
      case ExerciseType.multipleChoice:
      case ExerciseType.listenAndSelect:
      case ExerciseType.fillInTheBlank:
        return _validateOptionIndex(exercise, userAnswer);
      case ExerciseType.listenAndType:
      case ExerciseType.translate:
        return _validateFreeText(exercise, userAnswer);
      case ExerciseType.wordOrder:
        return _validateWordOrder(exercise, userAnswer);
      case ExerciseType.matchPairs:
        return _validateMatchPairs(exercise, userAnswer);
      case ExerciseType.speakTheSentence:
        return _validateSpeakSentence(
          exercise,
          userAnswer,
          pronunciationAccuracyPercent,
        );
      case ExerciseType.trueOrFalse:
        return _validateTrueFalse(exercise, userAnswer);
    }
  }

  ExerciseValidationResult _validateOptionIndex(
    LessonExercise exercise,
    Object? userAnswer,
  ) {
    final selectedIndex = _asInt(userAnswer);
    final correctIndex = _asInt(exercise.content['correctOptionIndex']);

    if (selectedIndex == null || correctIndex == null) {
      return const ExerciseValidationResult(
        isCorrect: false,
        normalizedUserAnswer: '',
      );
    }

    return ExerciseValidationResult(
      isCorrect: selectedIndex == correctIndex,
      normalizedUserAnswer: selectedIndex.toString(),
    );
  }

  ExerciseValidationResult _validateFreeText(
    LessonExercise exercise,
    Object? userAnswer,
  ) {
    final answer = (userAnswer ?? '').toString();
    final normalizedAnswer = _normalize(answer);
    if (normalizedAnswer.isEmpty) {
      return const ExerciseValidationResult(
        isCorrect: false,
        normalizedUserAnswer: '',
      );
    }

    final accepted = _asStringList(exercise.content['acceptedAnswers'])
        .map(_normalize)
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (accepted.isEmpty) {
      return ExerciseValidationResult(
        isCorrect: false,
        normalizedUserAnswer: normalizedAnswer,
      );
    }

    final minDistance = accepted
        .map((candidate) => _levenshtein(normalizedAnswer, candidate))
        .fold<int>(
            1 << 30, (current, value) => value < current ? value : current);

    final threshold = normalizedAnswer.length <= 5
        ? 1
        : normalizedAnswer.length <= 12
            ? 2
            : 3;

    return ExerciseValidationResult(
      isCorrect: minDistance <= threshold,
      normalizedUserAnswer: normalizedAnswer,
    );
  }

  ExerciseValidationResult _validateWordOrder(
    LessonExercise exercise,
    Object? userAnswer,
  ) {
    final expectedTokens = _asStringList(exercise.content['correctTokens'])
        .map(_normalize)
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    final givenTokens = _asStringList(userAnswer)
        .map(_normalize)
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    final isCorrect = expectedTokens.isNotEmpty &&
        expectedTokens.length == givenTokens.length &&
        _isSameOrder(expectedTokens, givenTokens);

    return ExerciseValidationResult(
      isCorrect: isCorrect,
      normalizedUserAnswer: givenTokens.join(' '),
    );
  }

  ExerciseValidationResult _validateMatchPairs(
    LessonExercise exercise,
    Object? userAnswer,
  ) {
    final expectedPairs = _normalizeMap(exercise.content['correctPairs']);
    final givenPairs = _normalizeMap(userAnswer);

    final isCorrect = expectedPairs.isNotEmpty &&
        expectedPairs.length == givenPairs.length &&
        expectedPairs.entries.every(
          (entry) => givenPairs[entry.key] == entry.value,
        );

    return ExerciseValidationResult(
      isCorrect: isCorrect,
      normalizedUserAnswer: givenPairs.entries
          .map((entry) => '${entry.key}:${entry.value}')
          .join('|'),
    );
  }

  ExerciseValidationResult _validateSpeakSentence(
    LessonExercise exercise,
    Object? userAnswer,
    int pronunciationAccuracyPercent,
  ) {
    final minAccuracy = _asInt(exercise.content['minAccuracy']) ?? 85;
    final reference =
        _normalize((exercise.content['referenceText'] ?? '').toString());
    final spoken = _normalize((userAnswer ?? '').toString());

    final accuracyMatch = pronunciationAccuracyPercent >= minAccuracy;
    final textMatch = spoken.isNotEmpty && reference.isNotEmpty
        ? _levenshtein(spoken, reference) <= 3
        : false;

    return ExerciseValidationResult(
      isCorrect: accuracyMatch || textMatch,
      normalizedUserAnswer: spoken,
    );
  }

  ExerciseValidationResult _validateTrueFalse(
    LessonExercise exercise,
    Object? userAnswer,
  ) {
    final expected = _asBool(exercise.content['correctAnswer']);
    final given = _asBool(userAnswer);

    if (expected == null || given == null) {
      return const ExerciseValidationResult(
        isCorrect: false,
        normalizedUserAnswer: '',
      );
    }

    return ExerciseValidationResult(
      isCorrect: expected == given,
      normalizedUserAnswer: given.toString(),
    );
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
    if (raw == 'true' || raw == 'verdadeiro') {
      return true;
    }
    if (raw == 'false' || raw == 'falso') {
      return false;
    }
    return null;
  }

  List<String> _asStringList(Object? value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  Map<String, String> _normalizeMap(Object? value) {
    if (value is! Map) {
      return const <String, String>{};
    }

    final normalized = <String, String>{};
    for (final entry in value.entries) {
      final key = _normalize(entry.key.toString());
      final mapped = _normalize(entry.value.toString());
      if (key.isNotEmpty && mapped.isNotEmpty) {
        normalized[key] = mapped;
      }
    }
    return normalized;
  }

  String _normalize(String input) {
    final lower = input.toLowerCase();
    final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return cleaned.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _isSameOrder(List<String> expected, List<String> given) {
    for (var i = 0; i < expected.length; i += 1) {
      if (expected[i] != given[i]) {
        return false;
      }
    }
    return true;
  }

  int _levenshtein(String a, String b) {
    if (a == b) {
      return 0;
    }
    if (a.isEmpty) {
      return b.length;
    }
    if (b.isEmpty) {
      return a.length;
    }

    final rows = a.length + 1;
    final cols = b.length + 1;
    final matrix = List<List<int>>.generate(
      rows,
      (row) => List<int>.generate(
        cols,
        (col) => row == 0 ? col : (col == 0 ? row : 0),
        growable: false,
      ),
      growable: false,
    );

    for (var i = 1; i < rows; i += 1) {
      for (var j = 1; j < cols; j += 1) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = matrix[i - 1][j] + 1;
        final insertion = matrix[i][j - 1] + 1;
        final substitution = matrix[i - 1][j - 1] + cost;
        var min = deletion;
        if (insertion < min) {
          min = insertion;
        }
        if (substitution < min) {
          min = substitution;
        }
        matrix[i][j] = min;
      }
    }

    return matrix[a.length][b.length];
  }
}
