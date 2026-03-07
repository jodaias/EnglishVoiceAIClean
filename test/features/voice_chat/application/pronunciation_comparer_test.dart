import 'package:english_voice_ai_clean/features/voice_chat/application/pronunciation_comparer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PronunciationComparer', () {
    late PronunciationComparer comparer;

    setUp(() {
      comparer = PronunciationComparer();
    });

    test('perfect match returns 100% accuracy', () {
      final result = comparer.compare(
        'The train leaves at six',
        'the train leaves at six',
      );

      expect(result.accuracyPercent, 100);
      expect(result.matchedWords, 5);
      expect(result.totalWords, 5);
    });

    test('partial match returns correct accuracy', () {
      final result = comparer.compare(
        'The train leaves at six',
        'the bus leaves at six',
      );

      expect(result.matchedWords, 4);
      expect(result.totalWords, 5);
      expect(result.accuracyPercent, 80);
    });

    test('empty spoken text returns 0% accuracy', () {
      final result = comparer.compare(
        'The train leaves at six',
        '',
      );

      expect(result.accuracyPercent, 0);
      expect(result.matchedWords, 0);
      expect(result.totalWords, 5);
    });

    test('handles punctuation in original text', () {
      final result = comparer.compare(
        'Hello, how are you?',
        'hello how are you',
      );

      expect(result.accuracyPercent, 100);
      expect(result.matchedWords, 4);
    });

    test('tolerates minor spelling differences via levenshtein', () {
      final result = comparer.compare(
        'I want to practice speaking',
        'I want to practise speaking',
      );

      expect(result.matchedWords, 5);
      expect(result.accuracyPercent, 100);
    });

    test('word matches show expected and spoken status', () {
      final result = comparer.compare(
        'The cat sat on the mat',
        'the dog sat on the mat',
      );

      final catMatch =
          result.wordMatches.firstWhere((m) => m.expected == 'cat');
      expect(catMatch.matched, isFalse);

      final satMatch =
          result.wordMatches.firstWhere((m) => m.expected == 'sat');
      expect(satMatch.matched, isTrue);
    });
  });
}
