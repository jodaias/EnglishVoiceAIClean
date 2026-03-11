import 'package:flutter/foundation.dart';

import '../domain/entities/lesson_progress.dart';
import '../domain/entities/learning_unit.dart';
import '../domain/entities/unit_progress.dart';
import '../domain/entities/user_progress.dart';
import 'learning_api_service.dart';
import 'practice_hub_controller.dart';

class LearningPathUnitState {
  final LearningUnit unit;
  final UnitProgress progress;
  final bool isUnlocked;
  final bool isCompleted;
  final int completionPercent;

  const LearningPathUnitState({
    required this.unit,
    required this.progress,
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

      units.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      final states = <String, LearningPathUnitState>{};
      for (var i = 0; i < units.length; i += 1) {
        final unit = units[i];
        final lessons = await apiService.getLessonsForUnit(unit.id);
        final progress = user.units[unit.id] ??
            UnitProgress.empty(unit.id, isUnlocked: i == 0);

        final synchronizedProgress = _synchronizeCrowns(
          progress: progress,
          lessonsCount: lessons.length,
        );

        final shouldUnlock =
            i == 0 || _isPreviousUnitCompleted(units[i - 1], states);
        final unlocked = synchronizedProgress.isUnlocked || shouldUnlock;

        final completionPercent =
            _completionPercent(synchronizedProgress.lessons, lessons.length);

        states[unit.id] = LearningPathUnitState(
          unit: LearningUnit(
            id: unit.id,
            titleEn: unit.titleEn,
            titlePt: unit.titlePt,
            iconAsset: unit.iconAsset,
            orderIndex: unit.orderIndex,
            difficulty: unit.difficulty,
            lessons: lessons,
          ),
          progress: synchronizedProgress.copyWith(isUnlocked: unlocked),
          isUnlocked: unlocked,
          isCompleted: completionPercent == 100,
          completionPercent: completionPercent,
        );
      }

      unitsNotifier.value = units;
      unitStatesNotifier.value = states;
      totalXpNotifier.value = user.totalXp;
      streakDaysNotifier.value = _resolveStreakDays(user);
    } catch (_) {
      errorNotifier.value =
          'Nao foi possivel carregar a trilha de aprendizado.';
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> refresh() async {
    await load();
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

  int _resolveStreakDays(UserProgress user) {
    final fromPracticeHub =
        practiceHubController?.weeklySnapshotNotifier.value?.currentStreakDays;
    if (fromPracticeHub != null) {
      return fromPracticeHub;
    }
    return user.streakDays;
  }
}
