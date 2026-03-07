import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/app_locale.dart';
import '../../domain/entities/conversation_language.dart';
import '../../domain/entities/session_ui_preferences.dart';

class LocalUserPreferencesRepository {
  static const String _boxName = 'voice_chat_local_v1';
  static const String _preferredLanguageKey =
      'voice_chat_preferred_language_v1';
  static const String _appLocaleKey = 'voice_chat_app_locale_v1';
  static const String _autoResumeListeningKey =
      'voice_chat_auto_resume_listening_v1';
  static const String _showStartupTipsKey = 'voice_chat_show_startup_tips_v1';

  Future<ConversationLanguage> getPreferredLanguage() async {
    final box = await _openBox();
    final raw = box.get(_preferredLanguageKey)?.toString() ?? '';

    switch (raw) {
      case 'englishUs':
        return ConversationLanguage.englishUs;
      case 'portugueseBr':
        return ConversationLanguage.portugueseBr;
      case 'auto':
      default:
        return ConversationLanguage.auto;
    }
  }

  Future<void> savePreferredLanguage(ConversationLanguage language) async {
    final box = await _openBox();
    await box.put(_preferredLanguageKey, language.name);
  }

  Future<AppLocale> getAppLocale() async {
    final box = await _openBox();
    final raw = box.get(_appLocaleKey)?.toString() ?? '';

    switch (raw) {
      case 'ptBr':
        return AppLocale.ptBr;
      case 'enUs':
      default:
        return AppLocale.enUs;
    }
  }

  Future<void> saveAppLocale(AppLocale appLocale) async {
    final box = await _openBox();
    await box.put(_appLocaleKey, appLocale.name);
  }

  Future<SessionUiPreferences> getSessionUiPreferences() async {
    final box = await _openBox();

    final autoResumeRaw = box.get(_autoResumeListeningKey);
    final showTipsRaw = box.get(_showStartupTipsKey);

    return SessionUiPreferences(
      autoResumeListening: autoResumeRaw is bool ? autoResumeRaw : true,
      showStartupTips: showTipsRaw is bool ? showTipsRaw : true,
    );
  }

  Future<void> saveSessionUiPreferences(SessionUiPreferences value) async {
    final box = await _openBox();
    await box.put(_autoResumeListeningKey, value.autoResumeListening);
    await box.put(_showStartupTipsKey, value.showStartupTips);
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return Hive.openBox<dynamic>(_boxName);
  }
}
