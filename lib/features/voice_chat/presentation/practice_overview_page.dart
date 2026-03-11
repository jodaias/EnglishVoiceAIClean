import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../application/app_feature_flags.dart';
import '../application/lesson_content_catalog.dart';
import '../application/practice_hub_controller.dart';
import '../application/spaced_repetition_service.dart';
import '../application/session_history_service.dart';
import '../domain/entities/lesson.dart';
import '../domain/entities/reading_listening_exercise.dart';
import '../infrastructure/ai/exercise_generator_service.dart';
import '../infrastructure/local/local_learning_api_service.dart';
import '../infrastructure/local/local_session_history_repository.dart';
import 'app_text.dart';
import 'dashboard_routes.dart';
import 'lesson_page.dart';
import 'practice_hub_sheet.dart';
import 'responsive_content_shell.dart';

class PracticeOverviewPage extends StatefulWidget {
  const PracticeOverviewPage({super.key});

  @override
  State<PracticeOverviewPage> createState() => _PracticeOverviewPageState();
}

class _PracticeOverviewPageState extends State<PracticeOverviewPage> {
  late final PracticeHubController controller;
  late final ExerciseGeneratorService _exerciseGeneratorService;
  late final SpacedRepetitionService _spacedRepetitionService;
  final ValueNotifier<bool> _isGeneratingSurpriseLessonNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isOpeningDailyReviewNotifier =
      ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    final featureFlags = AppFeatureFlags.fromEnv(dotenv.env);
    final historyRepository = LocalSessionHistoryRepository();
    final learningApiService = LocalLearningApiService();
    controller = PracticeHubController(
      repository: historyRepository,
      historyService: SessionHistoryService(),
      featureFlags: featureFlags,
      learningApiService: learningApiService,
    );
    _spacedRepetitionService = SpacedRepetitionService(
      learningApiService: learningApiService,
      trackableExerciseIds: LessonContentCatalog()
          .loadDefaultUnits()
          .expand((unit) => unit.lessons)
          .expand((lesson) => lesson.exercises)
          .map((exercise) => exercise.id)
          .toSet(),
    );
    _exerciseGeneratorService = ExerciseGeneratorService();
    controller.load();
  }

  @override
  void dispose() {
    _isGeneratingSurpriseLessonNotifier.dispose();
    _isOpeningDailyReviewNotifier.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appText(context, en: 'Practice Overview', pt: 'Visao de Pratica'),
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
                        .pushNamed(DashboardRoutes.readingListening);
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
            Navigator.of(context).pushReplacementNamed(DashboardRoutes.session);
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
            label: appText(context, en: 'Practice', pt: 'Pratica'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: appText(context, en: 'Session', pt: 'Sessao'),
          ),
        ],
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

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LessonPage(
            unitId: lesson.unitId,
            lesson: lesson,
            spacedRepetitionService: _spacedRepetitionService,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appText(
              context,
              en: 'Could not generate a surprise lesson right now. Please try again.',
              pt: 'Nao foi possivel gerar uma licao surpresa agora. Tente novamente.',
            ),
          ),
        ),
      );
    } finally {
      _isGeneratingSurpriseLessonNotifier.value = false;
    }
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
                pt: 'Nao ha revisoes vencidas agora. Volte mais tarde.',
              ),
            ),
          ),
        );
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

      await controller.load();
    } finally {
      _isOpeningDailyReviewNotifier.value = false;
    }
  }

  Future<_SurpriseLessonSelection?> _showSurpriseLessonPicker() async {
    final units = LessonContentCatalog().loadDefaultUnits();
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
                  pt: 'Licao Surpresa',
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
