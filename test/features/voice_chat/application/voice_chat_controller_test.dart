import 'dart:async';
import 'dart:collection';

import 'package:english_voice_ai_clean/features/voice_chat/application/voice_chat_controller.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/session_history_repository.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/conversation_language.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/daily_challenge.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/daily_challenge_history.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/practice_session_record.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/ai/ai_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/speech/speech_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/tts/tts_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceChatController', () {
    test('uses pt_BR fallback when auto mode gets empty en_US recognition',
        () async {
      final ai =
          FakeAIService(responseText: 'Resposta em portugues. Tudo bem?');
      final speech = FakeSpeechService(
        responses: <String?>['', 'ola, tudo bem?', null],
      );
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      await controller.startConversation();
      await _waitFor(() => ai.responseCalls.isNotEmpty);

      expect(speech.requestedLocales.length, greaterThanOrEqualTo(2));
      expect(speech.requestedLocales[0],
          ConversationLanguage.englishUs.speechLocale);
      expect(speech.requestedLocales[1],
          ConversationLanguage.portugueseBr.speechLocale);
      expect(
          ai.responseCalls.single.language, ConversationLanguage.portugueseBr);

      controller.dispose();
    });

    test('pauses automatically after configured silent turns', () async {
      final ai = FakeAIService(
          responseText: 'Hello! What would you like to practice?');
      final speech = FakeSpeechService(responses: <String?>[null, null, null]);
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 1,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      await controller.startConversation();
      await _waitFor(() => controller.isPausedNotifier.value == true);

      expect(controller.isPausedNotifier.value, isTrue);
      expect(
        controller.statusNotifier.value,
        contains('Conversation paused'),
      );

      controller.dispose();
    });

    test('handles "slow down" command without calling AI', () async {
      final ai = FakeAIService(responseText: 'This should not be used.');
      final speech = FakeSpeechService(responses: <String?>['slow down', null]);
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      await controller.startConversation();
      await _waitFor(() => tts.speakCalls.length >= 2);

      expect(ai.responseCalls, isEmpty);
      expect(tts.rates, contains(0.35));
      expect(
        controller.conversation.value.any(
          (msg) => (msg['content'] ?? '').contains('speak slower'),
        ),
        isTrue,
      );

      controller.dispose();
    });

    test('handles "speed up" command and keeps adjusted rate on next turn',
        () async {
      final ai = FakeAIService(responseText: 'Great, keep going.');
      final speech = FakeSpeechService(
        responses: <String?>['speed up', 'hello again', null],
      );
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      await controller.startConversation();
      await _waitFor(() => ai.responseCalls.isNotEmpty);

      expect(tts.rates, isNotEmpty);
      expect(tts.rates.first, 1.0);
      expect(tts.rates.where((value) => value == 0.7), isEmpty);
      expect(
        controller.conversation.value.any(
          (msg) => (msg['content'] ?? '').contains('speak faster'),
        ),
        isTrue,
      );

      controller.dispose();
    });

    test('handles "normal speed" command after slowing down', () async {
      final ai = FakeAIService(responseText: 'Unused');
      final speech = FakeSpeechService(
        responses: <String?>['slow down', 'normal speed', null],
      );
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      await controller.startConversation();
      await _waitFor(() => tts.rates.length >= 2);

      expect(tts.rates[0], 0.35);
      expect(tts.rates[1], 0.7);
      expect(
        controller.conversation.value.any(
          (msg) => (msg['content'] ?? '').contains('reset to normal'),
        ),
        isTrue,
      );

      controller.dispose();
    });

    test('handles "aumentar velocidade" command in Portuguese', () async {
      final ai = FakeAIService(responseText: 'Unused');
      final speech = FakeSpeechService(
        responses: <String?>['aumentar velocidade', null],
      );
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      controller.setPreferredLanguage(ConversationLanguage.portugueseBr);
      await controller.startConversation();
      await _waitFor(() => tts.rates.isNotEmpty);

      expect(tts.rates.first, 1.0);
      expect(
        controller.conversation.value.any(
          (msg) => (msg['content'] ?? '').contains('falar mais rapido'),
        ),
        isTrue,
      );

      controller.dispose();
    });

    test('handles "diminuir velocidade" command in Portuguese', () async {
      final ai = FakeAIService(responseText: 'Unused');
      final speech = FakeSpeechService(
        responses: <String?>['diminuir velocidade', null],
      );
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      controller.setPreferredLanguage(ConversationLanguage.portugueseBr);
      await controller.startConversation();
      await _waitFor(() => tts.rates.isNotEmpty);

      expect(tts.rates.first, 0.35);
      expect(
        controller.conversation.value.any(
          (msg) => (msg['content'] ?? '').contains('falar mais devagar'),
        ),
        isTrue,
      );

      controller.dispose();
    });

    test('handles explicit "2x" speech speed command', () async {
      final ai = FakeAIService(responseText: 'Unused');
      final speech = FakeSpeechService(
        responses: <String?>['2x', null],
      );
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      await controller.startConversation();
      await _waitFor(() => tts.rates.isNotEmpty);

      expect(tts.rates.first, 1.0);
      expect(
        controller.conversation.value.any(
          (msg) => (msg['content'] ?? '').contains('2.0x'),
        ),
        isTrue,
      );

      controller.dispose();
    });

    test('handles explicit "0.5x" speech speed command', () async {
      final ai = FakeAIService(responseText: 'Unused');
      final speech = FakeSpeechService(
        responses: <String?>['0.5x', null],
      );
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      await controller.startConversation();
      await _waitFor(() => tts.rates.isNotEmpty);

      expect(tts.rates.first, 0.35);
      expect(
        controller.conversation.value.any(
          (msg) => (msg['content'] ?? '').contains('0.5x'),
        ),
        isTrue,
      );

      controller.dispose();
    });

    test('does not auto-pause immediately after resume', () async {
      final ai = FakeAIService(responseText: 'Hello there.');
      final speech = FakeSpeechService(
        responses: <String?>[null, null, null, null, null, null],
      );
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 1,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
        resumeGracePeriod: const Duration(milliseconds: 150),
      );

      await controller.startConversation();
      await _waitFor(() => controller.isPausedNotifier.value == true);

      controller.resumeConversation();
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(controller.isPausedNotifier.value, isFalse);

      controller.dispose();
    });

    test('handles repeat command without AI call', () async {
      final ai = FakeAIService(responseText: 'Unused');
      final speech = FakeSpeechService(responses: <String?>['repeat', null]);
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      await controller.startConversation();
      await _waitFor(() => tts.speakCalls.length >= 2);

      expect(ai.responseCalls, isEmpty);
      expect(tts.speakCalls[1].text, contains('Hello!'));

      controller.dispose();
    });

    test('handles pause command and pauses conversation', () async {
      final ai = FakeAIService(responseText: 'Unused');
      final speech = FakeSpeechService(responses: <String?>['pause', null]);
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      await controller.startConversation();
      await _waitFor(() => controller.isPausedNotifier.value == true);

      expect(controller.isPausedNotifier.value, isTrue);
      expect(controller.statusNotifier.value, contains('paused'));

      controller.dispose();
    });

    test('persists session after feedback generation', () async {
      final ai = FakeAIService(
        responseText: 'Hello there.',
        feedbackText: 'Summary:\nEstimated Level: Beginner',
      );
      final speech = FakeSpeechService(responses: <String?>[null]);
      final tts = FakeTTSService();
      final repo = FakeSessionHistoryRepository();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        sessionHistoryRepository: repo,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      await controller.startConversation();
      await controller.endSessionWithFeedback();

      expect(repo.savedSessions.length, 1);
      expect(repo.savedSessions.single.feedback, contains('Estimated Level'));

      controller.dispose();
    });

    test('normalizes feedback to structured pedagogical report format',
        () async {
      final ai = FakeAIService(
        responseText: 'Hello there.',
        feedbackText: 'Nice effort today.',
      );
      final speech = FakeSpeechService(responses: <String?>[null]);
      final tts = FakeTTSService();
      final repo = FakeSessionHistoryRepository();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        sessionHistoryRepository: repo,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      await controller.startConversation();
      await controller.endSessionWithFeedback();

      final feedback = controller.sessionFeedbackNotifier.value ?? '';
      expect(feedback, contains('Summary:'));
      expect(feedback, contains('Estimated Level:'));
      expect(feedback, contains('Try These 3 Sentences:'));
      expect(feedback, contains('Next Challenge:'));

      controller.dispose();
    });

    test('uses fallback feedback when AI feedback generation fails', () async {
      final ai = FakeAIService(
        responseText: 'Hello there.',
        throwOnFeedback: true,
      );
      final speech = FakeSpeechService(responses: <String?>[null]);
      final tts = FakeTTSService();
      final repo = FakeSessionHistoryRepository();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        sessionHistoryRepository: repo,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      await controller.startConversation();
      await controller.endSessionWithFeedback();

      final feedback = controller.sessionFeedbackNotifier.value ?? '';
      expect(feedback, contains('Estimated Level:'));
      expect(feedback, contains('Try These 3 Sentences:'));
      expect(repo.savedSessions, hasLength(1));

      controller.dispose();
    });

    test('uses actionable AI fallback when network error happens', () async {
      final ai = FakeAIService(
        responseText: 'Unused',
        responseError: const AIServiceException(
          code: AIServiceErrorCode.network,
          message: 'network down',
        ),
      );
      final speech = FakeSpeechService(
        responses: <String?>['hello there', null],
      );
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      await controller.startConversation();
      await _waitFor(() => tts.speakCalls.length >= 2);

      expect(tts.speakCalls[1].text, contains('internet'));

      controller.dispose();
    });

    test('keeps response language aligned to user-selected Portuguese mode',
        () async {
      final ai = FakeAIService(responseText: 'Resposta alinhada.');
      final speech = FakeSpeechService(
        responses: <String?>['hello, can we continue?', null],
      );
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      controller.setPreferredLanguage(ConversationLanguage.portugueseBr);
      await controller.startConversation();
      await _waitFor(() => ai.responseCalls.isNotEmpty);

      expect(
        ai.responseCalls.single.language,
        ConversationLanguage.portugueseBr,
      );

      controller.dispose();
    });

    test('keeps response language aligned to user-selected English mode',
        () async {
      final ai = FakeAIService(responseText: 'Aligned answer.');
      final speech = FakeSpeechService(
        responses: <String?>['ola, tudo bem?', null],
      );
      final tts = FakeTTSService();

      final controller = VoiceChatController(
        aiService: ai,
        speechService: speech,
        ttsService: tts,
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      controller.setPreferredLanguage(ConversationLanguage.englishUs);
      await controller.startConversation();
      await _waitFor(() => ai.responseCalls.isNotEmpty);

      expect(ai.responseCalls.single.language, ConversationLanguage.englishUs);

      controller.dispose();
    });

    test(
        'uses Portuguese inactivity pause message when Portuguese mode selected',
        () async {
      final controller = VoiceChatController(
        aiService: FakeAIService(responseText: 'ok'),
        speechService: FakeSpeechService(responses: <String?>[null]),
        ttsService: FakeTTSService(),
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      controller.setPreferredLanguage(ConversationLanguage.portugueseBr);
      await controller.startConversation();
      controller.pauseConversation(fromInactivity: true);

      expect(controller.statusNotifier.value, contains('Sem resposta'));

      controller.dispose();
    });

    test('uses English inactivity pause message when auto mode selected',
        () async {
      final controller = VoiceChatController(
        aiService: FakeAIService(responseText: 'ok'),
        speechService: FakeSpeechService(responses: <String?>[null]),
        ttsService: FakeTTSService(),
        maxSilentTurnsBeforePause: 10,
        loopDelay: const Duration(milliseconds: 10),
        pausedPollDelay: const Duration(milliseconds: 10),
      );

      controller.setPreferredLanguage(ConversationLanguage.auto);
      await controller.startConversation();
      controller.pauseConversation(fromInactivity: true);

      expect(controller.statusNotifier.value, contains('No response'));

      controller.dispose();
    });
  });
}

Future<void> _waitFor(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
  Duration step = const Duration(milliseconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (predicate()) {
      return;
    }
    await Future<void>.delayed(step);
  }
  throw TimeoutException('Condition not satisfied within $timeout.');
}

class FakeAIService implements AIService {
  final String responseText;
  final String feedbackText;
  final bool throwOnFeedback;
  final Object? responseError;
  final List<AIResponseCall> responseCalls = <AIResponseCall>[];

  FakeAIService({
    required this.responseText,
    this.feedbackText = 'Session feedback',
    this.throwOnFeedback = false,
    this.responseError,
  });

  @override
  Future<String> getResponse({
    required List<Map<String, String>> conversation,
    required ConversationLanguage language,
    String? practiceFocus,
    int? sessionTurns,
  }) async {
    responseCalls.add(
      AIResponseCall(
        conversation: conversation,
        language: language,
        practiceFocus: practiceFocus,
        sessionTurns: sessionTurns,
      ),
    );

    if (responseError != null) {
      throw responseError!;
    }

    return responseText;
  }

  @override
  Future<String> getSessionFeedback({
    required List<Map<String, String>> conversation,
    required ConversationLanguage language,
    required String practiceFocus,
    required int sessionTurns,
    required int elapsedSeconds,
  }) async {
    if (throwOnFeedback) {
      throw Exception('feedback failure');
    }
    return feedbackText;
  }
}

class AIResponseCall {
  final List<Map<String, String>> conversation;
  final ConversationLanguage language;
  final String? practiceFocus;
  final int? sessionTurns;

  AIResponseCall({
    required this.conversation,
    required this.language,
    required this.practiceFocus,
    required this.sessionTurns,
  });
}

class FakeSpeechService implements SpeechService {
  final Queue<String?> _responses;
  final List<String> requestedLocales = <String>[];

  FakeSpeechService({required List<String?> responses})
      : _responses = Queue<String?>.from(responses);

  @override
  Duration get listenFor => const Duration(seconds: 1);

  @override
  Duration get pauseFor => const Duration(milliseconds: 500);

  @override
  Duration get retryDelay => Duration.zero;

  @override
  int get sttStartFailureCount => 0;

  @override
  Future<String?> listen({
    required bool isSpeaking,
    required String localeId,
  }) async {
    requestedLocales.add(localeId);
    if (_responses.isEmpty) {
      return null;
    }
    return _responses.removeFirst();
  }
}

class FakeTTSService implements TTSService {
  final List<double> rates = <double>[];
  final List<SpeakCall> speakCalls = <SpeakCall>[];

  @override
  Future<void> setRate(double rate) async {
    rates.add(rate);
  }

  @override
  Future<void> speak(String text, {required String locale}) async {
    speakCalls.add(SpeakCall(text: text, locale: locale));
  }

  @override
  Future<void> stop() async {}
}

class SpeakCall {
  final String text;
  final String locale;

  SpeakCall({required this.text, required this.locale});
}

class FakeSessionHistoryRepository implements SessionHistoryRepository {
  final List<PracticeSessionRecord> savedSessions = <PracticeSessionRecord>[];

  @override
  Future<List<PracticeSessionRecord>> getSessions() async {
    return List<PracticeSessionRecord>.from(savedSessions);
  }

  @override
  Future<DailyChallenge> getDailyChallenge() async {
    return const DailyChallenge(
      dateKey: '2026-03-07',
      topic: 'Daily routine',
      targetMinutes: 6,
      isCompleted: false,
    );
  }

  @override
  Future<DailyChallengeHistory> getDailyChallengeHistory() async {
    return const DailyChallengeHistory(completedDateKeys: <String>[]);
  }

  @override
  Future<void> markDailyChallengeCompleted({required String dateKey}) async {}

  @override
  Future<void> saveSession(PracticeSessionRecord session) async {
    savedSessions.add(session);
  }
}
