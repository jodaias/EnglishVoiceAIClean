import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/exercise_type.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/learning_unit.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/reading_listening_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/unit_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/user_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/xp_reward.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Learning path entities', () {
    test('serializes and parses lesson exercise', () {
      const exercise = LessonExercise(
        id: 'ex_1',
        type: ExerciseType.listenAndType,
        difficulty: ReadingListeningDifficulty.intermediate,
        content: <String, dynamic>{
          'promptEn': 'How are you?',
          'promptPt': 'Como vai voce?',
          'answer': 'How are you?',
        },
      );

      final parsed = LessonExercise.fromJson(exercise.toJson());

      expect(parsed.id, 'ex_1');
      expect(parsed.type, ExerciseType.listenAndType);
      expect(parsed.difficulty, ReadingListeningDifficulty.intermediate);
      expect(parsed.content['answer'], 'How are you?');
    });

    test('serializes and parses lesson and learning unit', () {
      const lesson = Lesson(
        id: 'lesson_1',
        unitId: 'unit_1',
        orderIndex: 0,
        exercises: <LessonExercise>[
          LessonExercise(
            id: 'ex_1',
            type: ExerciseType.multipleChoice,
            difficulty: ReadingListeningDifficulty.beginner,
            content: <String, dynamic>{'questionEn': 'Choose the right one'},
          ),
        ],
      );

      const unit = LearningUnit(
        id: 'unit_1',
        titleEn: 'Greetings',
        titlePt: 'Cumprimentos',
        iconAsset: 'assets/images/greetings.png',
        orderIndex: 0,
        difficulty: ReadingListeningDifficulty.beginner,
        lessons: <Lesson>[lesson],
      );

      final parsed = LearningUnit.fromJson(unit.toJson());

      expect(parsed.id, 'unit_1');
      expect(parsed.lessons, hasLength(1));
      expect(parsed.lessons.first.exercises, hasLength(1));
      expect(parsed.lessons.first.exercises.first.type,
          ExerciseType.multipleChoice);
    });

    test('serializes and parses user progress tree', () {
      final lessonProgress = LessonProgress.empty('lesson_1').copyWith(
        isCompleted: true,
        bestScore: 90,
        xpEarned: 60,
        attempts: 2,
        completedAt: DateTime.utc(2026, 3, 11, 10, 0, 0),
      );

      final unitProgress =
          UnitProgress.empty('unit_1', isUnlocked: true).copyWith(
        crowns: 2,
        lessons: <String, LessonProgress>{'lesson_1': lessonProgress},
      );

      final progress = UserProgress.initial().copyWith(
        units: <String, UnitProgress>{'unit_1': unitProgress},
        totalXp: 180,
        availableHearts: 4,
        heartsRefillAt: DateTime.utc(2026, 3, 11, 12, 0, 0),
        streakDays: 5,
        lastCompletedDateKey: '2026-03-11',
      );

      final parsed = UserProgress.fromJson(progress.toJson());

      expect(parsed.totalXp, 180);
      expect(parsed.availableHearts, 4);
      expect(parsed.streakDays, 5);
      expect(parsed.units['unit_1']?.crowns, 2);
      expect(parsed.units['unit_1']?.lessons['lesson_1']?.bestScore, 90);
    });

    test('calculates xp rewards according to rules', () {
      final reward = XpReward.fromResult(
        isCorrect: true,
        firstTry: true,
        perfectLesson: true,
        pronunciationAccuracyPercent: 93,
      );

      expect(reward.baseXp, 10);
      expect(reward.firstTryBonus, 5);
      expect(reward.perfectLessonBonus, 20);
      expect(reward.pronunciationBonus, 10);
      expect(reward.total, 45);
    });

    test('gives no base xp when answer is incorrect', () {
      final reward = XpReward.fromResult(
        isCorrect: false,
        firstTry: true,
        perfectLesson: false,
        pronunciationAccuracyPercent: 70,
      );

      expect(reward.total, 0);
    });
  });
}
