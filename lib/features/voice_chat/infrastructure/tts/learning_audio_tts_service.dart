import '../../application/learning_audio_service.dart';
import 'tts_service.dart';

class LearningAudioTtsService implements LearningAudioService {
  final TTSService ttsService;

  LearningAudioTtsService({required this.ttsService});

  @override
  Future<void> speak(String text, {required String locale}) {
    return ttsService.speak(text, locale: locale);
  }

  @override
  Future<void> stop() {
    return ttsService.stop();
  }
}
