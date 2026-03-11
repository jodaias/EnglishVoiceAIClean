enum ExerciseType {
  multipleChoice,
  listenAndSelect,
  listenAndType,
  fillInTheBlank,
  wordOrder,
  translate,
  matchPairs,
  speakTheSentence,
  trueOrFalse,
}

extension ExerciseTypeX on ExerciseType {
  static ExerciseType fromStorage(String raw) {
    return ExerciseType.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => ExerciseType.multipleChoice,
    );
  }
}
