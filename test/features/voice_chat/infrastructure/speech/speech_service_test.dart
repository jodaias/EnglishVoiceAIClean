import 'dart:async';

import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/speech/speech_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpeechService', () {
    test('serializes concurrent listen calls (single-flight)', () async {
      final adapter = _FakeRecognizerAdapter(
        listenActions: <_ListenAction>[
          _ListenAction.blocking(
            recognizedWords: 'hello there',
          ),
        ],
      );

      final service = SpeechService(
        recognizer: adapter,
        retryDelay: Duration.zero,
      );

      final first = service.listen(isSpeaking: false, localeId: 'en_US');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final second = await service.listen(isSpeaking: false, localeId: 'en_US');

      expect(second, isNull);

      adapter.releaseBlockingListen();
      final firstResult = await first;

      expect(firstResult, 'hello there');
      expect(adapter.listenCalls, 1);
    });

    test('retries once after web start failure and counts failure', () async {
      final adapter = _FakeRecognizerAdapter(
        listenActions: <_ListenAction>[
          _ListenAction.throwing(StateError('stale recognizer state')),
          _ListenAction.success('retry succeeded'),
        ],
      );

      final service = SpeechService(
        recognizer: adapter,
        retryDelay: Duration.zero,
      );

      final result = await service.listen(isSpeaking: false, localeId: 'en_US');

      expect(result, 'retry succeeded');
      expect(service.sttStartFailureCount, 1);
      expect(adapter.listenCalls, 2);
    });

    test('returns null when retry also fails and keeps count', () async {
      final adapter = _FakeRecognizerAdapter(
        listenActions: <_ListenAction>[
          _ListenAction.throwing(StateError('first fail')),
          _ListenAction.throwing(StateError('second fail')),
        ],
      );

      final service = SpeechService(
        recognizer: adapter,
        retryDelay: Duration.zero,
      );

      final result = await service.listen(isSpeaking: false, localeId: 'en_US');

      expect(result, isNull);
      expect(service.sttStartFailureCount, 2);
      expect(adapter.listenCalls, 2);
    });
  });
}

class _FakeRecognizerAdapter implements SpeechRecognizerAdapter {
  final List<_ListenAction> _listenActions;
  int initializeCalls = 0;
  int listenCalls = 0;
  int stopCalls = 0;

  bool _isListening = false;
  Completer<void>? _blockingCompleter;

  _FakeRecognizerAdapter({required List<_ListenAction> listenActions})
      : _listenActions = List<_ListenAction>.from(listenActions);

  void releaseBlockingListen() {
    _blockingCompleter?.complete();
  }

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(Object error) onError,
  }) async {
    initializeCalls += 1;
    return true;
  }

  @override
  Future<void> listen({
    required void Function(String recognizedWords) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String localeId,
  }) async {
    listenCalls += 1;
    if (_listenActions.isEmpty) {
      return;
    }

    final action = _listenActions.removeAt(0);
    if (action.error != null) {
      throw action.error!;
    }

    if (action.blocking) {
      _isListening = true;
      _blockingCompleter = Completer<void>();
      await _blockingCompleter!.future;
    }

    if (action.recognizedWords != null) {
      onResult(action.recognizedWords!);
    }

    _isListening = false;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    _isListening = false;
  }

  @override
  bool get isListening => _isListening;
}

class _ListenAction {
  final String? recognizedWords;
  final Object? error;
  final bool blocking;

  const _ListenAction._({
    this.recognizedWords,
    this.error,
    this.blocking = false,
  });

  const _ListenAction.success(String words)
      : this._(recognizedWords: words, blocking: false);

  const _ListenAction.blocking({required String recognizedWords})
      : this._(recognizedWords: recognizedWords, blocking: true);

  const _ListenAction.throwing(Object error)
      : this._(error: error, blocking: false);
}
