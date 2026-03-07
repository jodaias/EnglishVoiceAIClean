import 'package:speech_to_text/speech_to_text.dart' as stt;

abstract class SpeechRecognizerAdapter {
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(Object error) onError,
  });

  Future<void> listen({
    required void Function(String recognizedWords) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String localeId,
  });

  Future<void> stop();

  bool get isListening;
}

class SpeechToTextAdapter implements SpeechRecognizerAdapter {
  final stt.SpeechToText _speech;

  SpeechToTextAdapter({stt.SpeechToText? speech})
      : _speech = speech ?? stt.SpeechToText();

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(Object error) onError,
  }) {
    return _speech.initialize(
      onStatus: onStatus,
      onError: onError,
    );
  }

  @override
  Future<void> listen({
    required void Function(String recognizedWords) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String localeId,
  }) {
    return _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenFor: listenFor,
      pauseFor: pauseFor,
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
      localeId: localeId,
    );
  }

  @override
  Future<void> stop() {
    return _speech.stop();
  }

  @override
  bool get isListening => _speech.isListening;
}

class SpeechService {
  final SpeechRecognizerAdapter _recognizer;
  final Duration listenFor;
  final Duration pauseFor;
  final Duration retryDelay;
  bool _isListenInFlight = false;
  int _sttStartFailureCount = 0;

  int get sttStartFailureCount => _sttStartFailureCount;

  SpeechService({
    this.listenFor = const Duration(seconds: 10),
    this.pauseFor = const Duration(seconds: 3),
    this.retryDelay = const Duration(milliseconds: 120),
    SpeechRecognizerAdapter? recognizer,
  }) : _recognizer = recognizer ?? SpeechToTextAdapter();

  Future<String?> listen({
    required bool isSpeaking,
    required String localeId,
  }) async {
    if (isSpeaking) return null;
    if (_isListenInFlight) return null;

    _isListenInFlight = true;

    try {
      return await _listenSafely(localeId: localeId);
    } finally {
      _isListenInFlight = false;
    }
  }

  Future<String?> _listenSafely({required String localeId}) async {
    await _ensureRecognizerStopped();

    final available = await _recognizer.initialize(
      onStatus: (status) {
        // Ignore frequent status callbacks to avoid noisy logs in production.
      },
      onError: (error) {
        // Errors are handled through null result fallback in the controller.
      },
    );

    if (!available) {
      return null;
    }

    var spokenText = '';

    try {
      await _recognizer.listen(
        onResult: (result) {
          spokenText = result;
        },
        listenFor: listenFor,
        pauseFor: pauseFor,
        localeId: localeId,
      );
    } catch (_) {
      _sttStartFailureCount += 1;

      // On web, start() may fail with InvalidStateError if a previous
      // recognizer instance has not fully settled yet. Retry once after cleanup.
      await _ensureRecognizerStopped();
      await Future.delayed(retryDelay);

      try {
        await _recognizer.listen(
          onResult: (result) {
            spokenText = result;
          },
          listenFor: listenFor,
          pauseFor: pauseFor,
          localeId: localeId,
        );
      } catch (_) {
        _sttStartFailureCount += 1;
        return null;
      }
    }

    while (_recognizer.isListening) {
      await Future.delayed(const Duration(milliseconds: 150));
    }

    await _recognizer.stop();

    if (spokenText.trim().isEmpty) {
      return null;
    }

    return spokenText.trim();
  }

  Future<void> _ensureRecognizerStopped() async {
    try {
      await _recognizer.stop();
    } catch (_) {
      // Ignore stop errors during cleanup; next listen attempt will fallback.
    }

    for (var i = 0; i < 10 && _recognizer.isListening; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
}
