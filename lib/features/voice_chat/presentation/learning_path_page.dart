import 'package:flutter/material.dart';

import '../application/learning_api_service.dart';
import '../application/learning_path_controller.dart';
import '../domain/entities/app_locale.dart';
import '../domain/entities/lesson.dart';
import '../domain/entities/lesson_progress.dart';
import '../domain/entities/learning_unit.dart';
import '../infrastructure/local/local_learning_api_service.dart';
import 'app_settings_scope.dart';
import 'app_text.dart';
import 'lesson_page.dart';
import 'responsive_content_shell.dart';
import 'widgets/hearts_display.dart';
import 'widgets/lesson_node_widget.dart';

typedef OpenLessonCallback = Future<void> Function(
  BuildContext context,
  String unitId,
  Lesson lesson,
);

class LearningPathPage extends StatefulWidget {
  final LearningPathController? controller;
  final LearningApiService? apiService;
  final OpenLessonCallback? onOpenLesson;

  const LearningPathPage({
    super.key,
    this.controller,
    this.apiService,
    this.onOpenLesson,
  });

  @override
  State<LearningPathPage> createState() => _LearningPathPageState();
}

class _LearningPathPageState extends State<LearningPathPage> {
  late final LearningPathController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        LearningPathController(
          apiService: widget.apiService ?? LocalLearningApiService(),
        );
    _controller.load();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppSettingsScope.localeOf(context);
    final isPt = locale == AppLocale.ptBr;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            appText(context, en: 'Learning path', pt: 'Trilha de aprendizado')),
      ),
      body: SafeArea(
        child: ResponsiveContentShell.premium(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 12),
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _controller.isLoadingNotifier,
                    builder: (context, loading, _) {
                      if (loading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return ValueListenableBuilder<String?>(
                        valueListenable: _controller.errorNotifier,
                        builder: (context, error, __) {
                          if (error != null && error.trim().isNotEmpty) {
                            return Center(child: Text(error));
                          }

                          return ValueListenableBuilder<List<LearningUnit>>(
                            valueListenable: _controller.unitsNotifier,
                            builder: (context, units, ___) {
                              if (units.isEmpty) {
                                return Center(
                                  child: Text(
                                    isPt
                                        ? 'Nenhuma unidade disponivel no momento.'
                                        : 'No units available right now.',
                                  ),
                                );
                              }

                              return _buildPathList(context, isPt);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF004D40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: _controller.totalXpNotifier,
              builder: (context, xp, _) {
                return _HeaderMetric(
                  label: appText(context, en: 'XP', pt: 'XP'),
                  value: '$xp',
                );
              },
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: _controller.streakDaysNotifier,
              builder: (context, streak, _) {
                return _HeaderMetric(
                  label: appText(context, en: 'Streak', pt: 'Sequencia'),
                  value: '$streak',
                );
              },
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: _controller.availableHeartsNotifier,
            builder: (context, hearts, _) {
              return HeartsDisplay(hearts: hearts);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPathList(BuildContext context, bool isPt) {
    final units = _controller.unitsNotifier.value;
    final states = _controller.unitStatesNotifier.value;

    return ListView.builder(
      itemCount: units.length,
      itemBuilder: (context, index) {
        final unit = units[index];
        final state = states[unit.id];
        if (state == null) {
          return const SizedBox.shrink();
        }

        final unitTitle = isPt ? unit.titlePt : unit.titleEn;

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UnitBanner(
                title: unitTitle,
                completionPercent: state.completionPercent,
                unlocked: state.isUnlocked,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: unit.lessons.length,
                  separatorBuilder: (_, separatorIndex) {
                    final nextLesson = unit.lessons[separatorIndex + 1];
                    final nextUnlocked =
                        state.lessonUnlocked[nextLesson.id] ?? false;
                    return _connector(nextUnlocked);
                  },
                  itemBuilder: (context, lessonIndex) {
                    final lesson = unit.lessons[lessonIndex];
                    final progress = state.progress.lessons[lesson.id] ??
                        LessonProgress.empty(lesson.id);
                    final lessonUnlocked =
                        state.lessonUnlocked[lesson.id] ?? false;
                    final nodeState = _mapLessonNodeState(
                      unlocked: lessonUnlocked,
                      progress: progress,
                    );

                    return LessonNodeWidget(
                      key: ValueKey<String>('lesson-node-${lesson.id}'),
                      label: 'L${lessonIndex + 1}',
                      state: nodeState,
                      onTap: nodeState == LessonNodeState.locked
                          ? null
                          : () async {
                              await _openLesson(context, unit.id, lesson);
                            },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _connector(bool unlocked) {
    return SizedBox(
      width: 22,
      child: Center(
        child: Container(
          height: 4,
          decoration: BoxDecoration(
            color:
                unlocked ? Colors.cyanAccent.withOpacity(0.45) : Colors.white24,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  LessonNodeState _mapLessonNodeState({
    required bool unlocked,
    required LessonProgress progress,
  }) {
    if (!unlocked) {
      return LessonNodeState.locked;
    }
    if (progress.isCompleted && progress.bestScore >= 100) {
      return LessonNodeState.perfect;
    }
    if (progress.isCompleted) {
      return LessonNodeState.completed;
    }
    return LessonNodeState.available;
  }

  Future<void> _openLesson(
    BuildContext context,
    String unitId,
    Lesson lesson,
  ) async {
    final external = widget.onOpenLesson;
    if (external != null) {
      await external(context, unitId, lesson);
      await _controller.refreshProgressOnly();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonPage(
          unitId: unitId,
          lesson: lesson,
        ),
      ),
    );

    await _controller.refreshProgressOnly();
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _UnitBanner extends StatelessWidget {
  final String title;
  final int completionPercent;
  final bool unlocked;

  const _UnitBanner({
    required this.title,
    required this.completionPercent,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFF1E3A5F) : const Color(0xFF2B2F35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? const Color(0xFF4FC3F7) : Colors.white24,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '$completionPercent%',
            style: TextStyle(
              color: unlocked ? Colors.cyanAccent.shade100 : Colors.white54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
