import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();

  TTSService() {
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.6);
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }
}
