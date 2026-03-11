import 'package:english_voice_ai_clean/features/voice_chat/application/app_feature_flags.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/learning_api_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/lesson_content_catalog.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/practice_hub_controller.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/session_history_repository.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/session_history_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/spaced_repetition_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/conversation_language.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/daily_challenge.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/daily_challenge_history.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/exercise_type.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/learning_unit.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/practice_session_record.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/reading_listening_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/review_queue_item.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/unit_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/user_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/ai/exercise_generation_cache.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/ai/exercise_generator_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/practice_overview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'PracticeOverviewPage uses local fallback lesson when AI returns 429',
      (tester) async {
    final learningApi = _FakeLearningApiService();
    final controller = PracticeHubController(
      repository: _FakeSessionHistoryRepository(),
      historyService: SessionHistoryService(),
      featureFlags: const AppFeatureFlags(),
      learningApiService: learningApi,
    );

    final generator = ExerciseGeneratorService(
      cache: _InMemoryExerciseCache(),
      executePrompt: (_) async {
        throw const AIQuotaExceededException(statusCode: 429);
      },
    );

    final spaced = SpacedRepetitionService(
      learningApiService: learningApi,
      trackableExerciseIds: const <String>{'fallback_e1'},
    );

    Lesson? openedLesson;

    await tester.pumpWidget(
      MaterialApp(
        home: PracticeOverviewPage(
          practiceHubController: controller,
          exerciseGeneratorService: generator,
          lessonContentCatalog: _FakeLessonContentCatalog(),
          spacedRepetitionService: spaced,
          onOpenLesson: (context, lesson, _) async {
            openedLesson = lesson;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Start surprise lesson'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generate'));
    await tester.pumpAndSettle();

    expect(openedLesson, isNotNull);
    expect(openedLesson!.unitId, 'unit_surprise_fallback');
    expect(openedLesson!.exercises, isNotEmpty);
    expect(
      find.textContaining('Starting a curated fallback lesson now'),
      findsOneWidget,
    );

    controller.dispose();
  });
}

class _FakeLessonContentCatalog extends LessonContentCatalog {
  @override
  List<LearningUnit> loadDefaultUnits() {
    return <LearningUnit>[
      const LearningUnit(
        id: 'unit_greetings',
        titleEn: 'Greetings',
        titlePt: 'Cumprimentos',
        iconAsset: 'assets/images/scenes/studio_scene.png',
        orderIndex: 0,
        difficulty: ReadingListeningDifficulty.beginner,
        lessons: <Lesson>[
          Lesson(
            id: 'lesson_fallback',
            unitId: 'unit_greetings',
            orderIndex: 0,
            exercises: <LessonExercise>[
              LessonExercise(
                id: 'fallback_e1',
                type: ExerciseType.multipleChoice,
                difficulty: ReadingListeningDifficulty.beginner,
                content: <String, dynamic>{
                  'promptEn': 'Choose one',
                  'promptPt': 'Escolha uma',
                  'optionsEn': <String>['A', 'B', 'C'],
                  'optionsPt': <String>['A', 'B', 'C'],
                  'correctOptionIndex': 0,
                },
              ),
            ],
          ),
        ],
      ),
    ];
  }
}

class _FakeSessionHistoryRepository implements SessionHistoryRepository {
  @override
  Future<DailyChallenge> getDailyChallenge() async {
    return const DailyChallenge(
      dateKey: '2026-03-11',
      topic: 'Greetings',
      targetMinutes: 5,
      isCompleted: false,
    );
  }

  @override
  Future<DailyChallengeHistory> getDailyChallengeHistory() async {
    return const DailyChallengeHistory(completedDateKeys: <String>[]);
  }

  @override
  Future<List<PracticeSessionRecord>> getSessions() async {
    return <PracticeSessionRecord>[
      PracticeSessionRecord(
        id: 's1',
        startedAt: DateTime(2026, 3, 10, 10),
        endedAt: DateTime(2026, 3, 10, 10, 12),
        practiceFocus: 'Greetings',
        userTurns: 5,
        elapsedSeconds: 720,
        language: ConversationLanguage.englishUs,
        feedback: 'Great pace.',
      ),
    ];
  }

  @override
  Future<void> markDailyChallengeCompleted({required String dateKey}) async {}

  @override
  Future<void> saveSession(PracticeSessionRecord session) async {}
}

class _FakeLearningApiService implements LearningApiService {
  @override
  Future<List<LearningUnit>> getUnits() async => const <LearningUnit>[];

  @override
  Future<List<Lesson>> getLessonsForUnit(String unitId) async =>
      const <Lesson>[];

  @override
  Future<List<LessonExercise>> getExercisesForLesson(String lessonId) async =>
      const <LessonExercise>[];

  @override
  Future<void> saveLessonProgress({
    required String unitId,
    required LessonProgress progress,
    required int earnedXpDelta,
  }) async {}

  @override
  Future<UnitProgress> getUnitProgress(String unitId) async =>
      UnitProgress.empty(unitId, isUnlocked: true);

  @override
  Future<UserProgress> getUserStats() async => const UserProgress.initial();

  @override
  Future<List<ReviewQueueItem>> getReviewQueue({DateTime? until}) async =>
      const <ReviewQueueItem>[];

  @override
  Future<void> upsertReviewItem(ReviewQueueItem item) async {}

  @override
  Future<void> updateReviewItem(ReviewQueueItem item) async {}

  @override
  Future<void> removeReviewItem(String exerciseId) async {}
}

class _InMemoryExerciseCache implements ExerciseGenerationCache {
  @override
  Future<LessonExercise?> get(String key) async => null;

  @override
  Future<void> put(String key, LessonExercise exercise) async {}
}
