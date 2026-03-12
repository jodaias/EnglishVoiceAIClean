import 'ai_provider.dart';
import 'session_scene.dart';

class SessionUiPreferences {
  final bool autoResumeListening;
  final bool showStartupTips;
  final bool reviewBeforeSend;
  final SessionScene selectedScene;
  final AiProvider aiProvider;
  final bool useCustomAiModel;
  final String geminiModel;
  final String openAiModel;

  const SessionUiPreferences({
    required this.autoResumeListening,
    required this.showStartupTips,
    required this.reviewBeforeSend,
    required this.selectedScene,
    required this.aiProvider,
    required this.useCustomAiModel,
    required this.geminiModel,
    required this.openAiModel,
  });

  const SessionUiPreferences.defaults()
      : autoResumeListening = true,
        showStartupTips = true,
        reviewBeforeSend = false,
        selectedScene = SessionScene.studio,
        aiProvider = AiProvider.gemini,
        useCustomAiModel = false,
        geminiModel = 'gemini-2.5-flash',
        openAiModel = 'gpt-4.1';

  SessionUiPreferences copyWith({
    bool? autoResumeListening,
    bool? showStartupTips,
    bool? reviewBeforeSend,
    SessionScene? selectedScene,
    AiProvider? aiProvider,
    bool? useCustomAiModel,
    String? geminiModel,
    String? openAiModel,
  }) {
    return SessionUiPreferences(
      autoResumeListening: autoResumeListening ?? this.autoResumeListening,
      showStartupTips: showStartupTips ?? this.showStartupTips,
      reviewBeforeSend: reviewBeforeSend ?? this.reviewBeforeSend,
      selectedScene: selectedScene ?? this.selectedScene,
      aiProvider: aiProvider ?? this.aiProvider,
      useCustomAiModel: useCustomAiModel ?? this.useCustomAiModel,
      geminiModel: geminiModel ?? this.geminiModel,
      openAiModel: openAiModel ?? this.openAiModel,
    );
  }
}
