class PronunciationWordMatch {
  final String expected;
  final String? spoken;
  final bool matched;

  const PronunciationWordMatch({
    required this.expected,
    required this.spoken,
    required this.matched,
  });
}

class PronunciationResult {
  final String originalText;
  final String spokenText;
  final List<PronunciationWordMatch> wordMatches;
  final int matchedWords;
  final int totalWords;

  const PronunciationResult({
    required this.originalText,
    required this.spokenText,
    required this.wordMatches,
    required this.matchedWords,
    required this.totalWords,
  });

  int get accuracyPercent =>
      totalWords == 0 ? 0 : ((matchedWords / totalWords) * 100).round();
}
