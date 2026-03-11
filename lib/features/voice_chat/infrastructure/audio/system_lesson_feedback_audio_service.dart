import 'package:flutter/services.dart';

import '../../application/lesson_feedback_audio_service.dart';

class SystemLessonFeedbackAudioService implements LessonFeedbackAudioService {
  @override
  Future<void> playCorrect() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  @override
  Future<void> playWrong() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  @override
  Future<void> playComplete() async {
    try {
      await SystemSound.play(SystemSoundType.click);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {}
}
