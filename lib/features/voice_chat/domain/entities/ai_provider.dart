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

  String get envValue {
    switch (this) {
      case AiProvider.openai:
        return 'openai';
      case AiProvider.gemini:
        return 'gemini';
    }
  }
}
