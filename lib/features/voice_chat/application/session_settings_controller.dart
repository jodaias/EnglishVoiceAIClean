import 'package:flutter/foundation.dart';

import '../domain/entities/ai_provider.dart';
import '../domain/entities/session_scene.dart';
import '../domain/entities/session_ui_preferences.dart';
import '../infrastructure/local/local_user_preferences_repository.dart';

class SessionSettingsController {
  final LocalUserPreferencesRepository preferencesRepository;

  final ValueNotifier<SessionUiPreferences> preferencesNotifier =
      ValueNotifier<SessionUiPreferences>(
    const SessionUiPreferences.defaults(),
  );
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  SessionSettingsController({required this.preferencesRepository});

  Future<void> load() async {
    isLoadingNotifier.value = true;
    try {
      preferencesNotifier.value =
          await preferencesRepository.getSessionUiPreferences();
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> setAutoResumeListening(bool value) async {
    final updated = preferencesNotifier.value.copyWith(
      autoResumeListening: value,
    );
    preferencesNotifier.value = updated;
    await preferencesRepository.saveSessionUiPreferences(updated);
  }

  Future<void> setShowStartupTips(bool value) async {
    final updated = preferencesNotifier.value.copyWith(
      showStartupTips: value,
    );
    preferencesNotifier.value = updated;
    await preferencesRepository.saveSessionUiPreferences(updated);
  }

  Future<void> setReviewBeforeSend(bool value) async {
    final updated = preferencesNotifier.value.copyWith(
      reviewBeforeSend: value,
    );
    preferencesNotifier.value = updated;
    await preferencesRepository.saveSessionUiPreferences(updated);
  }

  Future<void> setSelectedScene(SessionScene value) async {
    final updated = preferencesNotifier.value.copyWith(
      selectedScene: value,
    );
    preferencesNotifier.value = updated;
    await preferencesRepository.saveSessionUiPreferences(updated);
  }

  Future<void> setAiProvider(AiProvider value) async {
    final updated = preferencesNotifier.value.copyWith(
      aiProvider: value,
    );
    preferencesNotifier.value = updated;
    await preferencesRepository.saveSessionUiPreferences(updated);
  }

  Future<void> setUseCustomAiModel(bool value) async {
    final updated = preferencesNotifier.value.copyWith(
      useCustomAiModel: value,
    );
    preferencesNotifier.value = updated;
    await preferencesRepository.saveSessionUiPreferences(updated);
  }

  Future<void> setGeminiModel(String value) async {
    final updated = preferencesNotifier.value.copyWith(
      geminiModel: AiProvider.gemini.normalizeModel(value),
    );
    preferencesNotifier.value = updated;
    await preferencesRepository.saveSessionUiPreferences(updated);
  }

  Future<void> setOpenAiModel(String value) async {
    final updated = preferencesNotifier.value.copyWith(
      openAiModel: AiProvider.openai.normalizeModel(value),
    );
    preferencesNotifier.value = updated;
    await preferencesRepository.saveSessionUiPreferences(updated);
  }

  void dispose() {
    preferencesNotifier.dispose();
    isLoadingNotifier.dispose();
  }
}
