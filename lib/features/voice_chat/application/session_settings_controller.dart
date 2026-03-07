import 'package:flutter/foundation.dart';

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

  Future<void> setSelectedScene(SessionScene value) async {
    final updated = preferencesNotifier.value.copyWith(
      selectedScene: value,
    );
    preferencesNotifier.value = updated;
    await preferencesRepository.saveSessionUiPreferences(updated);
  }

  void dispose() {
    preferencesNotifier.dispose();
    isLoadingNotifier.dispose();
  }
}
