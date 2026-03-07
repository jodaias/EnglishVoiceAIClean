import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/app_locale.dart';
import '../../domain/entities/conversation_language.dart';
import '../../domain/entities/session_scene.dart';
import '../../domain/entities/session_ui_preferences.dart';

class LocalUserPreferencesRepository {
  static const String _boxName = 'voice_chat_local_v1';
  static const String _preferredLanguageKey =
      'voice_chat_preferred_language_v1';
  static const String _appLocaleKey = 'voice_chat_app_locale_v1';
  static const String _autoResumeListeningKey =
      'voice_chat_auto_resume_listening_v1';
  static const String _showStartupTipsKey = 'voice_chat_show_startup_tips_v1';
  static const String _reviewBeforeSendKey = 'voice_chat_review_before_send_v1';
  static const String _selectedSceneKey = 'voice_chat_selected_scene_v1';
  static const String _aiProviderKey = 'voice_chat_ai_provider_v1';
  static const String _useCustomAiModelKey =
      'voice_chat_use_custom_ai_model_v1';
  static const String _geminiModelKey = 'voice_chat_gemini_model_v1';
  static const String _openAiModelKey = 'voice_chat_openai_model_v1';

  String _readEnvOrEmpty(String key) {
    try {
      return dotenv.env[key] ?? '';
    } catch (_) {
      return '';
    }
  }

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
    final reviewBeforeSendRaw = box.get(_reviewBeforeSendKey);
    final selectedSceneRaw = box.get(_selectedSceneKey)?.toString() ?? '';
    final providerRaw = box.get(_aiProviderKey)?.toString();
    final useCustomModelRaw = box.get(_useCustomAiModelKey);
    final geminiModelRaw = box.get(_geminiModelKey)?.toString();
    final openAiModelRaw = box.get(_openAiModelKey)?.toString();

    final defaultProvider = AiProviderX.fromEnv(_readEnvOrEmpty('AI_PROVIDER'));
    final aiProvider = providerRaw == null
        ? defaultProvider
        : AiProviderX.fromStorage(providerRaw);

    final defaultGeminiModel =
        AiProvider.gemini.normalizeModel(_readEnvOrEmpty('GEMINI_MODEL'));
    final defaultOpenAiModel =
        AiProvider.openai.normalizeModel(_readEnvOrEmpty('OPENAI_MODEL'));

    return SessionUiPreferences(
      autoResumeListening: autoResumeRaw is bool ? autoResumeRaw : true,
      showStartupTips: showTipsRaw is bool ? showTipsRaw : true,
      reviewBeforeSend:
          reviewBeforeSendRaw is bool ? reviewBeforeSendRaw : false,
      selectedScene: SessionSceneX.fromStorage(selectedSceneRaw),
      aiProvider: aiProvider,
      useCustomAiModel: useCustomModelRaw is bool ? useCustomModelRaw : false,
      geminiModel: AiProvider.gemini
          .normalizeModel(geminiModelRaw ?? defaultGeminiModel),
      openAiModel: AiProvider.openai
          .normalizeModel(openAiModelRaw ?? defaultOpenAiModel),
    );
  }

  Future<void> saveSessionUiPreferences(SessionUiPreferences value) async {
    final box = await _openBox();
    await box.put(_autoResumeListeningKey, value.autoResumeListening);
    await box.put(_showStartupTipsKey, value.showStartupTips);
    await box.put(_reviewBeforeSendKey, value.reviewBeforeSend);
    await box.put(_selectedSceneKey, value.selectedScene.name);
    await box.put(_aiProviderKey, value.aiProvider.envValue);
    await box.put(_useCustomAiModelKey, value.useCustomAiModel);
    await box.put(
        _geminiModelKey, AiProvider.gemini.normalizeModel(value.geminiModel));
    await box.put(
        _openAiModelKey, AiProvider.openai.normalizeModel(value.openAiModel));
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return Hive.openBox<dynamic>(_boxName);
  }
}
