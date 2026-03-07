abstract class LearningAudioService {
  Future<void> speak(
    String text, {
    required String locale,
  });

  Future<void> stop();
}
