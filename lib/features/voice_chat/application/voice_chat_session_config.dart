class VoiceChatSessionConfig {
  final Duration sttListenFor;
  final Duration sttPauseFor;
  final int maxSilentTurnsBeforePause;
  final Duration loopDelay;
  final Duration pausedPollDelay;
  final Duration resumeGracePeriod;
  final double defaultSpeechSpeedMultiplier;

  const VoiceChatSessionConfig({
    this.sttListenFor = const Duration(seconds: 10),
    this.sttPauseFor = const Duration(seconds: 3),
    this.maxSilentTurnsBeforePause = 2,
    this.loopDelay = const Duration(milliseconds: 250),
    this.pausedPollDelay = const Duration(milliseconds: 250),
    this.resumeGracePeriod = const Duration(seconds: 2),
    this.defaultSpeechSpeedMultiplier = 1.0,
  });

  factory VoiceChatSessionConfig.fromEnv(Map<String, String> env) {
    final sttListenSeconds = _parsePositiveInt(
      env['VOICE_CHAT_STT_LISTEN_SECONDS'],
      fallback: 10,
    );
    final sttPauseSeconds = _parsePositiveInt(
      env['VOICE_CHAT_STT_PAUSE_SECONDS'],
      fallback: 3,
    );
    final maxSilentTurns = _parsePositiveInt(
      env['VOICE_CHAT_MAX_SILENT_TURNS'],
      fallback: 2,
    );
    final loopDelayMs = _parsePositiveInt(
      env['VOICE_CHAT_LOOP_DELAY_MS'],
      fallback: 250,
    );
    final pausedPollMs = _parsePositiveInt(
      env['VOICE_CHAT_PAUSED_POLL_MS'],
      fallback: 250,
    );
    final resumeGraceMs = _parsePositiveInt(
      env['VOICE_CHAT_RESUME_GRACE_MS'],
      fallback: 2000,
    );
    final defaultSpeechSpeedMultiplier = _parsePositiveDouble(
      env['VOICE_CHAT_DEFAULT_SPEECH_SPEED_X'],
      fallback: 1.0,
    );

    return VoiceChatSessionConfig(
      sttListenFor: Duration(seconds: sttListenSeconds),
      sttPauseFor: Duration(seconds: sttPauseSeconds),
      maxSilentTurnsBeforePause: maxSilentTurns,
      loopDelay: Duration(milliseconds: loopDelayMs),
      pausedPollDelay: Duration(milliseconds: pausedPollMs),
      resumeGracePeriod: Duration(milliseconds: resumeGraceMs),
      defaultSpeechSpeedMultiplier: defaultSpeechSpeedMultiplier,
    );
  }

  static int _parsePositiveInt(String? rawValue, {required int fallback}) {
    final value = int.tryParse((rawValue ?? '').trim());
    if (value == null || value <= 0) {
      return fallback;
    }
    return value;
  }

  static double _parsePositiveDouble(String? rawValue,
      {required double fallback}) {
    final normalized = (rawValue ?? '').trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) {
      return fallback;
    }
    return value;
  }
}
