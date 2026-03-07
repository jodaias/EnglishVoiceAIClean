import 'dart:io';

import 'package:english_voice_ai_clean/features/voice_chat/application/app_feature_flags.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/practice_hub_controller.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/session_history_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/conversation_language.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/practice_session_record.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/local/local_session_history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('voice_chat_hive_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen('voice_chat_local_v1')) {
      await Hive.box<dynamic>('voice_chat_local_v1').clear();
      await Hive.box<dynamic>('voice_chat_local_v1').close();
    }
    await Hive.deleteBoxFromDisk('voice_chat_local_v1');
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PracticeHubController + Hive integration', () {
    test('load reads sessions/challenge and computes weekly snapshot',
        () async {
      final repository = LocalSessionHistoryRepository();
      final now = DateTime.now();

      await repository.saveSession(
        PracticeSessionRecord(
          id: 's1',
          startedAt: now.subtract(const Duration(minutes: 6)),
          endedAt: now.subtract(const Duration(minutes: 2)),
          practiceFocus: 'Travel English',
          userTurns: 4,
          elapsedSeconds: 240,
          language: ConversationLanguage.englishUs,
          feedback: 'Nice flow',
        ),
      );

      final controller = PracticeHubController(
        repository: repository,
        historyService: SessionHistoryService(),
        featureFlags: const AppFeatureFlags(),
      );

      await controller.load();

      expect(controller.isLoadingNotifier.value, isFalse);
      expect(controller.sessionsNotifier.value, hasLength(1));
      expect(controller.dailyChallengeNotifier.value, isNotNull);
      expect(controller.weeklySnapshotNotifier.value, isNotNull);
      expect(
        controller.weeklySnapshotNotifier.value!.mostUsedFocus,
        'Travel English',
      );
      expect(
        controller.weeklySnapshotNotifier.value!.consistencyPercent,
        inInclusiveRange(0, 100),
      );
      expect(
        controller.filteredSessionsNotifier.value,
        hasLength(1),
      );

      controller.dispose();
    });

    test('refreshAfterSession reloads newly persisted session', () async {
      final repository = LocalSessionHistoryRepository();
      final now = DateTime.now();

      await repository.saveSession(
        PracticeSessionRecord(
          id: 'older',
          startedAt: now.subtract(const Duration(minutes: 9)),
          endedAt: now.subtract(const Duration(minutes: 7)),
          practiceFocus: 'General conversation',
          userTurns: 3,
          elapsedSeconds: 120,
          language: ConversationLanguage.englishUs,
          feedback: 'Good start',
        ),
      );

      final controller = PracticeHubController(
        repository: repository,
        historyService: SessionHistoryService(),
        featureFlags: const AppFeatureFlags(),
      );

      await controller.load();
      expect(controller.sessionsNotifier.value.first.id, 'older');

      await repository.saveSession(
        PracticeSessionRecord(
          id: 'newer',
          startedAt: now.subtract(const Duration(minutes: 2)),
          endedAt: now,
          practiceFocus: 'Job interview',
          userTurns: 5,
          elapsedSeconds: 180,
          language: ConversationLanguage.portugueseBr,
          feedback: 'Great confidence',
        ),
      );

      await controller.refreshAfterSession();

      expect(controller.sessionsNotifier.value.first.id, 'newer');
      expect(controller.sessionsNotifier.value, hasLength(2));
      expect(controller.filteredSessionsNotifier.value, hasLength(2));

      controller.setSessionFocusFilter('Job interview');
      expect(controller.filteredSessionsNotifier.value, hasLength(1));
      expect(controller.filteredSessionsNotifier.value.single.id, 'newer');

      controller.setSessionSearchQuery('confidence');
      expect(controller.filteredSessionsNotifier.value, hasLength(1));

      controller.setSessionSearchQuery('not found');
      expect(controller.filteredSessionsNotifier.value, isEmpty);

      controller.setSessionSearchQuery('');
      controller.setSessionFocusFilter(null);
      expect(controller.filteredSessionsNotifier.value, hasLength(2));

      controller.dispose();
    });

    test('daily challenge completion is persisted in history', () async {
      final repository = LocalSessionHistoryRepository();
      final controller = PracticeHubController(
        repository: repository,
        historyService: SessionHistoryService(),
        featureFlags: const AppFeatureFlags(),
      );

      await controller.load();
      final challenge = controller.dailyChallengeNotifier.value;
      expect(challenge, isNotNull);

      if (challenge == null) {
        controller.dispose();
        return;
      }

      await controller.markDailyChallengeCompleted();

      expect(controller.dailyChallengeNotifier.value!.isCompleted, isTrue);
      expect(
        controller.dailyChallengeHistoryNotifier.value.completedDateKeys,
        contains(challenge.dateKey),
      );

      await controller.refreshAfterSession();
      expect(
        controller.dailyChallengeHistoryNotifier.value.completedDateKeys,
        contains(challenge.dateKey),
      );

      controller.dispose();
    });
  });
}
