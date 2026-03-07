enum ConversationLanguage { auto, englishUs, portugueseBr }

extension ConversationLanguageX on ConversationLanguage {
  String get speechLocale {
    switch (this) {
      case ConversationLanguage.englishUs:
        return 'en_US';
      case ConversationLanguage.portugueseBr:
        return 'pt_BR';
      case ConversationLanguage.auto:
        return 'en_US';
    }
  }

  String get ttsLocale {
    switch (this) {
      case ConversationLanguage.englishUs:
        return 'en-US';
      case ConversationLanguage.portugueseBr:
        return 'pt-BR';
      case ConversationLanguage.auto:
        return 'en-US';
    }
  }

  String get label {
    switch (this) {
      case ConversationLanguage.auto:
        return 'Auto';
      case ConversationLanguage.englishUs:
        return 'English (US)';
      case ConversationLanguage.portugueseBr:
        return 'Portugues (BR)';
    }
  }
}
