enum AiProvider {
  openai,
  gemini,
}

extension AiProviderX on AiProvider {
  static AiProvider fromEnv(String? rawValue) {
    final normalized = (rawValue ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'gemini':
        return AiProvider.gemini;
      case 'openai':
      default:
        return AiProvider.openai;
    }
  }

  static AiProvider fromStorage(String? rawValue) {
    return fromEnv(rawValue);
  }

  String get envValue {
    switch (this) {
      case AiProvider.openai:
        return 'openai';
      case AiProvider.gemini:
        return 'gemini';
    }
  }

  String get label {
    switch (this) {
      case AiProvider.openai:
        return 'OpenAI';
      case AiProvider.gemini:
        return 'Gemini';
    }
  }

  String get defaultModel {
    switch (this) {
      case AiProvider.openai:
        return 'gpt-4.1';
      case AiProvider.gemini:
        return 'gemini-2.5-flash';
    }
  }

  List<String> get presetModels {
    switch (this) {
      case AiProvider.openai:
        return const <String>[
          'gpt-4.1',
          'gpt-4.1-mini',
          'gpt-4o',
          'gpt-4o-mini',
        ];
      case AiProvider.gemini:
        return const <String>[
          'gemini-2.5-flash',
          'gemini-2.5-flash Lite',
          'gemini-2.5-pro',
          'gemini-2.0-flash',
          'gemini-1.5-pro',
          'Gemini 3.1 Flash Lite',
          'Gemini 2.5 Flash Native Audio Dialog',
          'Gemma 3 1B',
          'Gemma 3 4B',
          'Gemma 3 12B',
          'Gemma 3 27B',
        ];
    }
  }

  String normalizeModel(String? rawModel) {
    final trimmed = (rawModel ?? '').trim();
    if (trimmed.isEmpty) {
      return defaultModel;
    }

    for (final option in presetModels) {
      if (option.toLowerCase() == trimmed.toLowerCase()) {
        return option;
      }
    }

    return trimmed;
  }
}
