import 'package:english_voice_ai_clean/features/voice_chat/application/app_feature_flags.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/learning_api_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/learning_path_controller.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/practice_hub_controller.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/session_history_repository.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/session_history_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/daily_challenge.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/daily_challenge_history.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/learning_unit.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/practice_session_record.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/reading_listening_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/review_queue_item.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/unit_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/user_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'loads units and applies progressive unlock based on previous completion',
      () async {
    final api = _FakeLearningApiService();
    api.units = _buildUnits();
    api.lessonsByUnit = _buildLessonsByUnit();
    api.user = UserProgress.initial().copyWith(
      units: <String, UnitProgress>{
        'u1': UnitProgress.empty('u1', isUnlocked: true).copyWith(
          lessons: <String, LessonProgress>{
            'u1_l1': LessonProgress.empty('u1_l1').copyWith(isCompleted: true),
            'u1_l2': LessonProgress.empty('u1_l2').copyWith(isCompleted: true),
          },
          crowns: 1,
        ),
        'u2': UnitProgress.empty('u2', isUnlocked: false),
      },
      totalXp: 240,
      streakDays: 3,
    );

    final controller = LearningPathController(apiService: api);
    await controller.load();

    final states = controller.unitStatesNotifier.value;
    expect(states['u1']?.isUnlocked, isTrue);
    expect(states['u1']?.isCompleted, isTrue);
    expect(states['u2']?.isUnlocked, isTrue);
    expect(controller.unitsNotifier.value, isNotEmpty);
    expect(controller.unitsNotifier.value.first.lessons, hasLength(2));
    expect(controller.totalXpNotifier.value, 240);
    expect(controller.streakDaysNotifier.value, 3);

    controller.dispose();
  });

  test('uses PracticeHub streak when available', () async {
    final api = _FakeLearningApiService()
      ..units = _buildUnits()
      ..lessonsByUnit = _buildLessonsByUnit()
      ..user = const UserProgress.initial();

    final hub = _FakePracticeHubController();
    hub.weeklySnapshotNotifier.value = const WeeklyProgressSnapshot(
      practicedMinutes: 20,
      activeDays: 3,
      mostUsedFocus: 'Reading',
      currentStreakDays: 9,
      consistencyPercent: 42,
      consistencyLabel: 'Building',
    );

    final controller = LearningPathController(
      apiService: api,
      practiceHubController: hub,
    );
    await controller.load();

    expect(controller.streakDaysNotifier.value, 9);

    controller.dispose();
    hub.dispose();
  });

  test('registerLessonResult persists and refreshes hub', () async {
    final api = _FakeLearningApiService()
      ..units = _buildUnits()
      ..lessonsByUnit = _buildLessonsByUnit()
      ..user = const UserProgress.initial();

    final hub = _FakePracticeHubController();
    final controller = LearningPathController(
      apiService: api,
      practiceHubController: hub,
    );
    await controller.load();

    await controller.registerLessonResult(
      unitId: 'u1',
      progress: LessonProgress.empty('u1_l1').copyWith(
        isCompleted: true,
        bestScore: 88,
        xpEarned: 55,
        attempts: 1,
      ),
      earnedXpDelta: 55,
    );

    expect(api.saveCalls, 1);
    expect(hub.refreshCount, 1);

    controller.dispose();
    hub.dispose();
  });

  test('locks next lesson in same unit until previous is completed', () async {
    final api = _FakeLearningApiService()
      ..units = _buildUnits().take(1).toList(growable: false)
      ..lessonsByUnit = <String, List<Lesson>>{
        'u1': const <Lesson>[
          Lesson(
            id: 'u1_l1',
            unitId: 'u1',
            orderIndex: 0,
            exercises: <LessonExercise>[],
          ),
          Lesson(
            id: 'u1_l2',
            unitId: 'u1',
            orderIndex: 1,
            exercises: <LessonExercise>[],
          ),
        ],
      }
      ..user = UserProgress.initial().copyWith(
        units: <String, UnitProgress>{
          'u1': UnitProgress.empty('u1', isUnlocked: true),
        },
      );

    final controller = LearningPathController(apiService: api);
    await controller.load();

    final state = controller.unitStatesNotifier.value['u1'];
    expect(state, isNotNull);
    expect(state!.lessonUnlocked['u1_l1'], isTrue);
    expect(state.lessonUnlocked['u1_l2'], isFalse);

    controller.dispose();
  });

  test('refreshProgressOnly updates stats without reloading catalog data',
      () async {
    final api = _FakeLearningApiService()
      ..units = _buildUnits()
      ..lessonsByUnit = _buildLessonsByUnit()
      ..user = UserProgress.initial().copyWith(
        units: <String, UnitProgress>{
          'u1': UnitProgress.empty('u1', isUnlocked: true),
          'u2': UnitProgress.empty('u2', isUnlocked: false),
        },
        totalXp: 10,
        streakDays: 1,
      );

    final controller = LearningPathController(apiService: api);
    await controller.load();

    expect(api.getUnitsCalls, 1);
    expect(api.getLessonsForUnitCalls, 2);

    api.user = api.user.copyWith(totalXp: 42, streakDays: 5);
    await controller.refreshProgressOnly();

    expect(api.getUnitsCalls, 1);
    expect(api.getLessonsForUnitCalls, 2);
    expect(controller.totalXpNotifier.value, 42);
    expect(controller.streakDaysNotifier.value, 5);

    controller.dispose();
  });
}

class _FakeLearningApiService implements LearningApiService {
  List<LearningUnit> units = <LearningUnit>[];
  Map<String, List<Lesson>> lessonsByUnit = <String, List<Lesson>>{};
  UserProgress user = const UserProgress.initial();
  int saveCalls = 0;
  int getUnitsCalls = 0;
  int getLessonsForUnitCalls = 0;

  @override
  Future<List<LearningUnit>> getUnits() async {
    getUnitsCalls += 1;
    return units;
  }

  @override
  Future<List<Lesson>> getLessonsForUnit(String unitId) async {
    getLessonsForUnitCalls += 1;
    return lessonsByUnit[unitId] ?? const <Lesson>[];
  }

  @override
  Future<List<LessonExercise>> getExercisesForLesson(String lessonId) async =>
      const <LessonExercise>[];

  @override
  Future<void> saveLessonProgress({
    required String unitId,
    required LessonProgress progress,
    required int earnedXpDelta,
  }) async {
    saveCalls += 1;
  }

  @override
  Future<UnitProgress> getUnitProgress(String unitId) async {
    return user.units[unitId] ?? UnitProgress.empty(unitId, isUnlocked: false);
  }

  @override
  Future<UserProgress> getUserStats() async => user;

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

class _FakePracticeHubController extends PracticeHubController {
  int refreshCount = 0;

  _FakePracticeHubController()
      : super(
          repository: _FakeSessionHistoryRepository(),
          historyService: SessionHistoryService(),
          featureFlags: const AppFeatureFlags(),
        );

  @override
  Future<void> refreshAfterSession() async {
    refreshCount += 1;
  }
}

class _FakeSessionHistoryRepository implements SessionHistoryRepository {
  @override
  Future<DailyChallenge> getDailyChallenge() async {
    return const DailyChallenge(
      dateKey: '2026-03-11',
      topic: 'Reading',
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
    return const <PracticeSessionRecord>[];
  }

  @override
  Future<void> markDailyChallengeCompleted({required String dateKey}) async {}

  @override
  Future<void> saveSession(PracticeSessionRecord session) async {}
}

List<LearningUnit> _buildUnits() {
  return const <LearningUnit>[
    LearningUnit(
      id: 'u1',
      titleEn: 'Unit 1',
      titlePt: 'Unidade 1',
      iconAsset: 'a',
      orderIndex: 0,
      difficulty: ReadingListeningDifficulty.beginner,
      lessons: <Lesson>[],
    ),
    LearningUnit(
      id: 'u2',
      titleEn: 'Unit 2',
      titlePt: 'Unidade 2',
      iconAsset: 'b',
      orderIndex: 1,
      difficulty: ReadingListeningDifficulty.beginner,
      lessons: <Lesson>[],
    ),
  ];
}

Map<String, List<Lesson>> _buildLessonsByUnit() {
  return <String, List<Lesson>>{
    'u1': const <Lesson>[
      Lesson(
        id: 'u1_l1',
        unitId: 'u1',
        orderIndex: 0,
        exercises: <LessonExercise>[],
      ),
      Lesson(
        id: 'u1_l2',
        unitId: 'u1',
        orderIndex: 1,
        exercises: <LessonExercise>[],
      ),
    ],
    'u2': const <Lesson>[
      Lesson(
        id: 'u2_l1',
        unitId: 'u2',
        orderIndex: 0,
        exercises: <LessonExercise>[],
      ),
      Lesson(
        id: 'u2_l2',
        unitId: 'u2',
        orderIndex: 1,
        exercises: <LessonExercise>[],
      ),
    ],
  };
}
