import 'package:flutter/foundation.dart';

import 'app_feature_flags.dart';
import 'session_history_repository.dart';
import 'session_history_service.dart';
import '../domain/entities/daily_challenge.dart';
import '../domain/entities/daily_challenge_history.dart';
import '../domain/entities/practice_session_record.dart';

class PracticeHubController {
  final SessionHistoryRepository repository;
  final SessionHistoryService historyService;
  final AppFeatureFlags featureFlags;

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

  PracticeHubController({
    required this.repository,
    required this.historyService,
    required this.featureFlags,
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
    } finally {
      isLoadingNotifier.value = false;
    }
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

    final filtered = source.where((session) {
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
  }
}
