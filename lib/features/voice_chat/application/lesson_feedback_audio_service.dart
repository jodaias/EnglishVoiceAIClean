abstract class LessonFeedbackAudioService {
  Future<void> playCorrect();
  Future<void> playWrong();
  Future<void> playComplete();
  Future<void> dispose();
}
