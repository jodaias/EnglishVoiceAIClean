class XpReward {
  static const int xpPerCorrectExercise = 10;
  static const int xpFirstTryBonus = 5;
  static const int xpPerfectLessonBonus = 20;
  static const int xpHighPronunciationBonus = 10;

  final int baseXp;
  final int firstTryBonus;
  final int perfectLessonBonus;
  final int pronunciationBonus;

  const XpReward({
    required this.baseXp,
    required this.firstTryBonus,
    required this.perfectLessonBonus,
    required this.pronunciationBonus,
  });

  int get total =>
      baseXp + firstTryBonus + perfectLessonBonus + pronunciationBonus;

  static XpReward fromResult({
    required bool isCorrect,
    required bool firstTry,
    required bool perfectLesson,
    required int pronunciationAccuracyPercent,
  }) {
    final baseXp = isCorrect ? xpPerCorrectExercise : 0;
    final firstTryBonus = isCorrect && firstTry ? xpFirstTryBonus : 0;
    final perfectLessonBonus = perfectLesson ? xpPerfectLessonBonus : 0;
    final pronunciationBonus = isCorrect && pronunciationAccuracyPercent >= 90
        ? xpHighPronunciationBonus
        : 0;

    return XpReward(
      baseXp: baseXp,
      firstTryBonus: firstTryBonus,
      perfectLessonBonus: perfectLessonBonus,
      pronunciationBonus: pronunciationBonus,
    );
  }
}
