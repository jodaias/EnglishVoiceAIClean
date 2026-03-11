import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/entities/conversation_language.dart';
import '../domain/entities/lesson.dart';
import '../domain/entities/lesson_progress.dart';
import '../domain/entities/lesson_exercise.dart';
import '../domain/entities/unit_progress.dart';
import 'exercise_validator.dart';
import 'hearts_manager.dart';
import 'learning_audio_service.dart';
import 'learning_progress_repository.dart';
import 'pronunciation_capture_service.dart';
import 'spaced_repetition_service.dart';
import 'xp_calculator.dart';

class LessonAnswerFeedback {
  final bool isCorrect;
  final String normalizedUserAnswer;

  const LessonAnswerFeedback({
    required this.isCorrect,
    required this.normalizedUserAnswer,
  });
}

class LessonSessionSummary {
  final int totalExercises;
  final int correctAnswers;
  final int scorePercent;
  final int earnedXp;
  final int remainingHearts;
  final bool isPassed;

  const LessonSessionSummary({
    required this.totalExercises,
    required this.correctAnswers,
    required this.scorePercent,
    required this.earnedXp,
    required this.remainingHearts,
    required this.isPassed,
  });
}

class LessonController {
  final String unitId;
  final Lesson lesson;
  final ExerciseValidator validator;
  final XpCalculator xpCalculator;
  final HeartsManager heartsManager;
  final LearningProgressRepository progressRepository;
  final LearningAudioService audioService;
  final PronunciationCaptureService? pronunciationCaptureService;
  final SpacedRepetitionService? spacedRepetitionService;

  final ValueNotifier<ConversationLanguage> languageNotifier;
  final ValueNotifier<int> currentExerciseIndexNotifier = ValueNotifier<int>(0);
  final ValueNotifier<LessonExercise?> currentExerciseNotifier =
      ValueNotifier<LessonExercise?>(null);
  final ValueNotifier<Object?> selectedAnswerNotifier =
      ValueNotifier<Object?>(null);
  final ValueNotifier<LessonAnswerFeedback?> feedbackNotifier =
      ValueNotifier<LessonAnswerFeedback?>(null);
  final ValueNotifier<int> heartsNotifier = ValueNotifier<int>(5);
  final ValueNotifier<int> earnedXpNotifier = ValueNotifier<int>(0);
  final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0);
  final ValueNotifier<bool> isCompletedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isCapturingSpeechNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<LessonSessionSummary?> summaryNotifier =
      ValueNotifier<LessonSessionSummary?>(null);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  final Map<String, int> _attemptsByExerciseId = <String, int>{};
  final Map<String, bool> _exerciseResultsById = <String, bool>{};
  int _correctAnswers = 0;
  int _lastPronunciationAccuracyPercent = 0;
  bool _sessionPersisted = false;

  LessonController({
    required this.unitId,
    required this.lesson,
    required this.validator,
    required this.xpCalculator,
    required this.heartsManager,
    required this.progressRepository,
    required this.audioService,
    this.pronunciationCaptureService,
    this.spacedRepetitionService,
    ConversationLanguage initialLanguage = ConversationLanguage.englishUs,
  }) : languageNotifier = ValueNotifier<ConversationLanguage>(initialLanguage) {
    heartsNotifier.value = heartsManager.state.currentHearts;
    _syncCurrentExercise();
  }

  int get totalExercises => lesson.exercises.length;

  int get correctAnswers => _correctAnswers;

  bool get hasSubmittedCurrentAnswer => feedbackNotifier.value != null;

  bool get canCaptureSpeech => pronunciationCaptureService != null;

  bool get canContinue => heartsManager.canContinue;

  void setLanguage(ConversationLanguage language) {
    if (language == ConversationLanguage.auto) {
      return;
    }
    languageNotifier.value = language;
  }

  void selectAnswer(Object answer) {
    if (isCompletedNotifier.value || hasSubmittedCurrentAnswer) {
      return;
    }
    selectedAnswerNotifier.value = answer;
    errorNotifier.value = null;
  }

  void setPronunciationAnswer({
    required String spokenText,
    required int pronunciationAccuracyPercent,
  }) {
    if (isCompletedNotifier.value || hasSubmittedCurrentAnswer) {
      return;
    }
    _lastPronunciationAccuracyPercent = pronunciationAccuracyPercent;
    selectedAnswerNotifier.value = spokenText;
  }

  bool submitCurrentAnswer() {
    if (isCompletedNotifier.value || hasSubmittedCurrentAnswer) {
      return false;
    }

    final exercise = currentExerciseNotifier.value;
    final selected = selectedAnswerNotifier.value;
    if (exercise == null || selected == null) {
      return false;
    }

    final attempts = (_attemptsByExerciseId[exercise.id] ?? 0) + 1;
    _attemptsByExerciseId[exercise.id] = attempts;
    final isFirstTry = attempts == 1;

    final validation = validator.validate(
      exercise: exercise,
      userAnswer: selected,
      pronunciationAccuracyPercent: _lastPronunciationAccuracyPercent,
    );

    if (validation.isCorrect) {
      _correctAnswers += 1;
      earnedXpNotifier.value += xpCalculator.calculateExerciseXp(
        isCorrect: true,
        firstTry: isFirstTry,
        pronunciationAccuracyPercent: _lastPronunciationAccuracyPercent,
      );
    } else {
      heartsManager.consumeHeart(DateTime.now());
      heartsNotifier.value = heartsManager.state.currentHearts;
    }

    _exerciseResultsById[exercise.id] = validation.isCorrect;

    feedbackNotifier.value = LessonAnswerFeedback(
      isCorrect: validation.isCorrect,
      normalizedUserAnswer: validation.normalizedUserAnswer,
    );

    _updateProgress();
    return true;
  }

  Future<bool> continueAfterFeedback() async {
    if (feedbackNotifier.value == null || isCompletedNotifier.value) {
      return false;
    }

    final isLastExercise =
        currentExerciseIndexNotifier.value >= totalExercises - 1;
    final outOfHearts = !heartsManager.canContinue;
    if (isLastExercise || outOfHearts) {
      await _completeLesson();
      return false;
    }

    currentExerciseIndexNotifier.value += 1;
    _lastPronunciationAccuracyPercent = 0;
    selectedAnswerNotifier.value = null;
    feedbackNotifier.value = null;
    _syncCurrentExercise();
    _updateProgress();
    return true;
  }

  Future<void> playCurrentPromptAudio() async {
    final exercise = currentExerciseNotifier.value;
    if (exercise == null || isSpeakingNotifier.value) {
      return;
    }

    final prompt = _promptForLanguage(exercise);
    if (prompt.isEmpty) {
      return;
    }

    errorNotifier.value = null;
    isSpeakingNotifier.value = true;
    try {
      await audioService.speak(
        prompt,
        locale: languageNotifier.value.ttsLocale,
      );
    } catch (_) {
      errorNotifier.value = 'Nao foi possivel reproduzir o audio agora.';
    } finally {
      isSpeakingNotifier.value = false;
    }
  }

  Future<void> stopAudio() async {
    isSpeakingNotifier.value = false;
    await audioService.stop();
  }

  Future<String?> captureSpokenAnswer({
    int pronunciationAccuracyPercent = 0,
  }) async {
    final service = pronunciationCaptureService;
    if (service == null || isCapturingSpeechNotifier.value) {
      return null;
    }

    isCapturingSpeechNotifier.value = true;
    errorNotifier.value = null;

    try {
      final spoken = await service.captureUserSpeech(
        localeId: languageNotifier.value.speechLocale,
      );

      final normalized = (spoken ?? '').trim();
      if (normalized.isEmpty) {
        errorNotifier.value = 'Nenhuma fala detectada. Tente novamente.';
        return null;
      }

      setPronunciationAnswer(
        spokenText: normalized,
        pronunciationAccuracyPercent: pronunciationAccuracyPercent,
      );
      return normalized;
    } catch (_) {
      errorNotifier.value = 'Nao foi possivel capturar a fala agora.';
      return null;
    } finally {
      isCapturingSpeechNotifier.value = false;
    }
  }

  void dispose() {
    unawaited(audioService.stop());
    languageNotifier.dispose();
    currentExerciseIndexNotifier.dispose();
    currentExerciseNotifier.dispose();
    selectedAnswerNotifier.dispose();
    feedbackNotifier.dispose();
    heartsNotifier.dispose();
    earnedXpNotifier.dispose();
    progressNotifier.dispose();
    isCompletedNotifier.dispose();
    isSpeakingNotifier.dispose();
    isCapturingSpeechNotifier.dispose();
    summaryNotifier.dispose();
    errorNotifier.dispose();
  }

  Future<void> _completeLesson() async {
    if (isCompletedNotifier.value) {
      return;
    }

    final perfectBonus = xpCalculator.calculateLessonBonus(
      totalExercises: totalExercises,
      correctExercises: _correctAnswers,
    );
    if (perfectBonus > 0) {
      earnedXpNotifier.value += perfectBonus;
    }

    final scorePercent = totalExercises == 0
        ? 0
        : ((_correctAnswers / totalExercises) * 100).round();
    final isPassed = scorePercent >= 60;

    summaryNotifier.value = LessonSessionSummary(
      totalExercises: totalExercises,
      correctAnswers: _correctAnswers,
      scorePercent: scorePercent,
      earnedXp: earnedXpNotifier.value,
      remainingHearts: heartsNotifier.value,
      isPassed: isPassed,
    );

    progressNotifier.value = 1;
    isCompletedNotifier.value = true;
    await _persistLessonProgress(
        scorePercent: scorePercent, isPassed: isPassed);
  }

  Future<void> _persistLessonProgress({
    required int scorePercent,
    required bool isPassed,
  }) async {
    if (_sessionPersisted) {
      return;
    }

    try {
      final previous = await progressRepository.getUserProgress();
      final previousUnit = previous.units[unitId] ??
          UnitProgress.empty(unitId, isUnlocked: true);
      final previousLesson =
          previousUnit.lessons[lesson.id] ?? LessonProgress.empty(lesson.id);

      final updatedLesson = previousLesson.copyWith(
        isCompleted: previousLesson.isCompleted || isPassed,
        bestScore: scorePercent > previousLesson.bestScore
            ? scorePercent
            : previousLesson.bestScore,
        xpEarned: previousLesson.xpEarned + earnedXpNotifier.value,
        completedAt: isPassed ? DateTime.now() : previousLesson.completedAt,
        attempts: previousLesson.attempts + 1,
      );

      final updatedLessons =
          Map<String, LessonProgress>.from(previousUnit.lessons)
            ..[lesson.id] = updatedLesson;

      final updatedUnit = previousUnit.copyWith(
        lessons: updatedLessons,
        crowns: isPassed && previousUnit.crowns < 5
            ? previousUnit.crowns + 1
            : previousUnit.crowns,
      );

      final updatedUnits = Map<String, UnitProgress>.from(previous.units)
        ..[unitId] = updatedUnit;

      final state = heartsManager.state;
      final updatedUser = previous.copyWith(
        units: updatedUnits,
        totalXp: previous.totalXp + earnedXpNotifier.value,
        availableHearts: state.currentHearts,
        heartsRefillAt: state.refillAt,
      );

      await progressRepository.saveUserProgress(updatedUser);
      _sessionPersisted = true;

      final reviewService = spacedRepetitionService;
      if (reviewService != null && _exerciseResultsById.isNotEmpty) {
        await reviewService.registerLessonResults(
          exerciseResults: _exerciseResultsById,
          now: DateTime.now(),
        );
      }
    } catch (_) {
      errorNotifier.value = 'Nao foi possivel salvar o progresso da licao.';
    }
  }

  void _syncCurrentExercise() {
    if (lesson.exercises.isEmpty) {
      currentExerciseNotifier.value = null;
      return;
    }

    final safeIndex = currentExerciseIndexNotifier.value.clamp(
      0,
      lesson.exercises.length - 1,
    );
    currentExerciseNotifier.value = lesson.exercises[safeIndex];
  }

  void _updateProgress() {
    if (totalExercises <= 0) {
      progressNotifier.value = 0;
      return;
    }

    final index = currentExerciseIndexNotifier.value;
    final answeredCurrent = feedbackNotifier.value != null ? 1 : 0;
    final completed = (index + answeredCurrent).clamp(0, totalExercises);
    progressNotifier.value = completed / totalExercises;
  }

  String _promptForLanguage(LessonExercise exercise) {
    final isPt = languageNotifier.value == ConversationLanguage.portugueseBr;
    final key = isPt ? 'promptPt' : 'promptEn';
    return (exercise.content[key] ?? '').toString();
  }
}
