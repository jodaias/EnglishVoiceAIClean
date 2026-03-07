import 'package:english_voice_ai_clean/features/voice_chat/application/learning_audio_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/pronunciation_capture_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/reading_listening_controller.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/session_history_repository.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/conversation_language.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/daily_challenge.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/daily_challenge_history.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/practice_session_record.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/reading_listening_exercise.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingListeningController', () {
    late _FakeLearningAudioService audioService;
    late _FakeSessionHistoryRepository historyRepository;

    setUp(() {
      audioService = _FakeLearningAudioService();
      historyRepository = _FakeSessionHistoryRepository();
    });

    ReadingListeningController buildController() {
      return ReadingListeningController(
        exercises: const <ReadingListeningExercise>[
          ReadingListeningExercise(
            id: 'one',
            titleEn: 'Exercise one',
            titlePt: 'Exercicio um',
            readingTextEn: 'The train leaves at six.',
            readingTextPt: 'O trem sai as seis.',
            questionEn: 'What time is departure?',
            questionPt: 'Que horas e a partida?',
            optionsEn: <String>['At six', 'At eight'],
            optionsPt: <String>['As seis', 'As oito'],
            correctOptionIndex: 0,
            difficulty: ReadingListeningDifficulty.beginner,
          ),
          ReadingListeningExercise(
            id: 'two',
            titleEn: 'Exercise two',
            titlePt: 'Exercicio dois',
            readingTextEn: 'We will meet after lunch.',
            readingTextPt: 'Vamos nos encontrar depois do almoco.',
            questionEn: 'When will we meet?',
            questionPt: 'Quando vamos nos encontrar?',
            optionsEn: <String>['After lunch', 'Before breakfast'],
            optionsPt: <String>['Depois do almoco', 'Antes do cafe da manha'],
            correctOptionIndex: 0,
            difficulty: ReadingListeningDifficulty.intermediate,
          ),
        ],
        audioService: audioService,
        historyRepository: historyRepository,
      );
    }

    test('submits answers, advances, and marks completion', () {
      final controller = buildController();

      expect(controller.isCompletedNotifier.value, isFalse);
      expect(controller.submitAnswer(), isFalse);

      controller.selectOption(0);
      expect(controller.submitAnswer(), isTrue);
      expect(controller.correctAnswersNotifier.value, 1);
      expect(controller.hasSubmittedCurrentAnswer, isTrue);

      expect(controller.moveToNext(), isTrue);
      expect(controller.currentIndexNotifier.value, 1);

      controller.selectOption(1);
      expect(controller.submitAnswer(), isTrue);
      controller.moveToNext();
      expect(controller.isCompletedNotifier.value, isTrue);
      expect(controller.correctAnswersNotifier.value, 1);
      expect(controller.sessionSummaryNotifier.value, isNotNull);

      controller.dispose();
    });

    test('playCurrentAudio uses selected language locale and text', () async {
      final controller = buildController();

      await controller.playCurrentAudio();
      expect(audioService.lastLocale, 'en-US');
      expect(audioService.lastText, 'The train leaves at six.');

      controller.setPracticeLanguage(ConversationLanguage.portugueseBr);
      await controller.playCurrentAudio();
      expect(audioService.lastLocale, 'pt-BR');
      expect(audioService.lastText, 'O trem sai as seis.');

      controller.dispose();
    });

    test('saveSession persists once after completion', () async {
      final controller = buildController();

      controller.selectOption(0);
      controller.submitAnswer();
      controller.moveToNext();
      controller.selectOption(0);
      controller.submitAnswer();
      controller.moveToNext();

      expect(controller.isCompletedNotifier.value, isTrue);

      final firstSave = await controller.saveSession();
      final secondSave = await controller.saveSession();

      expect(firstSave, isTrue);
      expect(secondSave, isFalse);
      expect(historyRepository.saved, hasLength(1));
      expect(historyRepository.saved.single.practiceFocus,
          'Reading and listening');

      controller.dispose();
    });

    test('filters by difficulty and restarts progression', () {
      final controller = buildController();

      expect(controller.totalExercises, 2);

      controller.setDifficultyFilter(ReadingListeningDifficultyFilter.beginner);
      expect(controller.totalExercises, 1);
      expect(controller.currentExercise?.id, 'one');

      controller.selectOption(0);
      expect(controller.submitAnswer(), isTrue);
      controller.moveToNext();
      expect(controller.isCompletedNotifier.value, isTrue);

      controller.setDifficultyFilter(
        ReadingListeningDifficultyFilter.intermediate,
      );

      expect(controller.totalExercises, 1);
      expect(controller.currentExercise?.id, 'two');
      expect(controller.isCompletedNotifier.value, isFalse);
      expect(controller.correctAnswersNotifier.value, 0);

      controller.dispose();
    });

    test('startReadAloud captures speech and returns pronunciation result',
        () async {
      final captureService = _FakePronunciationCaptureService();
      captureService.nextResult = 'the train leaves at six';

      final controller = ReadingListeningController(
        exercises: const <ReadingListeningExercise>[
          ReadingListeningExercise(
            id: 'one',
            titleEn: 'Exercise one',
            titlePt: 'Exercicio um',
            readingTextEn: 'The train leaves at six.',
            readingTextPt: 'O trem sai as seis.',
            questionEn: 'What time?',
            questionPt: 'Que horas?',
            optionsEn: <String>['At six'],
            optionsPt: <String>['As seis'],
            correctOptionIndex: 0,
            difficulty: ReadingListeningDifficulty.beginner,
          ),
        ],
        audioService: audioService,
        historyRepository: historyRepository,
        pronunciationCaptureService: captureService,
      );

      expect(controller.canReadAloud, isTrue);

      await controller.startReadAloud();

      expect(controller.pronunciationResultNotifier.value, isNotNull);
      expect(
          controller.pronunciationResultNotifier.value!.accuracyPercent, 100);
      expect(controller.pronunciationResultNotifier.value!.matchedWords, 5);

      controller.clearPronunciationResult();
      expect(controller.pronunciationResultNotifier.value, isNull);

      controller.dispose();
    });

    test('startReadAloud shows error when no speech detected', () async {
      final captureService = _FakePronunciationCaptureService();
      captureService.nextResult = null;

      final controller = ReadingListeningController(
        exercises: const <ReadingListeningExercise>[
          ReadingListeningExercise(
            id: 'one',
            titleEn: 'Exercise one',
            titlePt: 'Exercicio um',
            readingTextEn: 'The train leaves at six.',
            readingTextPt: 'O trem sai as seis.',
            questionEn: 'What time?',
            questionPt: 'Que horas?',
            optionsEn: <String>['At six'],
            optionsPt: <String>['As seis'],
            correctOptionIndex: 0,
            difficulty: ReadingListeningDifficulty.beginner,
          ),
        ],
        audioService: audioService,
        historyRepository: historyRepository,
        pronunciationCaptureService: captureService,
      );

      await controller.startReadAloud();

      expect(controller.pronunciationResultNotifier.value, isNull);
      expect(controller.errorNotifier.value, isNotNull);

      controller.dispose();
    });
  });
}

class _FakeLearningAudioService implements LearningAudioService {
  String? lastText;
  String? lastLocale;

  @override
  Future<void> speak(String text, {required String locale}) async {
    lastText = text;
    lastLocale = locale;
  }

  @override
  Future<void> stop() async {}
}

class _FakeSessionHistoryRepository implements SessionHistoryRepository {
  final List<PracticeSessionRecord> saved = <PracticeSessionRecord>[];

  @override
  Future<List<PracticeSessionRecord>> getSessions() async {
    return saved;
  }

  @override
  Future<void> saveSession(PracticeSessionRecord session) async {
    saved.add(session);
  }

  @override
  Future<DailyChallenge> getDailyChallenge() async {
    return const DailyChallenge(
      dateKey: '2026-03-07',
      topic: 'Daily routine',
      targetMinutes: 5,
      isCompleted: false,
    );
  }

  @override
  Future<DailyChallengeHistory> getDailyChallengeHistory() async {
    return const DailyChallengeHistory(completedDateKeys: <String>[]);
  }

  @override
  Future<void> markDailyChallengeCompleted({required String dateKey}) async {}
}

class _FakePronunciationCaptureService implements PronunciationCaptureService {
  String? nextResult;

  @override
  Future<String?> captureUserSpeech({required String localeId}) async {
    return nextResult;
  }
}
