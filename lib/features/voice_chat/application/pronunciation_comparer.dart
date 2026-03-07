import '../domain/entities/pronunciation_result.dart';

class PronunciationComparer {
  PronunciationResult compare(String original, String spoken) {
    final originalWords = _tokenize(original);
    final spokenWords = _tokenize(spoken);

    final wordMatches = <PronunciationWordMatch>[];
    var matched = 0;

    for (var i = 0; i < originalWords.length; i++) {
      final expected = originalWords[i];
      String? spokenWord;
      var isMatch = false;

      final searchStart = (i - 2).clamp(0, spokenWords.length);
      final searchEnd = (i + 3).clamp(0, spokenWords.length);

      for (var j = searchStart; j < searchEnd; j++) {
        if (_wordsMatch(expected, spokenWords[j])) {
          spokenWord = spokenWords[j];
          isMatch = true;
          break;
        }
      }

      if (isMatch) {
        matched++;
      }

      wordMatches.add(PronunciationWordMatch(
        expected: expected,
        spoken: spokenWord,
        matched: isMatch,
      ));
    }

    return PronunciationResult(
      originalText: original,
      spokenText: spoken,
      wordMatches: wordMatches,
      matchedWords: matched,
      totalWords: originalWords.length,
    );
  }

  List<String> _tokenize(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  bool _wordsMatch(String a, String b) {
    if (a == b) return true;
    if (a.length > 3 && b.length > 3) {
      return _levenshtein(a, b) <= 1;
    }
    return false;
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var prev = List<int>.generate(b.length + 1, (i) => i);
    var curr = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        final insert = curr[j - 1] + 1;
        final delete = prev[j] + 1;
        final replace = prev[j - 1] + cost;
        curr[j] = insert < delete
            ? (insert < replace ? insert : replace)
            : (delete < replace ? delete : replace);
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }

    return prev[b.length];
  }
}
