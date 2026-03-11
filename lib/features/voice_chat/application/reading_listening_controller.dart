import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/entities/conversation_language.dart';
import '../domain/entities/practice_session_record.dart';
import '../domain/entities/pronunciation_result.dart';
import '../domain/entities/reading_listening_exercise.dart';
import 'learning_audio_service.dart';
import 'pronunciation_capture_service.dart';
import 'pronunciation_comparer.dart';
import 'session_history_repository.dart';

class ReadingListeningController {
  final List<ReadingListeningExercise> exercises;
  final LearningAudioService audioService;
  final SessionHistoryRepository historyRepository;
  final PronunciationCaptureService? pronunciationCaptureService;

  final ValueNotifier<ConversationLanguage> practiceLanguageNotifier =
      ValueNotifier<ConversationLanguage>(ConversationLanguage.englishUs);
  final ValueNotifier<ReadingListeningDifficultyFilter>
      difficultyFilterNotifier =
      ValueNotifier<ReadingListeningDifficultyFilter>(
    ReadingListeningDifficultyFilter.all,
  );
  final ValueNotifier<int> currentIndexNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int?> selectedOptionNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<List<int?>> submittedAnswersNotifier =
      ValueNotifier<List<int?>>(<int?>[]);
  final ValueNotifier<int> correctAnswersNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isCompletedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSavingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> sessionSummaryNotifier = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isCapturingReadAloudNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<PronunciationResult?> pronunciationResultNotifier =
      ValueNotifier<PronunciationResult?>(null);
  final ValueNotifier<bool> suggestIntermediateNotifier =
      ValueNotifier<bool>(false);

  DateTime? _startedAt;
  bool _sessionSaved = false;

  ReadingListeningController({
    required this.exercises,
    required this.audioService,
    required this.historyRepository,
    this.pronunciationCaptureService,
  }) {
    _resetSessionForCurrentFilter();
  }

  ReadingListeningExercise? get currentExercise {
    final visible = _visibleExerciseIndices();
    if (visible.isEmpty) {
      return null;
    }
    final safeIndex = currentIndexNotifier.value.clamp(0, visible.length - 1);
    return exercises[visible[safeIndex]];
  }

  bool get hasSubmittedCurrentAnswer {
    final visible = _visibleExerciseIndices();
    if (visible.isEmpty) {
      return false;
    }
    final safeIndex = currentIndexNotifier.value.clamp(0, visible.length - 1);
    return submittedAnswersNotifier.value[visible[safeIndex]] != null;
  }

  int get totalExercises => _visibleExerciseIndices().length;

  void setPracticeLanguage(ConversationLanguage language) {
    if (language == ConversationLanguage.auto) {
      return;
    }
    practiceLanguageNotifier.value = language;
  }

  void setDifficultyFilter(ReadingListeningDifficultyFilter filter) {
    if (difficultyFilterNotifier.value == filter) {
      return;
    }

    difficultyFilterNotifier.value = filter;
    _resetSessionForCurrentFilter();
  }

  void selectOption(int index) {
    if (hasSubmittedCurrentAnswer) {
      return;
    }
    selectedOptionNotifier.value = index;
  }

  bool submitAnswer() {
    final exercise = currentExercise;
    final selected = selectedOptionNotifier.value;
    if (exercise == null || selected == null) {
      return false;
    }

    final updated = List<int?>.from(submittedAnswersNotifier.value);
    final sourceIndex = _sourceIndexForCurrent();
    if (sourceIndex == null || updated[sourceIndex] != null) {
      return false;
    }

    updated[sourceIndex] = selected;
    submittedAnswersNotifier.value = updated;

    if (selected == exercise.correctOptionIndex) {
      correctAnswersNotifier.value += 1;
    }

    return true;
  }

  bool moveToNext() {
    if (!hasSubmittedCurrentAnswer || isCompletedNotifier.value) {
      return false;
    }

    final next = currentIndexNotifier.value + 1;
    if (next >= totalExercises) {
      isCompletedNotifier.value = true;
      sessionSummaryNotifier.value = _buildSessionSummary();
      return false;
    }

    currentIndexNotifier.value = next;
    selectedOptionNotifier.value = null;
    return true;
  }

  Future<void> playCurrentAudio() async {
    final exercise = currentExercise;
    if (exercise == null || isSpeakingNotifier.value) {
      return;
    }

    errorNotifier.value = null;
    isSpeakingNotifier.value = true;

    try {
      final language = practiceLanguageNotifier.value;
      await audioService.speak(
        exercise.readingTextFor(language),
        locale: language.ttsLocale,
      );
    } catch (_) {
      errorNotifier.value =
          'Nao foi possivel reproduzir o audio agora. Tente novamente.';
    } finally {
      isSpeakingNotifier.value = false;
    }
  }

  Future<void> stopAudio() async {
    isSpeakingNotifier.value = false;
    await audioService.stop();
  }

  bool get canReadAloud => pronunciationCaptureService != null;

  Future<void> startReadAloud() async {
    final captureService = pronunciationCaptureService;
    if (captureService == null || isCapturingReadAloudNotifier.value) {
      return;
    }

    final exercise = currentExercise;
    if (exercise == null) {
      return;
    }

    pronunciationResultNotifier.value = null;
    isCapturingReadAloudNotifier.value = true;
    errorNotifier.value = null;

    try {
      final language = practiceLanguageNotifier.value;
      final captured = await captureService.captureUserSpeech(
        localeId: language.speechLocale,
      );

      if (captured == null || captured.trim().isEmpty) {
        errorNotifier.value = language == ConversationLanguage.portugueseBr
            ? 'Nenhuma fala detectada. Tente novamente.'
            : 'No speech detected. Try again.';
        return;
      }

      final original = exercise.readingTextFor(language);
      pronunciationResultNotifier.value =
          PronunciationComparer().compare(original, captured);
    } catch (_) {
      errorNotifier.value =
          'Nao foi possivel capturar a pronuncia agora. Tente novamente.';
    } finally {
      isCapturingReadAloudNotifier.value = false;
    }
  }

  void clearPronunciationResult() {
    pronunciationResultNotifier.value = null;
  }

  Future<bool> saveSession() async {
    if (_sessionSaved ||
        totalExercises == 0 ||
        isCompletedNotifier.value == false) {
      return false;
    }

    isSavingNotifier.value = true;
    errorNotifier.value = null;

    try {
      final now = DateTime.now();
      final startedAt = _startedAt ?? now;
      final elapsedSeconds =
          now.difference(startedAt).inSeconds.clamp(30, 60 * 30);
      final language = practiceLanguageNotifier.value;

      final record = PracticeSessionRecord(
        id: 'learn_${now.microsecondsSinceEpoch}',
        startedAt: startedAt,
        endedAt: now,
        practiceFocus: _focusByLanguage(
          language,
          difficultyFilterNotifier.value,
        ),
        userTurns: submittedAnswersNotifier.value.whereType<int>().length,
        elapsedSeconds: elapsedSeconds,
        language: language,
        feedback: _buildSessionSummary(),
      );

      await historyRepository.saveSession(record);
      _sessionSaved = true;
      await _checkAdaptiveDifficulty();
      return true;
    } catch (_) {
      errorNotifier.value =
          'Nao foi possivel salvar a sessao de aprendizado agora.';
      return false;
    } finally {
      isSavingNotifier.value = false;
    }
  }

  String _focusByLanguage(
    ConversationLanguage language,
    ReadingListeningDifficultyFilter filter,
  ) {
    final suffixPt = switch (filter) {
      ReadingListeningDifficultyFilter.all => '',
      ReadingListeningDifficultyFilter.beginner => ' - Iniciante',
      ReadingListeningDifficultyFilter.intermediate => ' - Intermediario',
      ReadingListeningDifficultyFilter.advanced => ' - Avancado',
    };
    final suffixEn = switch (filter) {
      ReadingListeningDifficultyFilter.all => '',
      ReadingListeningDifficultyFilter.beginner => ' - Beginner',
      ReadingListeningDifficultyFilter.intermediate => ' - Intermediate',
      ReadingListeningDifficultyFilter.advanced => ' - Advanced',
    };

    if (language == ConversationLanguage.portugueseBr) {
      return 'Leitura e audicao$suffixPt';
    }
    return 'Reading and listening$suffixEn';
  }

  String _buildSessionSummary() {
    final total = totalExercises;
    final correct = correctAnswersNotifier.value;
    final accuracy = total == 0 ? 0 : ((correct / total) * 100).round();

    final language = practiceLanguageNotifier.value;
    if (language == ConversationLanguage.portugueseBr) {
      return 'Voce acertou $correct de $total exercicios ($accuracy%). Continue praticando leitura em voz alta e repeticao auditiva.';
    }

    return 'You got $correct out of $total exercises right ($accuracy%). Keep practicing short read-aloud and listening repetition blocks.';
  }

  void dispose() {
    unawaited(audioService.stop());
    practiceLanguageNotifier.dispose();
    difficultyFilterNotifier.dispose();
    currentIndexNotifier.dispose();
    selectedOptionNotifier.dispose();
    submittedAnswersNotifier.dispose();
    correctAnswersNotifier.dispose();
    isSpeakingNotifier.dispose();
    isCompletedNotifier.dispose();
    isSavingNotifier.dispose();
    sessionSummaryNotifier.dispose();
    errorNotifier.dispose();
    isCapturingReadAloudNotifier.dispose();
    pronunciationResultNotifier.dispose();
    suggestIntermediateNotifier.dispose();
  }

  int? _sourceIndexForCurrent() {
    final visible = _visibleExerciseIndices();
    if (visible.isEmpty) {
      return null;
    }
    final safeIndex = currentIndexNotifier.value.clamp(0, visible.length - 1);
    return visible[safeIndex];
  }

  List<int> _visibleExerciseIndices() {
    final filter = difficultyFilterNotifier.value;
    final visible = <int>[];

    for (var index = 0; index < exercises.length; index += 1) {
      final exercise = exercises[index];
      if (exercise.difficulty.matchesFilter(filter)) {
        visible.add(index);
      }
    }

    return visible;
  }

  Future<void> _checkAdaptiveDifficulty() async {
    if (difficultyFilterNotifier.value !=
        ReadingListeningDifficultyFilter.beginner) {
      return;
    }

    try {
      final sessions = await historyRepository.getSessions();
      final beginnerSessions = sessions.where((s) {
        final focus = s.practiceFocus.toLowerCase();
        return focus.contains('beginner') || focus.contains('iniciante');
      }).toList();

      if (beginnerSessions.length < 2) return;

      int highAccuracyCount = 0;
      for (final session in beginnerSessions) {
        final accuracy = _parseAccuracyFromFeedback(session.feedback);
        if (accuracy != null && accuracy >= 80) {
          highAccuracyCount += 1;
        }
      }

      suggestIntermediateNotifier.value = highAccuracyCount >= 2;
    } catch (_) {
      // Silently ignore — recommendation is non-critical.
    }
  }

  static int? _parseAccuracyFromFeedback(String feedback) {
    final match = RegExp(r'\((\d+)%\)').firstMatch(feedback);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  void _resetSessionForCurrentFilter() {
    currentIndexNotifier.value = 0;
    selectedOptionNotifier.value = null;
    submittedAnswersNotifier.value = List<int?>.filled(exercises.length, null);
    correctAnswersNotifier.value = 0;
    isCompletedNotifier.value = false;
    isSavingNotifier.value = false;
    sessionSummaryNotifier.value = null;
    errorNotifier.value = null;
    _sessionSaved = false;
    _startedAt = DateTime.now();
  }
}
