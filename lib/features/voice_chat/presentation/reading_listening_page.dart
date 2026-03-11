import 'package:flutter/material.dart';

import '../application/reading_listening_catalog.dart';
import '../application/reading_listening_controller.dart';
import '../domain/entities/app_locale.dart';
import '../domain/entities/conversation_language.dart';
import '../domain/entities/pronunciation_result.dart';
import '../domain/entities/reading_listening_exercise.dart';
import '../infrastructure/local/local_session_history_repository.dart';
import '../infrastructure/speech/speech_service.dart';
import '../infrastructure/speech/stt_pronunciation_capture_service.dart';
import '../infrastructure/tts/learning_audio_tts_service.dart';
import '../infrastructure/tts/tts_service.dart';
import 'app_settings_scope.dart';
import 'app_text.dart';
import 'responsive_content_shell.dart';

class ReadingListeningPage extends StatefulWidget {
  const ReadingListeningPage({super.key});

  @override
  State<ReadingListeningPage> createState() => _ReadingListeningPageState();
}

class _ReadingListeningPageState extends State<ReadingListeningPage> {
  late final ReadingListeningController controller;

  @override
  void initState() {
    super.initState();
    controller = ReadingListeningController(
      exercises: ReadingListeningCatalog().loadDefault(),
      audioService: LearningAudioTtsService(ttsService: TTSService()),
      historyRepository: LocalSessionHistoryRepository(),
      pronunciationCaptureService: SttPronunciationCaptureService(
        speechService: SpeechService(),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = AppSettingsScope.localeOf(context);
    final language = locale == AppLocale.ptBr
        ? ConversationLanguage.portugueseBr
        : ConversationLanguage.englishUs;
    controller.setPracticeLanguage(language);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appText(
            context,
            en: 'Reading and Listening',
            pt: 'Leitura e Audicao',
          ),
        ),
      ),
      body: ResponsiveContentShell.premium(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: ValueListenableBuilder<bool>(
              valueListenable: controller.isCompletedNotifier,
              builder: (context, completed, _) {
                if (controller.totalExercises == 0) {
                  return Center(
                    child: Text(
                      appText(
                        context,
                        en: 'No exercises available right now.',
                        pt: 'Nenhum exercicio disponivel agora.',
                      ),
                    ),
                  );
                }

                return ListView(
                  children: [
                    _buildLanguageSelector(context),
                    const SizedBox(height: 8),
                    _buildDifficultySelector(context),
                    const SizedBox(height: 12),
                    if (completed)
                      _buildSummaryCard(context)
                    else
                      _buildExerciseCard(context),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<String?>(
                      valueListenable: controller.errorNotifier,
                      builder: (context, error, _) {
                        if (error == null || error.trim().isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(error),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultySelector(BuildContext context) {
    return ValueListenableBuilder<ReadingListeningDifficultyFilter>(
      valueListenable: controller.difficultyFilterNotifier,
      builder: (context, selected, _) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appText(
                  context,
                  en: 'Difficulty',
                  pt: 'Dificuldade',
                ),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _difficultyChip(
                    context: context,
                    selected: selected,
                    value: ReadingListeningDifficultyFilter.all,
                  ),
                  _difficultyChip(
                    context: context,
                    selected: selected,
                    value: ReadingListeningDifficultyFilter.beginner,
                  ),
                  _difficultyChip(
                    context: context,
                    selected: selected,
                    value: ReadingListeningDifficultyFilter.intermediate,
                  ),
                  _difficultyChip(
                    context: context,
                    selected: selected,
                    value: ReadingListeningDifficultyFilter.advanced,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _difficultyChip({
    required BuildContext context,
    required ReadingListeningDifficultyFilter selected,
    required ReadingListeningDifficultyFilter value,
  }) {
    return ChoiceChip(
      label: Text(_difficultyLabel(context, value)),
      selected: selected == value,
      onSelected: (_) => controller.setDifficultyFilter(value),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return ValueListenableBuilder<ConversationLanguage>(
      valueListenable: controller.practiceLanguageNotifier,
      builder: (context, selected, _) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appText(
                  context,
                  en: 'Practice language',
                  pt: 'Idioma de pratica',
                ),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('English (US)'),
                    selected: selected == ConversationLanguage.englishUs,
                    onSelected: (_) => controller.setPracticeLanguage(
                      ConversationLanguage.englishUs,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Portugues (BR)'),
                    selected: selected == ConversationLanguage.portugueseBr,
                    onSelected: (_) => controller.setPracticeLanguage(
                      ConversationLanguage.portugueseBr,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseCard(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: controller.currentIndexNotifier,
      builder: (context, index, _) {
        if (controller.totalExercises == 0) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              appText(
                context,
                en: 'No exercises for this level yet. Try another difficulty.',
                pt: 'Ainda nao ha exercicios para esse nivel. Tente outra dificuldade.',
              ),
            ),
          );
        }

        final exercise = controller.currentExercise;
        if (exercise == null) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<ConversationLanguage>(
          valueListenable: controller.practiceLanguageNotifier,
          builder: (context, language, _) {
            final title = exercise.titleFor(language);
            final readingText = exercise.readingTextFor(language);
            final question = exercise.questionFor(language);
            final options = exercise.optionsFor(language);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title (${index + 1}/${controller.totalExercises})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    readingText,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: controller.isSpeakingNotifier,
                        builder: (context, speaking, _) {
                          return FilledButton.icon(
                            onPressed: speaking
                                ? controller.stopAudio
                                : controller.playCurrentAudio,
                            icon: Icon(
                              speaking
                                  ? Icons.stop_circle_outlined
                                  : Icons.volume_up_outlined,
                            ),
                            label: Text(
                              speaking
                                  ? appText(
                                      context,
                                      en: 'Stop audio',
                                      pt: 'Parar audio',
                                    )
                                  : appText(
                                      context,
                                      en: 'Listen',
                                      pt: 'Ouvir',
                                    ),
                            ),
                          );
                        },
                      ),
                      if (controller.canReadAloud) ...[
                        const SizedBox(width: 8),
                        ValueListenableBuilder<bool>(
                          valueListenable:
                              controller.isCapturingReadAloudNotifier,
                          builder: (context, capturing, _) {
                            return OutlinedButton.icon(
                              onPressed:
                                  capturing ? null : controller.startReadAloud,
                              icon: Icon(
                                capturing
                                    ? Icons.hearing
                                    : Icons.record_voice_over_outlined,
                              ),
                              label: Text(
                                capturing
                                    ? appText(
                                        context,
                                        en: 'Listening...',
                                        pt: 'Ouvindo...',
                                      )
                                    : appText(
                                        context,
                                        en: 'Read aloud',
                                        pt: 'Ler em voz alta',
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                  _buildPronunciationResult(context),
                  const SizedBox(height: 12),
                  Text(
                    question,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildOptionTiles(options),
                  _buildAnswerFeedback(context),
                  const SizedBox(height: 10),
                  _buildActionButtons(context),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildOptionTiles(List<String> options) {
    return options.asMap().entries.map((entry) {
      final optionIndex = entry.key;
      final label = entry.value;

      return ValueListenableBuilder<int?>(
        valueListenable: controller.selectedOptionNotifier,
        builder: (context, selectedOption, _) {
          return ValueListenableBuilder<List<int?>>(
            valueListenable: controller.submittedAnswersNotifier,
            builder: (context, _, __) {
              final submitted = controller.hasSubmittedCurrentAnswer;
              final canSelect = !submitted;
              final selected = selectedOption == optionIndex;

              Color? tileColor;
              if (submitted && selectedOption != null) {
                final exercise = controller.currentExercise;
                if (exercise != null) {
                  final isCorrectOption =
                      optionIndex == exercise.correctOptionIndex;
                  final isSelectedOption = optionIndex == selectedOption;

                  if (isCorrectOption) {
                    tileColor = Colors.green.withOpacity(0.15);
                  } else if (isSelectedOption) {
                    tileColor = Colors.red.withOpacity(0.15);
                  }
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RadioListTile<int>(
                  value: optionIndex,
                  groupValue: selectedOption,
                  onChanged: canSelect
                      ? (_) => controller.selectOption(optionIndex)
                      : null,
                  title: Text(
                    label,
                    style: TextStyle(
                      color: tileColor != null ? Colors.white : null,
                      fontWeight: tileColor != null ? FontWeight.w600 : null,
                    ),
                  ),
                  selected: selected,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              );
            },
          );
        },
      );
    }).toList(growable: false);
  }

  Widget _buildAnswerFeedback(BuildContext context) {
    return ValueListenableBuilder<List<int?>>(
      valueListenable: controller.submittedAnswersNotifier,
      builder: (context, _, __) {
        if (!controller.hasSubmittedCurrentAnswer) {
          return const SizedBox.shrink();
        }

        final exercise = controller.currentExercise;
        final selected = controller.selectedOptionNotifier.value;
        if (exercise == null || selected == null) {
          return const SizedBox.shrink();
        }

        final isCorrect = selected == exercise.correctOptionIndex;
        final language = controller.practiceLanguageNotifier.value;
        final options = exercise.optionsFor(language);

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCorrect
                ? Colors.green.withOpacity(0.15)
                : Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCorrect ? Colors.green.shade300 : Colors.red.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green.shade300 : Colors.red.shade300,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCorrect
                      ? appText(context, en: 'Correct!', pt: 'Correto!')
                      : appText(
                          context,
                          en: 'Wrong. The correct answer is: ${options[exercise.correctOptionIndex]}',
                          pt: 'Errado. A resposta correta e: ${options[exercise.correctOptionIndex]}',
                        ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        isCorrect ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return ValueListenableBuilder<List<int?>>(
      valueListenable: controller.submittedAnswersNotifier,
      builder: (context, _, __) {
        final submitted = controller.hasSubmittedCurrentAnswer;
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: submitted
                    ? null
                    : () {
                        final didSubmit = controller.submitAnswer();
                        if (!didSubmit && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                appText(
                                  context,
                                  en: 'Select one option before confirming.',
                                  pt: 'Selecione uma opcao antes de confirmar.',
                                ),
                              ),
                            ),
                          );
                        }
                      },
                child: Text(
                  appText(
                    context,
                    en: 'Confirm answer',
                    pt: 'Confirmar resposta',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: submitted ? controller.moveToNext : null,
                child: Text(
                  appText(context, en: 'Next', pt: 'Proximo'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appText(context, en: 'Session completed', pt: 'Sessao concluida'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<String?>(
            valueListenable: controller.sessionSummaryNotifier,
            builder: (context, summary, _) {
              return Text(summary ?? '');
            },
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: controller.isSavingNotifier,
            builder: (context, saving, _) {
              return FilledButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        final didSave = await controller.saveSession();
                        if (!context.mounted) {
                          return;
                        }

                        final text = didSave
                            ? appText(
                                context,
                                en: 'Learning session saved in your history.',
                                pt: 'Sessao de aprendizado salva no historico.',
                              )
                            : appText(
                                context,
                                en: 'Session was already saved or no exercises were completed.',
                                pt: 'A sessao ja foi salva ou nao houve exercicios concluidos.',
                              );

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(text)));
                      },
                icon: Icon(
                  saving ? Icons.hourglass_top_outlined : Icons.save_outlined,
                ),
                label: Text(
                  saving
                      ? appText(context, en: 'Saving...', pt: 'Salvando...')
                      : appText(
                          context,
                          en: 'Save learning session',
                          pt: 'Salvar sessao de aprendizado',
                        ),
                ),
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: controller.suggestIntermediateNotifier,
            builder: (context, suggest, _) {
              if (!suggest) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up,
                            size: 20, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          appText(
                            context,
                            en: 'Ready for the next level!',
                            pt: 'Pronto para o proximo nivel!',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      appText(
                        context,
                        en: 'You scored 80%+ in beginner across multiple sessions. Try Intermediate!',
                        pt: 'Voce acertou 80%+ no iniciante em varias sessoes. Experimente o Intermediario!',
                      ),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        controller.setDifficultyFilter(
                          ReadingListeningDifficultyFilter.intermediate,
                        );
                      },
                      icon: const Icon(Icons.arrow_upward),
                      label: Text(
                        appText(
                          context,
                          en: 'Switch to Intermediate',
                          pt: 'Mudar para Intermediario',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _difficultyLabel(
    BuildContext context,
    ReadingListeningDifficultyFilter filter,
  ) {
    switch (filter) {
      case ReadingListeningDifficultyFilter.all:
        return appText(context, en: 'All', pt: 'Todos');
      case ReadingListeningDifficultyFilter.beginner:
        return appText(context, en: 'Beginner', pt: 'Iniciante');
      case ReadingListeningDifficultyFilter.intermediate:
        return appText(context, en: 'Intermediate', pt: 'Intermediario');
      case ReadingListeningDifficultyFilter.advanced:
        return appText(context, en: 'Advanced', pt: 'Avancado');
    }
  }

  Widget _buildPronunciationResult(BuildContext context) {
    return ValueListenableBuilder<PronunciationResult?>(
      valueListenable: controller.pronunciationResultNotifier,
      builder: (context, result, _) {
        if (result == null) {
          return const SizedBox.shrink();
        }

        final accuracy = result.accuracyPercent;
        final color = accuracy >= 80
            ? Colors.green.shade300
            : accuracy >= 50
                ? Colors.orange.shade300
                : Colors.red.shade300;

        return Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.record_voice_over, size: 18, color: color),
                  const SizedBox(width: 6),
                  Text(
                    appText(
                      context,
                      en: 'Pronunciation: $accuracy%',
                      pt: 'Pronuncia: $accuracy%',
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: controller.clearPronunciationResult,
                    child: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: result.wordMatches.map((match) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: match.matched
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      match.expected,
                      style: TextStyle(
                        color: match.matched
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                        fontWeight:
                            match.matched ? FontWeight.w400 : FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              Text(
                appText(
                  context,
                  en: 'You said: "${result.spokenText}"',
                  pt: 'Voce disse: "${result.spokenText}"',
                ),
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        );
      },
    );
  }
}
