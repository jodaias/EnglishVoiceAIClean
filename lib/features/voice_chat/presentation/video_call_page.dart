import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';

import '../application/voice_chat_session_config.dart';
import '../application/voice_chat_controller.dart';
import '../domain/entities/ai_provider.dart';
import '../domain/entities/conversation_language.dart';
import '../domain/entities/session_ui_preferences.dart';
import '../infrastructure/ai/ai_service.dart';
import '../infrastructure/local/local_session_history_repository.dart';
import '../infrastructure/local/local_user_preferences_repository.dart';
import '../infrastructure/speech/speech_service.dart';
import '../infrastructure/tts/tts_service.dart';
import 'app_text.dart';

/// A voice conversation screen styled as a video call.
///
/// Reuses [VoiceChatController] for the STT → AI → TTS loop but presents
/// the avatar full-screen with floating controls and caption-style messages.
class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage>
    with SingleTickerProviderStateMixin {
  late final VoiceChatController controller;
  late final VoiceChatSessionConfig sessionConfig;
  final LocalUserPreferencesRepository _preferencesRepository =
      LocalUserPreferencesRepository();

  late final AnimationController _pulseController;

  bool _showCaptions = true;

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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    sessionConfig = VoiceChatSessionConfig.fromEnv(dotenv.env);
    final historyRepository = LocalSessionHistoryRepository();

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
  }

  Future<void> _initializeConversation() async {
    final preferredLanguage =
        await _preferencesRepository.getPreferredLanguage();
    final sessionPrefs = await _preferencesRepository.getSessionUiPreferences();
    if (!mounted) return;

    controller.updateAiService(_buildAiServiceFromPreferences(sessionPrefs));
    controller.setAutoResumeListening(sessionPrefs.autoResumeListening);
    controller.setPreferredLanguage(preferredLanguage);
    await controller.configureInitialSpeechSpeedMultiplier(
      sessionConfig.defaultSpeechSpeedMultiplier,
    );
    await controller.startConversation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1 — scene background
          _buildBackground(),

          // Layer 2 — full-screen avatar (the "other person's video")
          _buildAvatarArea(),

          // Layer 3 — top bar (call info + back)
          _buildTopBar(),

          // Layer 4 — captions overlay
          if (_showCaptions) _buildCaptionsOverlay(),

          // Layer 5 — self-view indicator (mic status)
          _buildSelfView(),

          // Layer 6 — bottom floating controls
          _buildControls(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Background
  // ---------------------------------------------------------------------------

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D1117),
            Color(0xFF161B22),
            Color(0xFF0D1117),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Avatar (full-screen, centered)
  // ---------------------------------------------------------------------------

  Widget _buildAvatarArea() {
    return ValueListenableBuilder<String>(
      valueListenable: controller.lottieAssetNotifier,
      builder: (context, lottieAsset, _) {
        final isTalking = lottieAsset.contains('talking');

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar glow ring when talking
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isTalking
                      ? [
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Lottie.asset(lottieAsset, fit: BoxFit.contain),
                ),
              ),

              const SizedBox(height: 16),

              // Status label under avatar
              ValueListenableBuilder<String>(
                valueListenable: controller.statusNotifier,
                builder: (context, status, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      status,
                      key: ValueKey(status),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar — call timer, language, back button
  // ---------------------------------------------------------------------------

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 16,
          right: 16,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),

            const SizedBox(width: 8),

            // Call label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    appText(context,
                        en: 'AI Video Call', pt: 'Videochamada IA'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<int>(
                    valueListenable: controller.elapsedSecondsNotifier,
                    builder: (context, seconds, _) {
                      return Text(
                        _formatDuration(seconds),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Language selector (compact)
            ValueListenableBuilder<ConversationLanguage>(
              valueListenable: controller.languageNotifier,
              builder: (context, selected, _) {
                return PopupMenuButton<ConversationLanguage>(
                  initialValue: selected,
                  onSelected: (value) {
                    controller.setPreferredLanguage(value);
                    _preferencesRepository.savePreferredLanguage(value);
                  },
                  icon: const Icon(Icons.language, color: Colors.white),
                  itemBuilder: (_) => ConversationLanguage.values
                      .map(
                        (lang) => PopupMenuItem(
                          value: lang,
                          child: Text(lang.label),
                        ),
                      )
                      .toList(),
                );
              },
            ),

            // Focus selector
            PopupMenuButton<String>(
              icon: const Icon(Icons.tune, color: Colors.white),
              onSelected: (value) => controller.setPracticeFocus(value),
              itemBuilder: (_) => _focusOptions
                  .map((f) => PopupMenuItem(value: f, child: Text(f)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Captions overlay — last messages shown like subtitles
  // ---------------------------------------------------------------------------

  Widget _buildCaptionsOverlay() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 140,
      child: ValueListenableBuilder<List<Map<String, String>>>(
        valueListenable: controller.conversation,
        builder: (context, conversation, _) {
          if (conversation.isEmpty) return const SizedBox.shrink();

          // Show last 2 messages as captions
          final captions = conversation.length > 2
              ? conversation.sublist(conversation.length - 2)
              : conversation;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: captions.map((msg) {
              final isUser = msg['role'] == 'user';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blueAccent.withValues(alpha: 0.75)
                          : Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg['content'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Self-view — small mic/listening indicator (like your own camera preview)
  // ---------------------------------------------------------------------------

  Widget _buildSelfView() {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 70,
      right: 16,
      child: ValueListenableBuilder<bool>(
        valueListenable: controller.isPausedNotifier,
        builder: (context, isPaused, _) {
          return ValueListenableBuilder<String>(
            valueListenable: controller.lottieAssetNotifier,
            builder: (context, lottieAsset, _) {
              final isTalking = lottieAsset.contains('talking');
              final isListening = !isPaused && !isTalking;

              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale =
                      isListening ? 1.0 + (_pulseController.value * 0.08) : 1.0;
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPaused
                        ? Colors.red.withValues(alpha: 0.7)
                        : isListening
                            ? Colors.green.withValues(alpha: 0.7)
                            : Colors.blueAccent.withValues(alpha: 0.5),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isPaused
                        ? Icons.mic_off
                        : isListening
                            ? Icons.mic
                            : Icons.volume_up,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom controls — video-call style action bar
  // ---------------------------------------------------------------------------

  Widget _buildControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.paddingOf(context).bottom + 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Toggle captions
            _ControlButton(
              icon: _showCaptions
                  ? Icons.closed_caption
                  : Icons.closed_caption_disabled,
              label: appText(context, en: 'Captions', pt: 'Legendas'),
              onTap: () => setState(() => _showCaptions = !_showCaptions),
              isActive: _showCaptions,
            ),

            // Pause / Resume
            ValueListenableBuilder<bool>(
              valueListenable: controller.isPausedNotifier,
              builder: (context, isPaused, _) {
                return _ControlButton(
                  icon: isPaused ? Icons.mic_off : Icons.mic,
                  label: isPaused
                      ? appText(context, en: 'Unmute', pt: 'Ativar mic')
                      : appText(context, en: 'Mute', pt: 'Mudo'),
                  onTap: isPaused
                      ? controller.resumeConversation
                      : () => controller.pauseConversation(),
                  isActive: !isPaused,
                  activeColor: isPaused ? Colors.red : null,
                );
              },
            ),

            // End call
            _ControlButton(
              icon: Icons.call_end,
              label: appText(context, en: 'End', pt: 'Encerrar'),
              onTap: () async {
                await controller.endSessionWithFeedback();
                if (mounted) Navigator.of(context).pop();
              },
              isActive: false,
              activeColor: Colors.red,
              isDestructive: true,
            ),

            // Speech speed
            _ControlButton(
              icon: Icons.speed,
              label: appText(context, en: 'Speed', pt: 'Velocidade'),
              onTap: _openSpeechSpeedSheet,
            ),

            // Session feedback (without ending)
            ValueListenableBuilder<bool>(
              valueListenable: controller.isGeneratingFeedbackNotifier,
              builder: (context, generating, _) {
                return _ControlButton(
                  icon: generating
                      ? Icons.hourglass_top
                      : Icons.assessment_outlined,
                  label: appText(context, en: 'Feedback', pt: 'Feedback'),
                  onTap: generating
                      ? null
                      : () => controller.endSessionWithFeedback(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Speech speed bottom sheet
  // ---------------------------------------------------------------------------

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
              appText(context, en: 'Speech speed', pt: 'Velocidade da fala'),
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

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }
}

// =============================================================================
// Control button widget (video-call style circular button)
// =============================================================================

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final Color? activeColor;
  final bool isDestructive;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
    this.activeColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDestructive
        ? Colors.red
        : activeColor ??
            (isActive
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.08));

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
