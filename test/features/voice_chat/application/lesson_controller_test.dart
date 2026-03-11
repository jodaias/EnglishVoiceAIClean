import 'package:english_voice_ai_clean/features/voice_chat/application/exercise_validator.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/hearts_manager.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/learning_audio_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/learning_progress_repository.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/lesson_controller.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/pronunciation_capture_service.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/xp_calculator.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/conversation_language.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/exercise_type.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/reading_listening_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/user_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Lesson buildLesson() {
    return Lesson(
      id: 'lesson_1',
      unitId: 'unit_1',
      orderIndex: 0,
      exercises: const <LessonExercise>[
        LessonExercise(
          id: 'ex_1',
          type: ExerciseType.multipleChoice,
          difficulty: ReadingListeningDifficulty.beginner,
          content: <String, dynamic>{
            'promptEn': 'Pick the greeting',
            'promptPt': 'Escolha o cumprimento',
            'correctOptionIndex': 1,
          },
        ),
        LessonExercise(
          id: 'ex_2',
          type: ExerciseType.listenAndType,
          difficulty: ReadingListeningDifficulty.beginner,
          content: <String, dynamic>{
            'promptEn': 'Type: hello friend',
            'promptPt': 'Digite: ola amigo',
            'audioTextEn': 'hello friend',
            'audioTextPt': 'ola amigo',
            'acceptedAnswers': <String>['hello friend'],
          },
        ),
      ],
    );
  }

  test('completes lesson with correct progression and persists summary',
      () async {
    final audio = _FakeAudioService();
    final repo = _InMemoryProgressRepository();
    final controller = LessonController(
      unitId: 'unit_1',
      lesson: buildLesson(),
      validator: const ExerciseValidator(),
      xpCalculator: const XpCalculator(),
      heartsManager: HeartsManager(maxHearts: 5),
      progressRepository: repo,
      audioService: audio,
    );

    controller.selectAnswer(1);
    expect(controller.submitCurrentAnswer(), isTrue);
    expect(controller.feedbackNotifier.value?.isCorrect, isTrue);
    expect(controller.earnedXpNotifier.value, 15);
    expect(await controller.continueAfterFeedback(), isTrue);

    controller.selectAnswer('hello friend');
    expect(controller.submitCurrentAnswer(), isTrue);
    expect(await controller.continueAfterFeedback(), isFalse);

    expect(controller.isCompletedNotifier.value, isTrue);
    expect(controller.summaryNotifier.value, isNotNull);
    expect(controller.summaryNotifier.value?.correctAnswers, 2);
    expect(controller.summaryNotifier.value?.scorePercent, 100);
    expect(controller.summaryNotifier.value?.isPassed, isTrue);
    expect(controller.summaryNotifier.value?.earnedXp, 50);
    expect(repo.lastSaved, isNotNull);
    expect(repo.lastSaved?.totalXp, 50);

    controller.dispose();
  });

  test('wrong answer consumes hearts and can end lesson when hearts run out',
      () async {
    final controller = LessonController(
      unitId: 'unit_1',
      lesson: Lesson(
        id: 'lesson_2',
        unitId: 'unit_1',
        orderIndex: 0,
        exercises: const <LessonExercise>[
          LessonExercise(
            id: 'only_ex',
            type: ExerciseType.trueOrFalse,
            difficulty: ReadingListeningDifficulty.beginner,
            content: <String, dynamic>{
              'promptEn': 'True or false test',
              'promptPt': 'Teste verdadeiro ou falso',
              'correctAnswer': true,
            },
          ),
        ],
      ),
      validator: const ExerciseValidator(),
      xpCalculator: const XpCalculator(),
      heartsManager: HeartsManager(maxHearts: 1),
      progressRepository: _InMemoryProgressRepository(),
      audioService: _FakeAudioService(),
    );

    controller.selectAnswer(false);
    expect(controller.submitCurrentAnswer(), isTrue);
    expect(controller.feedbackNotifier.value?.isCorrect, isFalse);
    expect(controller.heartsNotifier.value, 0);
    expect(await controller.continueAfterFeedback(), isFalse);
    expect(controller.isCompletedNotifier.value, isTrue);
    expect(controller.summaryNotifier.value?.isPassed, isFalse);

    controller.dispose();
  });

  test('plays prompt audio in english even when UI language is portuguese',
      () async {
    final audio = _FakeAudioService();
    final controller = LessonController(
      unitId: 'unit_1',
      lesson: buildLesson(),
      validator: const ExerciseValidator(),
      xpCalculator: const XpCalculator(),
      heartsManager: HeartsManager(maxHearts: 5),
      progressRepository: _InMemoryProgressRepository(),
      audioService: audio,
      initialLanguage: ConversationLanguage.portugueseBr,
    );

    await controller.playCurrentPromptAudio();

    expect(audio.lastLocale, 'en-US');
    expect(audio.lastText, 'Pick the greeting');
    controller.dispose();
  });

  test('plays only transcript for listen and type prompts', () async {
    final audio = _FakeAudioService();
    final controller = LessonController(
      unitId: 'unit_1',
      lesson: buildLesson(),
      validator: const ExerciseValidator(),
      xpCalculator: const XpCalculator(),
      heartsManager: HeartsManager(maxHearts: 5),
      progressRepository: _InMemoryProgressRepository(),
      audioService: audio,
      initialLanguage: ConversationLanguage.englishUs,
    );

    controller.selectAnswer(1);
    expect(controller.submitCurrentAnswer(), isTrue);
    expect(await controller.continueAfterFeedback(), isTrue);

    await controller.playCurrentPromptAudio();

    expect(audio.lastText, 'hello friend');
    expect(audio.lastLocale, 'en-US');
    controller.dispose();
  });

  test('captures spoken answer through pronunciation service', () async {
    final capture = _FakePronunciationCaptureService()
      ..nextCapture = 'hello friend';

    final controller = LessonController(
      unitId: 'unit_1',
      lesson: Lesson(
        id: 'lesson_3',
        unitId: 'unit_1',
        orderIndex: 0,
        exercises: const <LessonExercise>[
          LessonExercise(
            id: 'speak_ex',
            type: ExerciseType.speakTheSentence,
            difficulty: ReadingListeningDifficulty.beginner,
            content: <String, dynamic>{
              'promptEn': 'Say hello friend',
              'promptPt': 'Fale ola amigo',
              'referenceText': 'hello friend',
              'minAccuracy': 85,
            },
          ),
        ],
      ),
      validator: const ExerciseValidator(),
      xpCalculator: const XpCalculator(),
      heartsManager: HeartsManager(maxHearts: 5),
      progressRepository: _InMemoryProgressRepository(),
      audioService: _FakeAudioService(),
      pronunciationCaptureService: capture,
    );

    final spoken = await controller.captureSpokenAnswer(
      pronunciationAccuracyPercent: 92,
    );

    expect(spoken, 'hello friend');
    expect(controller.selectedAnswerNotifier.value, 'hello friend');
    expect(controller.submitCurrentAnswer(), isTrue);
    expect(controller.feedbackNotifier.value?.isCorrect, isTrue);

    controller.dispose();
  });
}

class _FakeAudioService implements LearningAudioService {
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

class _FakePronunciationCaptureService implements PronunciationCaptureService {
  String? nextCapture;

  @override
  Future<String?> captureUserSpeech({required String localeId}) async {
    return nextCapture;
  }
}

class _InMemoryProgressRepository implements LearningProgressRepository {
  UserProgress value = const UserProgress.initial();
  UserProgress? lastSaved;

  @override
  Future<UserProgress> getUserProgress() async {
    return value;
  }

  @override
  Future<void> saveUserProgress(UserProgress progress) async {
    value = progress;
    lastSaved = progress;
  }
}
