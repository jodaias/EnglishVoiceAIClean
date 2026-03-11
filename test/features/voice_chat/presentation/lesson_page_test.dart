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
import 'package:english_voice_ai_clean/features/voice_chat/presentation/lesson_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LessonPage renders check action and exercise header',
      (tester) async {
    final controller = _buildController();

    await tester.pumpWidget(
      MaterialApp(
        home: LessonPage(controller: controller),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('CHECK'), findsOneWidget);
    expect(find.textContaining('Exercise 1/1'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);

    controller.dispose();
  });

  testWidgets('LessonPage completes and navigates to summary', (tester) async {
    final controller = _buildController();

    await tester.pumpWidget(
      MaterialApp(
        home: LessonPage(controller: controller),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Yes, I am.'));
    await tester.pump();

    await tester.tap(find.text('CHECK'));
    await tester.pumpAndSettle();

    expect(find.text('CONTINUE'), findsOneWidget);

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('Lesson summary'), findsOneWidget);

    controller.dispose();
  });
}

LessonController _buildController() {
  return LessonController(
    unitId: 'u1',
    lesson: Lesson(
      id: 'l1',
      unitId: 'u1',
      orderIndex: 0,
      exercises: <LessonExercise>[
        LessonExercise(
          id: 'e1',
          type: ExerciseType.multipleChoice,
          difficulty: ReadingListeningDifficulty.beginner,
          content: <String, dynamic>{
            'promptEn': 'How are you?',
            'promptPt': 'Como voce esta?',
            'optionsEn': <String>['Yes, I am.', 'Blue.', 'Tomorrow.'],
            'optionsPt': <String>['Sim, estou.', 'Azul.', 'Amanha.'],
            'correctOptionIndex': 0,
          },
        ),
      ],
    ),
    validator: const ExerciseValidator(),
    xpCalculator: const XpCalculator(),
    heartsManager: HeartsManager(),
    progressRepository: _InMemoryProgressRepository(),
    audioService: _FakeAudioService(),
    pronunciationCaptureService: _FakeCaptureService(),
    initialLanguage: ConversationLanguage.englishUs,
  );
}

class _InMemoryProgressRepository implements LearningProgressRepository {
  UserProgress _value = const UserProgress.initial();

  @override
  Future<UserProgress> getUserProgress() async => _value;

  @override
  Future<void> saveUserProgress(UserProgress progress) async {
    _value = progress;
  }
}

class _FakeAudioService implements LearningAudioService {
  @override
  Future<void> speak(String text, {required String locale}) async {}

  @override
  Future<void> stop() async {}
}

class _FakeCaptureService implements PronunciationCaptureService {
  @override
  Future<String?> captureUserSpeech({required String localeId}) async {
    return 'hello world';
  }
}
