class SessionUiPreferences {
  final bool autoResumeListening;
  final bool showStartupTips;

  const SessionUiPreferences({
    required this.autoResumeListening,
    required this.showStartupTips,
  });

  const SessionUiPreferences.defaults()
      : autoResumeListening = true,
        showStartupTips = true;

  SessionUiPreferences copyWith({
    bool? autoResumeListening,
    bool? showStartupTips,
  }) {
    return SessionUiPreferences(
      autoResumeListening: autoResumeListening ?? this.autoResumeListening,
      showStartupTips: showStartupTips ?? this.showStartupTips,
    );
  }
}
