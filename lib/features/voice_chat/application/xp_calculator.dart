import '../domain/entities/xp_reward.dart';

class XpCalculator {
  const XpCalculator();

  int calculateExerciseXp({
    required bool isCorrect,
    required bool firstTry,
    int pronunciationAccuracyPercent = 0,
  }) {
    final reward = XpReward.fromResult(
      isCorrect: isCorrect,
      firstTry: firstTry,
      perfectLesson: false,
      pronunciationAccuracyPercent: pronunciationAccuracyPercent,
    );

    return reward.baseXp + reward.firstTryBonus + reward.pronunciationBonus;
  }

  int calculateLessonBonus({
    required int totalExercises,
    required int correctExercises,
  }) {
    if (totalExercises <= 0 || correctExercises != totalExercises) {
      return 0;
    }
    return XpReward.xpPerfectLessonBonus;
  }

  int calculateLessonTotalXp({
    required int baseExerciseXp,
    required int totalExercises,
    required int correctExercises,
  }) {
    return baseExerciseXp +
        calculateLessonBonus(
          totalExercises: totalExercises,
          correctExercises: correctExercises,
        );
  }
}
