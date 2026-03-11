import 'package:flutter/foundation.dart';

import '../domain/entities/lesson.dart';
import '../domain/entities/lesson_progress.dart';
import '../domain/entities/learning_unit.dart';
import '../domain/entities/unit_progress.dart';
import '../domain/entities/user_progress.dart';
import 'learning_api_service.dart';
import 'practice_hub_controller.dart';

class LearningPathUnitState {
  final LearningUnit unit;
  final UnitProgress progress;
  final Map<String, bool> lessonUnlocked;
  final bool isUnlocked;
  final bool isCompleted;
  final int completionPercent;

  const LearningPathUnitState({
    required this.unit,
    required this.progress,
    required this.lessonUnlocked,
    required this.isUnlocked,
    required this.isCompleted,
    required this.completionPercent,
  });
}

class LearningPathController {
  final LearningApiService apiService;
  final PracticeHubController? practiceHubController;

  final ValueNotifier<List<LearningUnit>> unitsNotifier =
      ValueNotifier<List<LearningUnit>>(<LearningUnit>[]);
  final ValueNotifier<Map<String, LearningPathUnitState>> unitStatesNotifier =
      ValueNotifier<Map<String, LearningPathUnitState>>(
          <String, LearningPathUnitState>{});
  final ValueNotifier<int> totalXpNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> streakDaysNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> availableHeartsNotifier = ValueNotifier<int>(5);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  LearningPathController({
    required this.apiService,
    this.practiceHubController,
  });

  Future<void> load() async {
    isLoadingNotifier.value = true;
    errorNotifier.value = null;

    try {
      final units = List<LearningUnit>.from(await apiService.getUnits());
      final user = await apiService.getUserStats();
      final hydratedUnits = <LearningUnit>[];

      units.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      final states = <String, LearningPathUnitState>{};
      for (var i = 0; i < units.length; i += 1) {
        final unit = units[i];
        final orderedLessons = List<Lesson>.from(
          await apiService.getLessonsForUnit(unit.id),
        )..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        final progress = user.units[unit.id] ??
            UnitProgress.empty(unit.id, isUnlocked: i == 0);

        final synchronizedProgress = _synchronizeCrowns(
          progress: progress,
          lessonsCount: orderedLessons.length,
        );

        final shouldUnlock =
            i == 0 || _isPreviousUnitCompleted(units[i - 1], states);
        final unlocked = synchronizedProgress.isUnlocked || shouldUnlock;
        final lessonUnlockMap = _buildLessonUnlockMap(
          lessons: orderedLessons,
          unitUnlocked: unlocked,
          lessonProgress: synchronizedProgress.lessons,
        );

        final completionPercent = _completionPercent(
            synchronizedProgress.lessons, orderedLessons.length);

        states[unit.id] = LearningPathUnitState(
          unit: LearningUnit(
            id: unit.id,
            titleEn: unit.titleEn,
            titlePt: unit.titlePt,
            iconAsset: unit.iconAsset,
            orderIndex: unit.orderIndex,
            difficulty: unit.difficulty,
            lessons: orderedLessons,
          ),
          progress: synchronizedProgress.copyWith(isUnlocked: unlocked),
          lessonUnlocked: lessonUnlockMap,
          isUnlocked: unlocked,
          isCompleted: completionPercent == 100,
          completionPercent: completionPercent,
        );
        hydratedUnits.add(states[unit.id]!.unit);
      }

      unitsNotifier.value = hydratedUnits;
      unitStatesNotifier.value = states;
      totalXpNotifier.value = user.totalXp;
      streakDaysNotifier.value = _resolveStreakDays(user);
      availableHeartsNotifier.value = user.availableHearts;
    } catch (_) {
      errorNotifier.value =
          'Não foi possível carregar a trilha de aprendizado.';
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> refresh() async {
    await load();
  }

  Future<void> refreshProgressOnly() async {
    errorNotifier.value = null;

    final currentUnits = List<LearningUnit>.from(unitsNotifier.value);
    if (currentUnits.isEmpty) {
      await load();
      return;
    }

    try {
      final user = await apiService.getUserStats();
      final updatedStates = <String, LearningPathUnitState>{};
      final hydratedUnits = <LearningUnit>[];

      for (var i = 0; i < currentUnits.length; i += 1) {
        final unit = currentUnits[i];
        final previousState = unitStatesNotifier.value[unit.id];
        final baseProgress = user.units[unit.id] ??
            previousState?.progress ??
            UnitProgress.empty(unit.id, isUnlocked: i == 0);

        final synchronizedProgress = _synchronizeCrowns(
          progress: baseProgress,
          lessonsCount: unit.lessons.length,
        );

        final shouldUnlock = i == 0 ||
            _isPreviousUnitCompleted(currentUnits[i - 1], updatedStates);
        final unlocked = synchronizedProgress.isUnlocked || shouldUnlock;

        final completionPercent = _completionPercent(
            synchronizedProgress.lessons, unit.lessons.length);
        final lessonUnlockMap = _buildLessonUnlockMap(
          lessons: unit.lessons,
          unitUnlocked: unlocked,
          lessonProgress: synchronizedProgress.lessons,
        );

        final state = LearningPathUnitState(
          unit: unit,
          progress: synchronizedProgress.copyWith(isUnlocked: unlocked),
          lessonUnlocked: lessonUnlockMap,
          isUnlocked: unlocked,
          isCompleted: completionPercent == 100,
          completionPercent: completionPercent,
        );
        updatedStates[unit.id] = state;
        hydratedUnits.add(state.unit);
      }

      unitsNotifier.value = hydratedUnits;
      unitStatesNotifier.value = updatedStates;
      totalXpNotifier.value = user.totalXp;
      streakDaysNotifier.value = _resolveStreakDays(user);
      availableHeartsNotifier.value = user.availableHearts;
    } catch (_) {
      errorNotifier.value = 'Não foi possível atualizar o progresso da trilha.';
    }
  }

  Future<void> registerLessonResult({
    required String unitId,
    required LessonProgress progress,
    required int earnedXpDelta,
  }) async {
    await apiService.saveLessonProgress(
      unitId: unitId,
      progress: progress,
      earnedXpDelta: earnedXpDelta,
    );

    if (practiceHubController != null) {
      await practiceHubController!.refreshAfterSession();
    }

    await load();
  }

  void dispose() {
    unitsNotifier.dispose();
    unitStatesNotifier.dispose();
    totalXpNotifier.dispose();
    streakDaysNotifier.dispose();
    availableHeartsNotifier.dispose();
    isLoadingNotifier.dispose();
    errorNotifier.dispose();
  }

  UnitProgress _synchronizeCrowns({
    required UnitProgress progress,
    required int lessonsCount,
  }) {
    final completedLessons =
        progress.lessons.values.where((lesson) => lesson.isCompleted).length;

    // Crowns should never exceed 5 and should at least reflect one full unit completion cycle.
    final expectedFromCompletion =
        lessonsCount == 0 ? 0 : (completedLessons ~/ lessonsCount).clamp(0, 5);

    final crowns = progress.crowns < expectedFromCompletion
        ? expectedFromCompletion
        : progress.crowns.clamp(0, 5);

    return progress.copyWith(crowns: crowns);
  }

  bool _isPreviousUnitCompleted(
    LearningUnit previousUnit,
    Map<String, LearningPathUnitState> currentStates,
  ) {
    final previous = currentStates[previousUnit.id];
    return previous?.isCompleted == true;
  }

  int _completionPercent(
      Map<String, LessonProgress> lessons, int lessonsCount) {
    if (lessonsCount <= 0) {
      return 0;
    }
    final completed = lessons.values.where((item) => item.isCompleted).length;
    return ((completed / lessonsCount) * 100).round();
  }

  Map<String, bool> _buildLessonUnlockMap({
    required List<Lesson> lessons,
    required bool unitUnlocked,
    required Map<String, LessonProgress> lessonProgress,
  }) {
    final lessonUnlockMap = <String, bool>{};
    if (lessons.isEmpty || !unitUnlocked) {
      for (final lesson in lessons) {
        lessonUnlockMap[lesson.id] = false;
      }
      return lessonUnlockMap;
    }

    for (var index = 0; index < lessons.length; index += 1) {
      final lesson = lessons[index];
      if (index == 0) {
        lessonUnlockMap[lesson.id] = true;
        continue;
      }

      final previousLesson = lessons[index - 1];
      final previousProgress = lessonProgress[previousLesson.id];
      lessonUnlockMap[lesson.id] = previousProgress?.isCompleted == true;
    }

    return lessonUnlockMap;
  }

  int _resolveStreakDays(UserProgress user) {
    final fromPracticeHub =
        practiceHubController?.weeklySnapshotNotifier.value?.currentStreakDays;
    if (fromPracticeHub != null) {
      return fromPracticeHub;
    }
    return user.streakDays;
  }
}

