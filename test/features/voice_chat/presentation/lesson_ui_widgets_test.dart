import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/conversation_language.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/exercise_type.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/reading_listening_exercise.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/widgets/feedback_overlay.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/widgets/hearts_display.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/widgets/lesson_exercise_widgets.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/widgets/progress_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProgressBarWidget shows rounded percent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProgressBarWidget(progress: 0.42)),
      ),
    );

    expect(find.text('42%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('HeartsDisplay renders filled and empty hearts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HeartsDisplay(hearts: 3, maxHearts: 5)),
      ),
    );

    expect(find.byIcon(Icons.favorite), findsNWidgets(3));
    expect(find.byIcon(Icons.favorite_border), findsNWidgets(2));
  });

  testWidgets('FeedbackOverlay shows continue action when callback exists',
      (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedbackOverlay(
            isCorrect: true,
            message: 'Great answer',
            onContinue: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Great answer'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('LessonExerciseRenderer emits option index for multiple choice',
      (tester) async {
    Object? answer;
    final exercise = LessonExercise(
      id: 'e1',
      type: ExerciseType.multipleChoice,
      difficulty: ReadingListeningDifficulty.beginner,
      content: <String, dynamic>{
        'promptEn': 'Choose one',
        'promptPt': 'Escolha uma',
        'optionsEn': <String>['A', 'B', 'C'],
        'optionsPt': <String>['A', 'B', 'C'],
        'correctOptionIndex': 1,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonExerciseRenderer(
            exercise: exercise,
            language: ConversationLanguage.englishUs,
            selectedAnswer: null,
            onAnswerChanged: (value) {
              answer = value;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('B'));
    await tester.pump();

    expect(answer, 1);
  });

  testWidgets('LessonExerciseRenderer emits typed text for translate',
      (tester) async {
    Object? answer;
    final exercise = LessonExercise(
      id: 'e2',
      type: ExerciseType.translate,
      difficulty: ReadingListeningDifficulty.beginner,
      content: <String, dynamic>{
        'promptEn': 'Translate this',
        'promptPt': 'Traduza isso',
        'acceptedAnswers': <String>['hello'],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonExerciseRenderer(
            exercise: exercise,
            language: ConversationLanguage.englishUs,
            selectedAnswer: null,
            onAnswerChanged: (value) {
              answer = value;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'hello world');
    await tester.pump();

    expect(answer, 'hello world');
  });

  testWidgets('LessonExerciseRenderer emits bool for true or false',
      (tester) async {
    Object? answer;
    final exercise = LessonExercise(
      id: 'e3',
      type: ExerciseType.trueOrFalse,
      difficulty: ReadingListeningDifficulty.beginner,
      content: <String, dynamic>{
        'promptEn': 'Earth is flat',
        'promptPt': 'A terra e plana',
        'correctAnswer': false,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonExerciseRenderer(
            exercise: exercise,
            language: ConversationLanguage.englishUs,
            selectedAnswer: null,
            onAnswerChanged: (value) {
              answer = value;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('False'));
    await tester.pump();

    expect(answer, isFalse);
  });

  testWidgets(
      'listen and type hides transcript by default and reveals on show tap',
      (tester) async {
    const exercise = LessonExercise(
      id: 'audio_text_1',
      type: ExerciseType.listenAndType,
      difficulty: ReadingListeningDifficulty.beginner,
      content: <String, dynamic>{
        'promptEn': 'Type what you hear: I am at the station.',
        'promptPt': 'Digite o que voce ouviu: Eu estou na estacao.',
        'audioTextEn': 'I am at the station.',
        'audioTextPt': 'Eu estou na estacao.',
        'acceptedAnswers': <String>['I am at the station'],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonExerciseRenderer(
            exercise: exercise,
            language: ConversationLanguage.englishUs,
            selectedAnswer: null,
            onAnswerChanged: (_) {},
            onPlayAudio: () {},
          ),
        ),
      ),
    );

    expect(
      find.text('Listen to the audio and answer without reading the text.'),
      findsOneWidget,
    );
    expect(find.text('Type what you hear: I am at the station.'), findsNothing);
    expect(find.text('I am at the station.'), findsNothing);
    expect(find.text('Show text'), findsOneWidget);

    await tester.tap(find.text('Show text'));
    await tester.pump();

    expect(find.text('Type what you hear: I am at the station.'), findsNothing);
    expect(find.text('I am at the station.'), findsOneWidget);
    expect(find.text('Hide text'), findsOneWidget);
  });

  testWidgets('advanced listening keeps text hidden without show button',
      (tester) async {
    const exercise = LessonExercise(
      id: 'audio_select_1',
      type: ExerciseType.listenAndSelect,
      difficulty: ReadingListeningDifficulty.advanced,
      content: <String, dynamic>{
        'promptEn': 'The next train leaves at nine fifteen.',
        'promptPt': 'O proximo trem sai as nove e quinze.',
        'optionsEn': <String>['A', 'B', 'C'],
        'optionsPt': <String>['A', 'B', 'C'],
        'correctOptionIndex': 0,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonExerciseRenderer(
            exercise: exercise,
            language: ConversationLanguage.englishUs,
            selectedAnswer: null,
            onAnswerChanged: (_) {},
            onPlayAudio: () {},
          ),
        ),
      ),
    );

    expect(
      find.text('Listen to the audio and answer without reading the text.'),
      findsOneWidget,
    );
    expect(find.text('The next train leaves at nine fifteen.'), findsNothing);
    expect(find.text('Show text'), findsNothing);
    expect(find.text('Advanced level: text hidden to focus on listening.'),
        findsOneWidget);
  });

  testWidgets('LessonExerciseRenderer connects match pairs interactively',
      (tester) async {
    Object? answer;
    const exercise = LessonExercise(
      id: 'e4',
      type: ExerciseType.matchPairs,
      difficulty: ReadingListeningDifficulty.beginner,
      content: <String, dynamic>{
        'promptEn': 'Match pairs',
        'promptPt': 'Conecte os pares',
        'correctPairs': <String, String>{
          'hello': 'ola',
          'bye': 'tchau',
        },
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonExerciseRenderer(
            exercise: exercise,
            language: ConversationLanguage.englishUs,
            selectedAnswer: const <String, String>{},
            onAnswerChanged: (value) {
              answer = value;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('hello'));
    await tester.pump();
    await tester.tap(find.text('ola'));
    await tester.pump();

    expect(answer, isA<Map<String, String>>());
    final map = answer as Map<String, String>;
    expect(map['hello'], 'ola');
  });

  testWidgets('LessonExerciseRenderer shows pronunciation accuracy bar',
      (tester) async {
    final exercise = LessonExercise(
      id: 'e5',
      type: ExerciseType.speakTheSentence,
      difficulty: ReadingListeningDifficulty.beginner,
      content: <String, dynamic>{
        'promptEn': 'Say this sentence',
        'promptPt': 'Fale esta frase',
        'referenceText': 'Nice to meet you',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonExerciseRenderer(
            exercise: exercise,
            language: ConversationLanguage.englishUs,
            selectedAnswer: null,
            pronunciationAccuracyPercent: 87,
            onAnswerChanged: (_) {},
            onStartSpeechCapture: () {},
          ),
        ),
      ),
    );

    expect(find.text('Pronunciation accuracy: 87%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Capture speech'), findsOneWidget);
  });
}
