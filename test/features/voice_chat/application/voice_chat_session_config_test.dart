import 'package:english_voice_ai_clean/features/voice_chat/application/voice_chat_session_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceChatSessionConfig', () {
    test('reads valid values from environment map', () {
      final config = VoiceChatSessionConfig.fromEnv({
        'VOICE_CHAT_STT_LISTEN_SECONDS': '12',
        'VOICE_CHAT_STT_PAUSE_SECONDS': '4',
        'VOICE_CHAT_MAX_SILENT_TURNS': '3',
        'VOICE_CHAT_LOOP_DELAY_MS': '300',
        'VOICE_CHAT_PAUSED_POLL_MS': '150',
        'VOICE_CHAT_RESUME_GRACE_MS': '1800',
        'VOICE_CHAT_DEFAULT_SPEECH_SPEED_X': '1.5',
      });

      expect(config.sttListenFor, const Duration(seconds: 12));
      expect(config.sttPauseFor, const Duration(seconds: 4));
      expect(config.maxSilentTurnsBeforePause, 3);
      expect(config.loopDelay, const Duration(milliseconds: 300));
      expect(config.pausedPollDelay, const Duration(milliseconds: 150));
      expect(config.resumeGracePeriod, const Duration(milliseconds: 1800));
      expect(config.defaultSpeechSpeedMultiplier, 1.5);
    });

    test('falls back to defaults for invalid values', () {
      final config = VoiceChatSessionConfig.fromEnv({
        'VOICE_CHAT_STT_LISTEN_SECONDS': '-1',
        'VOICE_CHAT_STT_PAUSE_SECONDS': 'abc',
        'VOICE_CHAT_MAX_SILENT_TURNS': '0',
        'VOICE_CHAT_LOOP_DELAY_MS': '',
        'VOICE_CHAT_PAUSED_POLL_MS': '-300',
        'VOICE_CHAT_RESUME_GRACE_MS': '0',
        'VOICE_CHAT_DEFAULT_SPEECH_SPEED_X': '-5',
      });

      expect(config.sttListenFor, const Duration(seconds: 10));
      expect(config.sttPauseFor, const Duration(seconds: 3));
      expect(config.maxSilentTurnsBeforePause, 2);
      expect(config.loopDelay, const Duration(milliseconds: 250));
      expect(config.pausedPollDelay, const Duration(milliseconds: 250));
      expect(config.resumeGracePeriod, const Duration(seconds: 2));
      expect(config.defaultSpeechSpeedMultiplier, 1.0);
    });
  });
}
