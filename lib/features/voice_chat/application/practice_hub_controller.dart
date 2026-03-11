import 'package:flutter/foundation.dart';

import 'app_feature_flags.dart';
import 'learning_api_service.dart';
import 'lesson_content_catalog.dart';
import 'session_history_repository.dart';
import 'session_history_service.dart';
import '../domain/entities/daily_challenge.dart';
import '../domain/entities/daily_challenge_history.dart';
import '../domain/entities/lesson.dart';
import '../domain/entities/lesson_exercise.dart';
import '../domain/entities/practice_session_record.dart';

enum SessionDateRange { allTime, last7Days, last30Days }

class PracticeHubController {
  final SessionHistoryRepository repository;
  final SessionHistoryService historyService;
  final AppFeatureFlags featureFlags;
  final LearningApiService? learningApiService;

  final ValueNotifier<List<PracticeSessionRecord>> sessionsNotifier =
      ValueNotifier<List<PracticeSessionRecord>>(<PracticeSessionRecord>[]);
  final ValueNotifier<WeeklyProgressSnapshot?> weeklySnapshotNotifier =
      ValueNotifier<WeeklyProgressSnapshot?>(null);
  final ValueNotifier<DailyChallenge?> dailyChallengeNotifier =
      ValueNotifier<DailyChallenge?>(null);
  final ValueNotifier<DailyChallengeHistory> dailyChallengeHistoryNotifier =
      ValueNotifier<DailyChallengeHistory>(
    const DailyChallengeHistory(completedDateKeys: <String>[]),
  );
  final ValueNotifier<String> sessionSearchQueryNotifier =
      ValueNotifier<String>('');
  final ValueNotifier<String?> sessionFocusFilterNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<List<PracticeSessionRecord>> filteredSessionsNotifier =
      ValueNotifier<List<PracticeSessionRecord>>(<PracticeSessionRecord>[]);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<SessionDateRange> sessionDateRangeNotifier =
      ValueNotifier<SessionDateRange>(SessionDateRange.allTime);
  final ValueNotifier<int> pendingReviewCountNotifier = ValueNotifier<int>(0);

  PracticeHubController({
    required this.repository,
    required this.historyService,
    required this.featureFlags,
    this.learningApiService,
  });

  Future<void> load() async {
    isLoadingNotifier.value = true;
    try {
      final sessions = await repository.getSessions();
      final challenge = await repository.getDailyChallenge();
      final challengeHistory = await repository.getDailyChallengeHistory();
      final snapshot = historyService.buildWeeklySnapshot(
        sessions: sessions,
        now: DateTime.now(),
      );

      sessionsNotifier.value = sessions;
      _refreshFilteredSessions();
      dailyChallengeNotifier.value = challenge;
      dailyChallengeHistoryNotifier.value = challengeHistory;
      weeklySnapshotNotifier.value = snapshot;

      final api = learningApiService;
      if (api != null) {
        final pending = await api.getReviewQueue(until: DateTime.now());
        pendingReviewCountNotifier.value = pending.length;
      } else {
        pendingReviewCountNotifier.value = 0;
      }
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<Lesson?> buildDailyReviewLesson({int maxExercises = 6}) async {
    final api = learningApiService;
    if (api == null) {
      return null;
    }

    final pending = await api.getReviewQueue(until: DateTime.now());
    if (pending.isEmpty) {
      return null;
    }

    final index = _exerciseIndexFromCatalog();
    final selectedExercises = <LessonExercise>[];

    for (final item in pending) {
      final exercise = index[item.exerciseId];
      if (exercise == null) {
        continue;
      }
      selectedExercises.add(exercise);
      if (selectedExercises.length >= maxExercises) {
        break;
      }
    }

    if (selectedExercises.isEmpty) {
      return null;
    }

    return Lesson(
      id: 'daily_review_${DateTime.now().millisecondsSinceEpoch}',
      unitId: 'unit_daily_review',
      orderIndex: 0,
      exercises: selectedExercises,
    );
  }

  Map<String, LessonExercise> _exerciseIndexFromCatalog() {
    final units = LessonContentCatalog().loadDefaultUnits();
    return {
      for (final unit in units)
        for (final lesson in unit.lessons)
          for (final exercise in lesson.exercises) exercise.id: exercise,
    };
  }

  Future<void> markDailyChallengeCompleted() async {
    final challenge = dailyChallengeNotifier.value;
    if (challenge == null || challenge.isCompleted) {
      return;
    }

    await repository.markDailyChallengeCompleted(dateKey: challenge.dateKey);
    dailyChallengeNotifier.value = challenge.copyWith(isCompleted: true);
    final history = dailyChallengeHistoryNotifier.value;
    dailyChallengeHistoryNotifier.value = history.addDateKey(challenge.dateKey);
  }

  void setSessionSearchQuery(String value) {
    sessionSearchQueryNotifier.value = value;
    _refreshFilteredSessions();
  }

  void setSessionFocusFilter(String? value) {
    sessionFocusFilterNotifier.value =
        (value == null || value.trim().isEmpty) ? null : value;
    _refreshFilteredSessions();
  }

  void setSessionDateRange(SessionDateRange value) {
    sessionDateRangeNotifier.value = value;
    _refreshFilteredSessions();
  }

  List<String> availableFocusFilters() {
    final set = sessionsNotifier.value
        .map((session) => session.practiceFocus)
        .where((focus) => focus.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return set;
  }

  void _refreshFilteredSessions() {
    final source = sessionsNotifier.value;
    final query = sessionSearchQueryNotifier.value.trim().toLowerCase();
    final selectedFocus = sessionFocusFilterNotifier.value;
    final dateRange = sessionDateRangeNotifier.value;
    final now = DateTime.now();

    final filtered = source.where((session) {
      if (dateRange == SessionDateRange.last7Days) {
        final cutoff = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 7));
        if (session.endedAt.isBefore(cutoff)) return false;
      } else if (dateRange == SessionDateRange.last30Days) {
        final cutoff = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 30));
        if (session.endedAt.isBefore(cutoff)) return false;
      }

      final focusMatches = selectedFocus == null
          ? true
          : session.practiceFocus.toLowerCase() == selectedFocus.toLowerCase();
      if (!focusMatches) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final combined =
          '${session.practiceFocus} ${session.feedback}'.toLowerCase();
      return combined.contains(query);
    }).toList(growable: false);

    filteredSessionsNotifier.value = filtered;
  }

  Future<void> refreshAfterSession() async {
    await load();
  }

  void dispose() {
    sessionsNotifier.dispose();
    weeklySnapshotNotifier.dispose();
    dailyChallengeNotifier.dispose();
    dailyChallengeHistoryNotifier.dispose();
    sessionSearchQueryNotifier.dispose();
    sessionFocusFilterNotifier.dispose();
    filteredSessionsNotifier.dispose();
    isLoadingNotifier.dispose();
    sessionDateRangeNotifier.dispose();
    pendingReviewCountNotifier.dispose();
  }
}
