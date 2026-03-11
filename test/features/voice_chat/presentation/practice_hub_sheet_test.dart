import 'package:english_voice_ai_clean/features/voice_chat/application/app_feature_flags.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/practice_hub_controller.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/session_history_repository.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/session_history_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/conversation_language.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/daily_challenge.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/daily_challenge_history.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/practice_session_record.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/practice_hub_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PracticeHubSheet triggers surprise lesson callback',
      (tester) async {
    final controller = PracticeHubController(
      repository: _FakeSessionHistoryRepository(),
      historyService: SessionHistoryService(),
      featureFlags: const AppFeatureFlags(),
    );

    var triggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PracticeHubSheet(
            controller: controller,
            onOpenSurpriseLesson: () {
              triggered = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Start surprise lesson'));
    await tester.pumpAndSettle();

    expect(triggered, isTrue);

    controller.dispose();
  });

  testWidgets('PracticeHubSheet triggers daily review callback when due',
      (tester) async {
    final controller = PracticeHubController(
      repository: _FakeSessionHistoryRepository(),
      historyService: SessionHistoryService(),
      featureFlags: const AppFeatureFlags(),
    );
    controller.pendingReviewCountNotifier.value = 3;

    var triggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PracticeHubSheet(
            controller: controller,
            onOpenDailyReview: () {
              triggered = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Start daily review'));
    await tester.pumpAndSettle();

    expect(triggered, isTrue);

    controller.dispose();
  });
}

class _FakeSessionHistoryRepository implements SessionHistoryRepository {
  @override
  Future<DailyChallenge> getDailyChallenge() async {
    return DailyChallenge(
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
