import 'package:english_voice_ai_clean/features/voice_chat/application/learning_api_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/learning_path_controller.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/learning_unit.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/reading_listening_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/review_queue_item.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/unit_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/user_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/learning_path_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LearningPathPage renders unit banners and lesson nodes',
      (tester) async {
    final controller =
        LearningPathController(apiService: _FakeLearningApiService());

    await tester.pumpWidget(
      MaterialApp(
        home: LearningPathPage(controller: controller),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Learning path'), findsOneWidget);
    expect(find.text('Greetings'), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('lesson-node-l1')), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('lesson-node-l2')), findsOneWidget);

    controller.dispose();
  });

  testWidgets('LearningPathPage triggers open callback for unlocked lesson',
      (tester) async {
    final controller =
        LearningPathController(apiService: _FakeLearningApiService());
    String? openedLessonId;

    await tester.pumpWidget(
      MaterialApp(
        home: LearningPathPage(
          controller: controller,
          onOpenLesson: (context, unitId, lesson) async {
            openedLessonId = lesson.id;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('lesson-node-l1')));
    await tester.pumpAndSettle();

    expect(openedLessonId, 'l1');

    controller.dispose();
  });

  testWidgets(
      'LearningPathPage keeps lesson 2 locked until lesson 1 is completed',
      (tester) async {
    final controller = LearningPathController(
      apiService: _FakeLearningApiService(firstLessonCompleted: false),
    );
    String? openedLessonId;

    await tester.pumpWidget(
      MaterialApp(
        home: LearningPathPage(
          controller: controller,
          onOpenLesson: (context, unitId, lesson) async {
            openedLessonId = lesson.id;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('lesson-node-l2')));
    await tester.pumpAndSettle();

    expect(openedLessonId, isNull);

    controller.dispose();
  });
}

class _FakeLearningApiService implements LearningApiService {
  final bool firstLessonCompleted;

  _FakeLearningApiService({this.firstLessonCompleted = true});

  @override
  Future<List<LearningUnit>> getUnits() async {
    return <LearningUnit>[
      LearningUnit(
        id: 'u1',
        titleEn: 'Greetings',
        titlePt: 'Cumprimentos',
        iconAsset: 'assets/images/scenes/studio_scene.png',
        orderIndex: 0,
        difficulty: ReadingListeningDifficulty.beginner,
        lessons: const <Lesson>[
          Lesson(
              id: 'l1',
              unitId: 'u1',
              orderIndex: 0,
              exercises: <LessonExercise>[]),
          Lesson(
              id: 'l2',
              unitId: 'u1',
              orderIndex: 1,
              exercises: <LessonExercise>[]),
        ],
      ),
    ];
  }

  @override
  Future<List<Lesson>> getLessonsForUnit(String unitId) async {
    return const <Lesson>[
      Lesson(
          id: 'l1', unitId: 'u1', orderIndex: 0, exercises: <LessonExercise>[]),
      Lesson(
          id: 'l2', unitId: 'u1', orderIndex: 1, exercises: <LessonExercise>[]),
    ];
  }

  @override
  Future<List<LessonExercise>> getExercisesForLesson(String lessonId) async {
    return const <LessonExercise>[];
  }

  @override
  Future<void> saveLessonProgress({
    required String unitId,
    required LessonProgress progress,
    required int earnedXpDelta,
  }) async {}

  @override
  Future<UnitProgress> getUnitProgress(String unitId) async {
    return UnitProgress.empty(unitId, isUnlocked: true);
  }

  @override
  Future<UserProgress> getUserStats() async {
    final lessons = <String, LessonProgress>{};
    if (firstLessonCompleted) {
      lessons['l1'] = LessonProgress.empty('l1')
          .copyWith(isCompleted: true, bestScore: 100);
    }

    return UserProgress.initial().copyWith(
      units: <String, UnitProgress>{
        'u1': UnitProgress.empty('u1', isUnlocked: true).copyWith(
          lessons: lessons,
          crowns: 1,
        ),
      },
      totalXp: 320,
      streakDays: 4,
      availableHearts: 5,
    );
  }

  @override
  Future<List<ReviewQueueItem>> getReviewQueue({DateTime? until}) async {
    return const <ReviewQueueItem>[];
  }

  @override
  Future<void> upsertReviewItem(ReviewQueueItem item) async {}

  @override
  Future<void> updateReviewItem(ReviewQueueItem item) async {}

  @override
  Future<void> removeReviewItem(String exerciseId) async {}
}
