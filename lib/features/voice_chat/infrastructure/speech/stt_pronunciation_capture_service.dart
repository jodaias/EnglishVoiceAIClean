import '../../application/pronunciation_capture_service.dart';
import 'speech_service.dart';

class SttPronunciationCaptureService implements PronunciationCaptureService {
  final SpeechService speechService;

  SttPronunciationCaptureService({required this.speechService});

  @override
  Future<String?> captureUserSpeech({required String localeId}) {
    return speechService.listen(isSpeaking: false, localeId: localeId);
  }
}
