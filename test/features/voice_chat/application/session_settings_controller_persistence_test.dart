import 'dart:io';

import 'package:english_voice_ai_clean/features/voice_chat/application/session_settings_controller.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/ai_provider.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/session_scene.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/local/local_user_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'session_settings_hive_test_',
    );
    Hive.init(tempDir.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen('voice_chat_local_v1')) {
      await Hive.box<dynamic>('voice_chat_local_v1').clear();
      await Hive.box<dynamic>('voice_chat_local_v1').close();
    }
    await Hive.deleteBoxFromDisk('voice_chat_local_v1');
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('persists session preferences across controller restart', () async {
    final repository = LocalUserPreferencesRepository();

    final firstController = SessionSettingsController(
      preferencesRepository: repository,
    );

    await firstController.load();
    expect(
        firstController.preferencesNotifier.value.autoResumeListening, isTrue);
    expect(firstController.preferencesNotifier.value.showStartupTips, isTrue);
    expect(firstController.preferencesNotifier.value.selectedScene,
        SessionScene.studio);
    expect(firstController.preferencesNotifier.value.aiProvider,
        AiProvider.openai);
    expect(firstController.preferencesNotifier.value.useCustomAiModel, isFalse);
    expect(firstController.preferencesNotifier.value.openAiModel, 'gpt-4.1');
    expect(firstController.preferencesNotifier.value.geminiModel,
        'gemini-2.5-flash');

    await firstController.setAutoResumeListening(false);
    await firstController.setShowStartupTips(false);
    await firstController.setSelectedScene(SessionScene.city);
    await firstController.setAiProvider(AiProvider.gemini);
    await firstController.setUseCustomAiModel(true);
    await firstController.setGeminiModel('gemini-2.5-pro');
    await firstController.setOpenAiModel('gpt-4o-mini');

    expect(
        firstController.preferencesNotifier.value.autoResumeListening, isFalse);
    expect(firstController.preferencesNotifier.value.showStartupTips, isFalse);
    expect(firstController.preferencesNotifier.value.selectedScene,
        SessionScene.city);
    expect(firstController.preferencesNotifier.value.aiProvider,
        AiProvider.gemini);
    expect(firstController.preferencesNotifier.value.useCustomAiModel, isTrue);
    expect(firstController.preferencesNotifier.value.geminiModel,
        'gemini-2.5-pro');
    expect(
        firstController.preferencesNotifier.value.openAiModel, 'gpt-4o-mini');

    firstController.dispose();

    final secondController = SessionSettingsController(
      preferencesRepository: repository,
    );

    await secondController.load();

    expect(secondController.preferencesNotifier.value.autoResumeListening,
        isFalse);
    expect(secondController.preferencesNotifier.value.showStartupTips, isFalse);
    expect(secondController.preferencesNotifier.value.selectedScene,
        SessionScene.city);
    expect(secondController.preferencesNotifier.value.aiProvider,
        AiProvider.gemini);
    expect(secondController.preferencesNotifier.value.useCustomAiModel, isTrue);
    expect(secondController.preferencesNotifier.value.geminiModel,
        'gemini-2.5-pro');
    expect(
        secondController.preferencesNotifier.value.openAiModel, 'gpt-4o-mini');

    secondController.dispose();
  });
}
