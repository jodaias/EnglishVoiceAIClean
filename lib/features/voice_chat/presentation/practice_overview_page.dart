import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../application/app_feature_flags.dart';
import '../application/lesson_content_catalog.dart';
import '../application/practice_hub_controller.dart';
import '../application/spaced_repetition_service.dart';
import '../application/session_history_service.dart';
import '../domain/entities/lesson.dart';
import '../domain/entities/lesson_exercise.dart';
import '../domain/entities/reading_listening_exercise.dart';
import '../infrastructure/ai/exercise_generator_service.dart';
import '../infrastructure/local/local_learning_api_service.dart';
import '../infrastructure/local/local_session_history_repository.dart';
import 'app_text.dart';
import 'dashboard_routes.dart';
import 'lesson_page.dart';
import 'practice_hub_sheet.dart';
import 'responsive_content_shell.dart';

typedef OpenLessonCallback = Future<void> Function(
  BuildContext context,
  Lesson lesson,
  SpacedRepetitionService spacedRepetitionService,
);

class PracticeOverviewPage extends StatefulWidget {
  final PracticeHubController? practiceHubController;
  final ExerciseGeneratorService? exerciseGeneratorService;
  final SpacedRepetitionService? spacedRepetitionService;
  final LessonContentCatalog? lessonContentCatalog;
  final OpenLessonCallback? onOpenLesson;

  const PracticeOverviewPage({
    super.key,
    this.practiceHubController,
    this.exerciseGeneratorService,
    this.spacedRepetitionService,
    this.lessonContentCatalog,
    this.onOpenLesson,
  });

  @override
  State<PracticeOverviewPage> createState() => _PracticeOverviewPageState();
}

class _PracticeOverviewPageState extends State<PracticeOverviewPage> {
  late final PracticeHubController controller;
  late final ExerciseGeneratorService _exerciseGeneratorService;
  late final SpacedRepetitionService _spacedRepetitionService;
  late final LessonContentCatalog _lessonContentCatalog;
  late final bool _ownsController;
  final ValueNotifier<bool> _isGeneratingSurpriseLessonNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isOpeningDailyReviewNotifier =
      ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _lessonContentCatalog =
        widget.lessonContentCatalog ?? LessonContentCatalog();
    _ownsController = widget.practiceHubController == null;

    if (_ownsController) {
      final featureFlags = AppFeatureFlags.fromEnv(dotenv.env);
      final historyRepository = LocalSessionHistoryRepository();
      final learningApiService = LocalLearningApiService();
      controller = PracticeHubController(
        repository: historyRepository,
        historyService: SessionHistoryService(),
        featureFlags: featureFlags,
        learningApiService: learningApiService,
      );
      _spacedRepetitionService = widget.spacedRepetitionService ??
          SpacedRepetitionService(
            learningApiService: learningApiService,
            trackableExerciseIds: _lessonContentCatalog
                .loadDefaultUnits()
                .expand((unit) => unit.lessons)
                .expand((lesson) => lesson.exercises)
                .map((exercise) => exercise.id)
                .toSet(),
          );
    } else {
      controller = widget.practiceHubController!;
      _spacedRepetitionService = widget.spacedRepetitionService ??
          SpacedRepetitionService(
            learningApiService: LocalLearningApiService(),
            trackableExerciseIds: _lessonContentCatalog
                .loadDefaultUnits()
                .expand((unit) => unit.lessons)
                .expand((lesson) => lesson.exercises)
                .map((exercise) => exercise.id)
                .toSet(),
          );
    }

    _exerciseGeneratorService =
        widget.exerciseGeneratorService ?? ExerciseGeneratorService();
    controller.load();
  }

  @override
  void dispose() {
    _isGeneratingSurpriseLessonNotifier.dispose();
    _isOpeningDailyReviewNotifier.dispose();
    if (_ownsController) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appText(context, en: 'Practice Overview', pt: 'Visao de Prática'),
        ),
      ),
      body: ResponsiveContentShell.premium(
        child: ValueListenableBuilder<bool>(
          valueListenable: _isGeneratingSurpriseLessonNotifier,
          builder: (context, isGenerating, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _isOpeningDailyReviewNotifier,
              builder: (context, isOpeningReview, __) {
                return PracticeHubSheet(
                  controller: controller,
                  isGeneratingSurpriseLesson: isGenerating,
                  isOpeningDailyReview: isOpeningReview,
                  onOpenReadingListening: () {
                    Navigator.of(context)
                        .pushNamed(DashboardRoutes.learningPath);
                  },
                  onOpenSurpriseLesson: _openSurpriseLesson,
                  onOpenDailyReview: _openDailyReviewLesson,
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context)
                .pushReplacementNamed(DashboardRoutes.dashboard);
            return;
          }

          if (index == 2) {
            Navigator.of(context)
                .pushReplacementNamed(DashboardRoutes.settings);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: appText(context, en: 'Dashboard', pt: 'Dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.insights_outlined),
            activeIcon: const Icon(Icons.insights),
            label: appText(context, en: 'Practice', pt: 'Prática'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: appText(context, en: 'Settings', pt: 'Configurações'),
          ),
        ],
      ),
    );
  }

  Future<void> _openLesson(Lesson lesson) async {
    final customOpen = widget.onOpenLesson;
    if (customOpen != null) {
      await customOpen(context, lesson, _spacedRepetitionService);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonPage(
          unitId: lesson.unitId,
          lesson: lesson,
          spacedRepetitionService: _spacedRepetitionService,
        ),
      ),
    );
  }

  Future<void> _openSurpriseLesson() async {
    if (_isGeneratingSurpriseLessonNotifier.value) {
      return;
    }

    final selection = await _showSurpriseLessonPicker();
    if (selection == null || !mounted) {
      return;
    }

    _isGeneratingSurpriseLessonNotifier.value = true;

    try {
      final generatedExercises =
          await _exerciseGeneratorService.generateSurpriseLesson(
        topic: selection.topic,
        difficulty: selection.difficulty,
      );

      if (!mounted) {
        return;
      }

      final lesson = Lesson(
        id: 'surprise_${DateTime.now().millisecondsSinceEpoch}',
        unitId: 'unit_surprise_ai',
        orderIndex: 0,
        exercises: generatedExercises,
      );

      await _openLesson(lesson);
    } catch (error) {
      if (!mounted) {
        return;
      }

      final rateLimited = error is AIQuotaExceededException;
      final retryAfterSeconds =
          rateLimited ? (error).retryAfter?.inSeconds : null;

      if (rateLimited) {
        final fallbackLesson = _buildFallbackSurpriseLesson(
          topic: selection.topic,
          difficulty: selection.difficulty,
        );

        if (fallbackLesson != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                appText(
                  context,
                  en: retryAfterSeconds == null
                      ? 'AI is rate-limited (HTTP 429). Starting a curated fallback lesson now.'
                      : 'AI is rate-limited (HTTP 429). Starting fallback now. Try AI again in about $retryAfterSeconds seconds.',
                  pt: retryAfterSeconds == null
                      ? 'A IA atingiu limite (HTTP 429). Iniciando uma lição curada de fallback agora.'
                      : 'A IA atingiu limite (HTTP 429). Iniciando fallback agora. Tente a IA novamente em cerca de $retryAfterSeconds segundos.',
                ),
              ),
            ),
          );

          await _openLesson(fallbackLesson);
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appText(
              context,
              en: rateLimited
                  ? retryAfterSeconds == null
                      ? 'AI is rate-limited (HTTP 429). Please wait a moment and try again.'
                      : 'AI is rate-limited (HTTP 429). Try again in about $retryAfterSeconds seconds.'
                  : 'Could not generate a surprise lesson right now. Please try again.',
              pt: rateLimited
                  ? retryAfterSeconds == null
                      ? 'A IA atingiu limite de requisicoes (HTTP 429). Aguarde um pouco e tente novamente.'
                      : 'A IA atingiu limite de requisicoes (HTTP 429). Tente novamente em cerca de $retryAfterSeconds segundos.'
                  : 'Não foi possível gerar uma lição surpresa agora. Tente novamente.',
            ),
          ),
        ),
      );
    } finally {
      _isGeneratingSurpriseLessonNotifier.value = false;
    }
  }

  Lesson? _buildFallbackSurpriseLesson({
    required String topic,
    required ReadingListeningDifficulty difficulty,
  }) {
    final units = _lessonContentCatalog.loadDefaultUnits();
    if (units.isEmpty) {
      return null;
    }

    final topicNormalized = topic.trim().toLowerCase();

    final matchedUnits = units.where((unit) {
      final titleEn = unit.titleEn.trim().toLowerCase();
      final titlePt = unit.titlePt.trim().toLowerCase();
      return titleEn == topicNormalized || titlePt == topicNormalized;
    }).toList(growable: false);
    final matchedUnit = matchedUnits.isEmpty ? null : matchedUnits.first;

    final unitByDifficulty =
        units.where((unit) => unit.difficulty == difficulty);
    final sourceUnit = matchedUnit ??
        (unitByDifficulty.isNotEmpty ? unitByDifficulty.first : units.first);

    final allExercises = sourceUnit.lessons
        .expand((lesson) => lesson.exercises)
        .toList(growable: false);
    if (allExercises.isEmpty) {
      return null;
    }

    var selected = allExercises
        .where((exercise) => exercise.difficulty == difficulty)
        .toList(growable: false);
    if (selected.isEmpty) {
      selected = allExercises;
    }

    final maxExercises = selected.length < 6 ? selected.length : 6;
    if (maxExercises <= 0) {
      return null;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final offset = selected.length <= 1 ? 0 : now % selected.length;
    final rotated = <LessonExercise>[];
    for (var i = 0; i < selected.length; i += 1) {
      rotated.add(selected[(offset + i) % selected.length]);
    }

    return Lesson(
      id: 'surprise_fallback_${DateTime.now().millisecondsSinceEpoch}',
      unitId: 'unit_surprise_fallback',
      orderIndex: 0,
      exercises: rotated.take(maxExercises).toList(growable: false),
    );
  }

  Future<void> _openDailyReviewLesson() async {
    if (_isOpeningDailyReviewNotifier.value) {
      return;
    }

    _isOpeningDailyReviewNotifier.value = true;
    try {
      final lesson = await controller.buildDailyReviewLesson();
      if (!mounted) {
        return;
      }

      if (lesson == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appText(
                context,
                en: 'No review items due right now. Come back later.',
                pt: 'Não há revisões vencidas agora. Volte mais tarde.',
              ),
            ),
          ),
        );
        return;
      }

      await _openLesson(lesson);

      await controller.load();
    } finally {
      _isOpeningDailyReviewNotifier.value = false;
    }
  }

  Future<_SurpriseLessonSelection?> _showSurpriseLessonPicker() async {
    final units = _lessonContentCatalog.loadDefaultUnits();
    final topicOptions = units
        .map((unit) => appText(
              context,
              en: unit.titleEn,
              pt: unit.titlePt,
            ))
        .toSet()
        .toList(growable: false);

    if (topicOptions.isEmpty) {
      return null;
    }

    var selectedTopic = topicOptions.first;
    var selectedDifficulty = ReadingListeningDifficulty.beginner;

    return showDialog<_SurpriseLessonSelection>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                appText(
                  context,
                  en: 'Surprise Lesson',
                  pt: 'Lição Surpresa',
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appText(
                      context,
                      en: 'Topic',
                      pt: 'Tema',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTopic,
                    items: topicOptions
                        .map(
                          (topic) => DropdownMenuItem<String>(
                            value: topic,
                            child: Text(topic),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedTopic = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    appText(
                      context,
                      en: 'Difficulty',
                      pt: 'Dificuldade',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _difficultyChip(
                        context: context,
                        selectedDifficulty: selectedDifficulty,
                        value: ReadingListeningDifficulty.beginner,
                        onSelected: () {
                          setState(() {
                            selectedDifficulty =
                                ReadingListeningDifficulty.beginner;
                          });
                        },
                      ),
                      _difficultyChip(
                        context: context,
                        selectedDifficulty: selectedDifficulty,
                        value: ReadingListeningDifficulty.intermediate,
                        onSelected: () {
                          setState(() {
                            selectedDifficulty =
                                ReadingListeningDifficulty.intermediate;
                          });
                        },
                      ),
                      _difficultyChip(
                        context: context,
                        selectedDifficulty: selectedDifficulty,
                        value: ReadingListeningDifficulty.advanced,
                        onSelected: () {
                          setState(() {
                            selectedDifficulty =
                                ReadingListeningDifficulty.advanced;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(appText(context, en: 'Cancel', pt: 'Cancelar')),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      _SurpriseLessonSelection(
                        topic: selectedTopic,
                        difficulty: selectedDifficulty,
                      ),
                    );
                  },
                  child: Text(
                    appText(
                      context,
                      en: 'Generate',
                      pt: 'Gerar',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _difficultyChip({
    required BuildContext context,
    required ReadingListeningDifficulty selectedDifficulty,
    required ReadingListeningDifficulty value,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(_difficultyLabel(context, value)),
      selected: selectedDifficulty == value,
      onSelected: (_) => onSelected(),
    );
  }

  String _difficultyLabel(
    BuildContext context,
    ReadingListeningDifficulty difficulty,
  ) {
    switch (difficulty) {
      case ReadingListeningDifficulty.beginner:
        return appText(context, en: 'Beginner', pt: 'Iniciante');
      case ReadingListeningDifficulty.intermediate:
        return appText(context, en: 'Intermediate', pt: 'Intermediário');
      case ReadingListeningDifficulty.advanced:
        return appText(context, en: 'Advanced', pt: 'Avançado');
    }
  }
}

class _SurpriseLessonSelection {
  final String topic;
  final ReadingListeningDifficulty difficulty;

  const _SurpriseLessonSelection({
    required this.topic,
    required this.difficulty,
  });
}
