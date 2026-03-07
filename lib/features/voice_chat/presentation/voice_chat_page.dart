import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';

import '../application/app_feature_flags.dart';
import '../application/practice_hub_controller.dart';
import '../application/session_history_service.dart';
import '../application/voice_chat_session_config.dart';
import '../application/voice_chat_controller.dart';
import '../domain/entities/ai_provider.dart';
import '../domain/entities/conversation_language.dart';
import '../domain/entities/session_scene.dart';
import '../domain/entities/session_ui_preferences.dart';
import '../infrastructure/ai/ai_service.dart';
import '../infrastructure/local/local_session_history_repository.dart';
import '../infrastructure/local/local_user_preferences_repository.dart';
import '../infrastructure/speech/speech_service.dart';
import '../infrastructure/tts/tts_service.dart';
import 'app_text.dart';
import 'practice_hub_sheet.dart';
import 'responsive_content_shell.dart';

class VoiceChatPage extends StatefulWidget {
  final String? startupHint;

  const VoiceChatPage({Key? key, this.startupHint}) : super(key: key);

  @override
  State<VoiceChatPage> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage> {
  late final VoiceChatController controller;
  late final PracticeHubController practiceHubController;
  late final VoiceChatSessionConfig sessionConfig;
  final TextEditingController _pendingInputTextController =
      TextEditingController();
  final FocusNode _pendingInputFocusNode = FocusNode();
  final LocalUserPreferencesRepository _preferencesRepository =
      LocalUserPreferencesRepository();
  final ValueNotifier<SessionScene> _selectedSceneNotifier =
      ValueNotifier<SessionScene>(SessionScene.studio);
  static const List<String> _focusOptions = [
    'General conversation',
    'Travel English',
    'Job interview',
    'Daily routine',
    'Restaurant and shopping',
  ];

  AIService _buildAiServiceFromEnv() {
    final provider = AiProviderX.fromEnv(dotenv.env['AI_PROVIDER']);
    switch (provider) {
      case AiProvider.gemini:
        return GeminiService();
      case AiProvider.openai:
        return OpenAIService();
    }
  }

  AIService _buildAiServiceFromPreferences(SessionUiPreferences preferences) {
    switch (preferences.aiProvider) {
      case AiProvider.gemini:
        return GeminiService(modelOverride: preferences.geminiModel);
      case AiProvider.openai:
        return OpenAIService(modelOverride: preferences.openAiModel);
    }
  }

  @override
  void initState() {
    super.initState();
    sessionConfig = VoiceChatSessionConfig.fromEnv(dotenv.env);
    final featureFlags = AppFeatureFlags.fromEnv(dotenv.env);
    final historyRepository = LocalSessionHistoryRepository();

    practiceHubController = PracticeHubController(
      repository: historyRepository,
      historyService: SessionHistoryService(),
      featureFlags: featureFlags,
    );

    controller = VoiceChatController(
      aiService: _buildAiServiceFromEnv(),
      sessionHistoryRepository: historyRepository,
      speechService: SpeechService(
        listenFor: sessionConfig.sttListenFor,
        pauseFor: sessionConfig.sttPauseFor,
      ),
      ttsService: TTSService(),
      maxSilentTurnsBeforePause: sessionConfig.maxSilentTurnsBeforePause,
      loopDelay: sessionConfig.loopDelay,
      pausedPollDelay: sessionConfig.pausedPollDelay,
      resumeGracePeriod: sessionConfig.resumeGracePeriod,
    );
    _initializeConversation();
    practiceHubController.load();
  }

  @override
  void dispose() {
    _pendingInputFocusNode.dispose();
    _pendingInputTextController.dispose();
    _selectedSceneNotifier.dispose();
    controller.dispose();
    practiceHubController.dispose();
    super.dispose();
  }

  Future<void> _initializeConversation() async {
    final preferredLanguage =
        await _preferencesRepository.getPreferredLanguage();
    final sessionPrefs = await _preferencesRepository.getSessionUiPreferences();
    if (!mounted) return;

    controller.updateAiService(_buildAiServiceFromPreferences(sessionPrefs));
    _applySessionPreferences(sessionPrefs);
    controller.setRequireInputReview(sessionPrefs.reviewBeforeSend);
    controller.setPreferredLanguage(preferredLanguage);
    await controller.configureInitialSpeechSpeedMultiplier(
      sessionConfig.defaultSpeechSpeedMultiplier,
    );
    await controller.startConversation();

    _showStartupHintIfNeeded(sessionPrefs);
  }

  void _applySessionPreferences(SessionUiPreferences preferences) {
    controller.setAutoResumeListening(preferences.autoResumeListening);
    _selectedSceneNotifier.value = preferences.selectedScene;
  }

  void _showStartupHintIfNeeded(SessionUiPreferences preferences) {
    if (!preferences.showStartupTips) {
      return;
    }

    final hint = widget.startupHint ??
        appText(
          context,
          en: 'Tip: choose your language and focus before speaking.',
          pt: 'Dica: escolha seu idioma e foco antes de falar.',
        );

    if (hint.trim().isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hint)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isCompactHeight = viewportHeight < 840;
    final showStatsPanel = !isCompactHeight;
    final avatarHeight = isCompactHeight ? 180.0 : 220.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appText(
            context,
            en: 'Voice Avatar (EN-US / PT-BR)',
            pt: 'Avatar de Voz (EN-US / PT-BR)',
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                appText(context, en: 'Practice hub', pt: 'Central de pratica'),
            icon: const Icon(Icons.insights_outlined),
            onPressed: () async {
              await practiceHubController.load();
              if (!context.mounted) return;
              await showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: const Color(0xFF1B1E23),
                builder: (_) => FractionallySizedBox(
                  heightFactor: 0.9,
                  child: PracticeHubSheet(controller: practiceHubController),
                ),
              );
            },
          ),
          IconButton(
            tooltip: appText(
              context,
              en: 'Speech speed',
              pt: 'Velocidade da fala',
            ),
            icon: const Icon(Icons.speed_outlined),
            onPressed: _openSpeechSpeedSheet,
          ),
          ValueListenableBuilder<ConversationLanguage>(
            valueListenable: controller.languageNotifier,
            builder: (context, selected, _) {
              return DropdownButtonHideUnderline(
                child: DropdownButton<ConversationLanguage>(
                  value: selected,
                  onChanged: (value) {
                    if (value == null) return;
                    controller.setPreferredLanguage(value);
                    _preferencesRepository.savePreferredLanguage(value);
                  },
                  items: ConversationLanguage.values
                      .map(
                        (lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(lang.label),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ValueListenableBuilder<SessionScene>(
        valueListenable: _selectedSceneNotifier,
        builder: (context, selectedScene, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildSceneBackground(selectedScene),
              ResponsiveContentShell.premium(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: keyboardInset),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: ValueListenableBuilder<String>(
                          valueListenable: controller.practiceFocusNotifier,
                          builder: (context, selectedFocus, _) {
                            return DropdownButtonFormField<String>(
                              key: ValueKey<String>(selectedFocus),
                              initialValue: selectedFocus,
                              decoration: InputDecoration(
                                labelText: appText(context,
                                    en: 'Practice focus',
                                    pt: 'Foco da pratica'),
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: _focusOptions
                                  .map(
                                    (focus) => DropdownMenuItem(
                                        value: focus, child: Text(focus)),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                controller.setPracticeFocus(value);
                              },
                            );
                          },
                        ),
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: controller.lottieAssetNotifier,
                        builder: (context, lottieAsset, _) => SizedBox(
                          height: avatarHeight,
                          child: Lottie.asset(lottieAsset),
                        ),
                      ),
                      if (showStatsPanel)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: ValueListenableBuilder<int>(
                                  valueListenable: controller.userTurnsNotifier,
                                  builder: (context, turns, _) => _StatCard(
                                      label: appText(context,
                                          en: 'Your turns', pt: 'Seus turnos'),
                                      value: '$turns'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ValueListenableBuilder<int>(
                                  valueListenable:
                                      controller.elapsedSecondsNotifier,
                                  builder: (context, seconds, _) => _StatCard(
                                    label: appText(context,
                                        en: 'Session time',
                                        pt: 'Tempo da sessao'),
                                    value: _formatDuration(seconds),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.24),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child:
                              ValueListenableBuilder<List<Map<String, String>>>(
                            valueListenable: controller.conversation,
                            builder: (context, conversation, _) {
                              return ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                itemCount: conversation.length,
                                itemBuilder: (_, i) {
                                  final msg = conversation[i];
                                  final isUser = msg['role'] == 'user';
                                  return Container(
                                    alignment: isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isUser
                                            ? Colors.blueAccent
                                            : Colors.grey[850],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        msg['content'] ?? '',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: controller.statusNotifier,
                        builder: (context, status, _) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: controller.isInResumeGraceNotifier,
                        builder: (context, inGrace, _) {
                          if (!inGrace) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                appText(
                                  context,
                                  en: 'Listening resumed. Silent timeout is briefly relaxed.',
                                  pt: 'Escuta retomada. O tempo de silencio foi relaxado por um instante.',
                                ),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white70),
                              ),
                            ),
                          );
                        },
                      ),
                      ValueListenableBuilder<String?>(
                        valueListenable: controller.sessionFeedbackNotifier,
                        builder: (context, feedback, _) {
                          if (feedback == null || feedback.trim().isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.4),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(feedback,
                                style: const TextStyle(fontSize: 14)),
                          );
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable:
                            controller.isReviewingUserInputNotifier,
                        builder: (context, isReviewing, _) {
                          if (!isReviewing) {
                            return const SizedBox.shrink();
                          }

                          return ValueListenableBuilder<String>(
                            valueListenable:
                                controller.pendingUserInputNotifier,
                            builder: (context, pendingInput, _) {
                              if (_pendingInputTextController.text !=
                                  pendingInput) {
                                _pendingInputTextController.value =
                                    TextEditingValue(
                                  text: pendingInput,
                                  selection: TextSelection.collapsed(
                                    offset: pendingInput.length,
                                  ),
                                );
                              }

                              return Container(
                                width: double.infinity,
                                margin:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appText(
                                        context,
                                        en: 'Edit and resend',
                                        pt: 'Editar e reenviar',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _pendingInputTextController,
                                      focusNode: _pendingInputFocusNode,
                                      minLines: 1,
                                      maxLines: 3,
                                      onChanged:
                                          controller.updatePendingUserInput,
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        hintText: appText(
                                          context,
                                          en: 'Edit the message and resend',
                                          pt: 'Edite a mensagem e reenvie',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed:
                                                controller.dismissReviewPanel,
                                            icon: const Icon(Icons.close),
                                            label: Text(
                                              appText(
                                                context,
                                                en: 'Dismiss',
                                                pt: 'Dispensar',
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => controller
                                                .confirmPendingUserInput(),
                                            icon: const Icon(Icons.send),
                                            label: Text(
                                              appText(
                                                context,
                                                en: 'Resend',
                                                pt: 'Reenviar',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: controller.isPausedNotifier,
                        builder: (context, isPaused, _) {
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                                16, 0, 16, isCompactHeight ? 10 : 18),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isPaused
                                        ? controller.resumeConversation
                                        : () => controller.pauseConversation(),
                                    icon: Icon(
                                        isPaused ? Icons.mic : Icons.pause),
                                    label: Text(
                                      isPaused
                                          ? appText(context,
                                              en: 'Resume conversation',
                                              pt: 'Retomar conversa')
                                          : appText(context,
                                              en: 'Pause', pt: 'Pausar'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable:
                                        controller.isGeneratingFeedbackNotifier,
                                    builder: (context, generating, _) {
                                      return ElevatedButton.icon(
                                        onPressed: generating
                                            ? null
                                            : () async {
                                                await controller
                                                    .endSessionWithFeedback();
                                                await practiceHubController
                                                    .refreshAfterSession();
                                              },
                                        icon: Icon(
                                          generating
                                              ? Icons.hourglass_top
                                              : Icons.assessment_outlined,
                                        ),
                                        label: Text(
                                          generating
                                              ? appText(context,
                                                  en: 'Generating...',
                                                  pt: 'Gerando...')
                                              : appText(context,
                                                  en: 'Session feedback',
                                                  pt: 'Feedback da sessao'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSceneBackground(SessionScene scene) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          scene.assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF17202A),
                    Color(0xFF1F2F3F),
                    Color(0xFF213E45)
                  ],
                ),
              ),
            );
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.black.withValues(alpha: 0.62),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  void _openSpeechSpeedSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B1E23),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
            child: _buildSpeechSpeedPicker(),
          ),
        );
      },
    );
  }

  Widget _buildSpeechSpeedPicker() {
    const options = <double>[0.5, 1.0, 1.5, 2.0];

    return ValueListenableBuilder<double>(
      valueListenable: controller.speechSpeedMultiplierNotifier,
      builder: (context, selected, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appText(
                context,
                en: 'Speech speed',
                pt: 'Velocidade da fala',
              ),
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final hasTwoDecimals = (option * 100).round() % 10 != 0;
                final precision = hasTwoDecimals ? 2 : 1;
                final label = '${option.toStringAsFixed(precision)}x';
                return ChoiceChip(
                  label: Text(label),
                  selected: selected == option,
                  onSelected: (_) async {
                    await controller.setSpeechSpeedMultiplier(
                      option,
                      language: controller.languageNotifier.value ==
                              ConversationLanguage.auto
                          ? ConversationLanguage.englishUs
                          : controller.languageNotifier.value,
                      origin: 'manual',
                    );
                  },
                );
              }).toList(growable: false),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
