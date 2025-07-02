import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<String?> listen({required bool isSpeaking}) async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );

    if (!available) {
      print("Speech recognition not available");
      return null;
    }

    String spokenText = '';

    await _speech.listen(
      onResult: (result) {
        spokenText = result.recognizedWords;
        print('Recognized: $spokenText');
        print('Main recognized: ${result.recognizedWords}');
        for (var alt in result.alternates) {
          print('Alternate: ${alt.recognizedWords}');
        }
      },
      listenFor: Duration(seconds: 10),
      pauseFor: Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
      localeId: 'en_US',
    );

    // Wait until the speech recognition is done
    while (_speech.isListening) {
      await Future.delayed(Duration(milliseconds: 200));
    }

    await _speech.stop();

    return spokenText.isNotEmpty ? spokenText : null;
  }
}
