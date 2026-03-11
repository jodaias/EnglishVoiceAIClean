import 'package:english_voice_ai_clean/features/voice_chat/application/xp_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = XpCalculator();

  test('calculates exercise xp with first try and pronunciation bonus', () {
    final xp = calculator.calculateExerciseXp(
      isCorrect: true,
      firstTry: true,
      pronunciationAccuracyPercent: 95,
    );

    expect(xp, 25);
  });

  test('returns zero for incorrect answer', () {
    final xp = calculator.calculateExerciseXp(
      isCorrect: false,
      firstTry: true,
      pronunciationAccuracyPercent: 95,
    );

    expect(xp, 0);
  });

  test('adds perfect lesson bonus only when all are correct', () {
    final bonusPerfect = calculator.calculateLessonBonus(
      totalExercises: 6,
      correctExercises: 6,
    );
    final bonusNotPerfect = calculator.calculateLessonBonus(
      totalExercises: 6,
      correctExercises: 5,
    );

    expect(bonusPerfect, 20);
    expect(bonusNotPerfect, 0);
  });

  test('combines base and lesson bonus', () {
    final total = calculator.calculateLessonTotalXp(
      baseExerciseXp: 80,
      totalExercises: 8,
      correctExercises: 8,
    );

    expect(total, 100);
  });
}
