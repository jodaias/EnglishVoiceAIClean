import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();

  TTSService() {
    _tts.setSpeechRate(0.5);
    _tts.setLanguage('en-US');
  }

  Future<void> speak(String text, {required String locale}) async {
    await _tts.setLanguage(locale);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }
}
