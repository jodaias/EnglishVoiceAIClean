import 'session_scene.dart';

class SessionUiPreferences {
  final bool autoResumeListening;
  final bool showStartupTips;
  final SessionScene selectedScene;

  const SessionUiPreferences({
    required this.autoResumeListening,
    required this.showStartupTips,
    required this.selectedScene,
  });

  const SessionUiPreferences.defaults()
      : autoResumeListening = true,
        showStartupTips = true,
        selectedScene = SessionScene.studio;

  SessionUiPreferences copyWith({
    bool? autoResumeListening,
    bool? showStartupTips,
    SessionScene? selectedScene,
  }) {
    return SessionUiPreferences(
      autoResumeListening: autoResumeListening ?? this.autoResumeListening,
      showStartupTips: showStartupTips ?? this.showStartupTips,
      selectedScene: selectedScene ?? this.selectedScene,
    );
  }
}
