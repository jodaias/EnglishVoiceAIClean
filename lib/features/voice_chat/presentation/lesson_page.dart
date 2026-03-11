import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/exercise_validator.dart';
import '../application/hearts_manager.dart';
import '../application/lesson_feedback_audio_service.dart';
import '../application/lesson_content_catalog.dart';
import '../application/lesson_controller.dart';
import '../application/pronunciation_comparer.dart';
import '../application/spaced_repetition_service.dart';
import '../application/xp_calculator.dart';
import '../domain/entities/app_locale.dart';
import '../domain/entities/conversation_language.dart';
import '../domain/entities/exercise_type.dart';
import '../domain/entities/lesson.dart';
import '../domain/entities/lesson_exercise.dart';
import '../infrastructure/local/local_learning_progress_repository.dart';
import '../infrastructure/audio/system_lesson_feedback_audio_service.dart';
import '../infrastructure/local/local_learning_api_service.dart';
import '../infrastructure/speech/speech_service.dart';
import '../infrastructure/speech/stt_pronunciation_capture_service.dart';
import '../infrastructure/tts/learning_audio_tts_service.dart';
import '../infrastructure/tts/tts_service.dart';
import 'app_settings_scope.dart';
import 'app_text.dart';
import 'lesson_summary_page.dart';
import 'responsive_content_shell.dart';
import 'widgets/feedback_overlay.dart';
import 'widgets/hearts_display.dart';
import 'widgets/lesson_exercise_widgets.dart';
import 'widgets/progress_bar_widget.dart';

class LessonPage extends StatefulWidget {
  final String? unitId;
  final Lesson? lesson;
  final LessonController? controller;
  final LessonFeedbackAudioService? feedbackAudioService;
  final SpacedRepetitionService? spacedRepetitionService;

  const LessonPage({
    super.key,
    this.unitId,
    this.lesson,
    this.controller,
    this.feedbackAudioService,
    this.spacedRepetitionService,
  });

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late final LessonController _controller;
  late final bool _ownsController;
  late final LessonFeedbackAudioService _feedbackAudioService;
  late final bool _ownsFeedbackAudioService;
  final ValueNotifier<int> _pronunciationAccuracyNotifier =
      ValueNotifier<int>(0);

  bool _completionHandled = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsFeedbackAudioService = widget.feedbackAudioService == null;
    _controller = widget.controller ?? _buildDefaultController();
    _feedbackAudioService =
        widget.feedbackAudioService ?? SystemLessonFeedbackAudioService();
    _controller.isCompletedNotifier.addListener(_onControllerCompleted);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appLocale = AppSettingsScope.localeOf(context);
    final language = appLocale == AppLocale.ptBr
        ? ConversationLanguage.portugueseBr
        : ConversationLanguage.englishUs;
    _controller.setLanguage(language);
  }

  @override
  void dispose() {
    _controller.isCompletedNotifier.removeListener(_onControllerCompleted);
    _pronunciationAccuracyNotifier.dispose();
    if (_ownsFeedbackAudioService) {
      unawaited(_feedbackAudioService.dispose());
    }
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmExit,
        ),
        title: Text(appText(context, en: 'Lesson', pt: 'Licao')),
      ),
      body: SafeArea(
        child: ResponsiveContentShell.premium(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(context),
                const SizedBox(height: 12),
                Expanded(child: _buildExerciseArea(context)),
                const SizedBox(height: 10),
                _buildBottomAction(context),
                const SizedBox(height: 6),
                ValueListenableBuilder<String?>(
                  valueListenable: _controller.errorNotifier,
                  builder: (context, error, _) {
                    if (error == null || error.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      error,
                      style: const TextStyle(color: Colors.redAccent),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<double>(
          valueListenable: _controller.progressNotifier,
          builder: (context, progress, _) {
            return ProgressBarWidget(progress: progress);
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: _controller.currentExerciseIndexNotifier,
                builder: (context, index, _) {
                  final current =
                      _controller.totalExercises == 0 ? 0 : index + 1;
                  return Text(
                    appText(
                      context,
                      en: 'Exercise $current/${_controller.totalExercises}',
                      pt: 'Exercicio $current/${_controller.totalExercises}',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  );
                },
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _controller.heartsNotifier,
              builder: (context, hearts, _) {
                return HeartsDisplay(hearts: hearts);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExerciseArea(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _controller.currentExerciseIndexNotifier,
      builder: (context, index, _) {
        return ValueListenableBuilder<ConversationLanguage>(
          valueListenable: _controller.languageNotifier,
          builder: (context, language, __) {
            return ValueListenableBuilder<Object?>(
              valueListenable: _controller.selectedAnswerNotifier,
              builder: (context, selected, ___) {
                return ValueListenableBuilder<LessonAnswerFeedback?>(
                  valueListenable: _controller.feedbackNotifier,
                  builder: (context, feedback, ____) {
                    final exercise = _controller.currentExerciseNotifier.value;
                    if (exercise == null) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: SingleChildScrollView(
                              key: ValueKey<String>(exercise.id),
                              child: LessonExerciseRenderer(
                                exercise: exercise,
                                language: language,
                                selectedAnswer: selected,
                                pronunciationAccuracyPercent:
                                    _pronunciationAccuracyNotifier.value,
                                enabled: feedback == null,
                                onAnswerChanged: _onAnswerChanged,
                                onPlayAudio: _controller.playCurrentPromptAudio,
                                onStartSpeechCapture: () {
                                  _captureSpokenAnswer(exercise);
                                },
                              ),
                            ),
                          ),
                        ),
                        if (feedback != null) ...[
                          const SizedBox(height: 10),
                          FeedbackOverlay(
                            isCorrect: feedback.isCorrect,
                            message: _feedbackMessage(
                              context,
                              feedback: feedback,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return ValueListenableBuilder<LessonAnswerFeedback?>(
      valueListenable: _controller.feedbackNotifier,
      builder: (context, feedback, _) {
        final submitted = feedback != null;
        return FilledButton(
          onPressed: () async {
            if (!submitted) {
              final didSubmit = _controller.submitCurrentAnswer();
              if (didSubmit) {
                await _playFeedbackForLastAnswer();
              }
              if (!didSubmit && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      appText(
                        context,
                        en: 'Select or type an answer before checking.',
                        pt: 'Selecione ou digite uma resposta antes de verificar.',
                      ),
                    ),
                  ),
                );
              }
              return;
            }

            _pronunciationAccuracyNotifier.value = 0;
            _safeHaptic(HapticFeedback.selectionClick);
            await _controller.continueAfterFeedback();
          },
          child: Text(
            submitted
                ? appText(context, en: 'CONTINUE', pt: 'CONTINUAR')
                : appText(context, en: 'CHECK', pt: 'VERIFICAR'),
          ),
        );
      },
    );
  }

  Future<void> _captureSpokenAnswer(LessonExercise exercise) async {
    final spoken = await _controller.captureSpokenAnswer();
    if (spoken == null || spoken.trim().isEmpty) {
      return;
    }

    if (exercise.type != ExerciseType.speakTheSentence) {
      return;
    }

    final reference = (exercise.content['referenceText'] ?? '').toString();
    if (reference.trim().isEmpty) {
      return;
    }

    final result = PronunciationComparer().compare(reference, spoken);
    _pronunciationAccuracyNotifier.value = result.accuracyPercent;
    _controller.setPronunciationAnswer(
      spokenText: spoken,
      pronunciationAccuracyPercent: result.accuracyPercent,
    );
  }

  String _feedbackMessage(
    BuildContext context, {
    required LessonAnswerFeedback feedback,
  }) {
    if (feedback.isCorrect) {
      return appText(context, en: 'Great job!', pt: 'Boa!');
    }

    final exercise = _controller.currentExerciseNotifier.value;
    if (exercise != null) {
      if (exercise.type == ExerciseType.multipleChoice ||
          exercise.type == ExerciseType.listenAndSelect ||
          exercise.type == ExerciseType.fillInTheBlank) {
        final options = _optionsForCurrentExercise(exercise);
        final correct = (exercise.content['correctOptionIndex'] as int?) ?? -1;
        if (correct >= 0 && correct < options.length) {
          return appText(
            context,
            en: 'Not this time. Correct answer: ${options[correct]}',
            pt: 'Ainda nao. Resposta correta: ${options[correct]}',
          );
        }
      }
    }

    return appText(
      context,
      en: 'Not this time. Review and try again in the next one.',
      pt: 'Ainda nao. Revise e tente novamente na proxima.',
    );
  }

  List<String> _optionsForCurrentExercise(LessonExercise exercise) {
    final lang = _controller.languageNotifier.value;
    final key =
        lang == ConversationLanguage.portugueseBr ? 'optionsPt' : 'optionsEn';
    final raw = exercise.content[key];
    if (raw is List) {
      return raw.map((item) => item.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                  appText(context, en: 'Exit lesson?', pt: 'Sair da licao?')),
              content: Text(
                appText(
                  context,
                  en: 'You may lose your current progress.',
                  pt: 'Voce pode perder seu progresso atual.',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(appText(context, en: 'Stay', pt: 'Ficar')),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(appText(context, en: 'Exit', pt: 'Sair')),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldExit && mounted) {
      Navigator.of(context).pop();
    }
  }

  LessonController _buildDefaultController() {
    final units = LessonContentCatalog().loadDefaultUnits();
    final selectedUnit = units.first;
    final selectedLesson = selectedUnit.lessons.first;

    return LessonController(
      unitId: widget.unitId ?? selectedUnit.id,
      lesson: widget.lesson ?? selectedLesson,
      validator: const ExerciseValidator(),
      xpCalculator: const XpCalculator(),
      heartsManager: HeartsManager(),
      progressRepository: LocalLearningProgressRepository(),
      audioService: LearningAudioTtsService(ttsService: TTSService()),
      pronunciationCaptureService: SttPronunciationCaptureService(
        speechService: SpeechService(),
      ),
      spacedRepetitionService: widget.spacedRepetitionService ??
          SpacedRepetitionService(
            learningApiService: LocalLearningApiService(),
            trackableExerciseIds: units
                .expand((unit) => unit.lessons)
                .expand((lesson) => lesson.exercises)
                .map((exercise) => exercise.id)
                .toSet(),
          ),
    );
  }

  void _onControllerCompleted() {
    if (!mounted ||
        _completionHandled ||
        !_controller.isCompletedNotifier.value) {
      return;
    }

    final summary = _controller.summaryNotifier.value;
    if (summary == null) {
      return;
    }

    _completionHandled = true;
    unawaited(_feedbackAudioService.playComplete());
    _safeHaptic(HapticFeedback.mediumImpact);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LessonSummaryPage(summary: summary),
      ),
    );
  }

  void _onAnswerChanged(Object answer) {
    _controller.selectAnswer(answer);
    _safeHaptic(HapticFeedback.selectionClick);
  }

  Future<void> _playFeedbackForLastAnswer() async {
    final feedback = _controller.feedbackNotifier.value;
    if (feedback == null) {
      return;
    }

    if (feedback.isCorrect) {
      await _feedbackAudioService.playCorrect();
      _safeHaptic(HapticFeedback.lightImpact);
    } else {
      await _feedbackAudioService.playWrong();
      _safeHaptic(HapticFeedback.heavyImpact);
    }
  }

  void _safeHaptic(Future<void> Function() trigger) {
    try {
      unawaited(trigger());
    } catch (_) {}
  }
}
