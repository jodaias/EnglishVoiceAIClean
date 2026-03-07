import 'conversation_language.dart';

enum ReadingListeningDifficulty {
  beginner,
  intermediate,
}

enum ReadingListeningDifficultyFilter {
  all,
  beginner,
  intermediate,
}

extension ReadingListeningDifficultyX on ReadingListeningDifficulty {
  bool matchesFilter(ReadingListeningDifficultyFilter filter) {
    switch (filter) {
      case ReadingListeningDifficultyFilter.all:
        return true;
      case ReadingListeningDifficultyFilter.beginner:
        return this == ReadingListeningDifficulty.beginner;
      case ReadingListeningDifficultyFilter.intermediate:
        return this == ReadingListeningDifficulty.intermediate;
    }
  }
}

class ReadingListeningExercise {
  final String id;
  final String titleEn;
  final String titlePt;
  final String readingTextEn;
  final String readingTextPt;
  final String questionEn;
  final String questionPt;
  final List<String> optionsEn;
  final List<String> optionsPt;
  final int correctOptionIndex;
  final ReadingListeningDifficulty difficulty;

  const ReadingListeningExercise({
    required this.id,
    required this.titleEn,
    required this.titlePt,
    required this.readingTextEn,
    required this.readingTextPt,
    required this.questionEn,
    required this.questionPt,
    required this.optionsEn,
    required this.optionsPt,
    required this.correctOptionIndex,
    required this.difficulty,
  });

  String titleFor(ConversationLanguage language) {
    return language == ConversationLanguage.portugueseBr ? titlePt : titleEn;
  }

  String readingTextFor(ConversationLanguage language) {
    return language == ConversationLanguage.portugueseBr
        ? readingTextPt
        : readingTextEn;
  }

  String questionFor(ConversationLanguage language) {
    return language == ConversationLanguage.portugueseBr
        ? questionPt
        : questionEn;
  }

  List<String> optionsFor(ConversationLanguage language) {
    return language == ConversationLanguage.portugueseBr
        ? optionsPt
        : optionsEn;
  }
}
