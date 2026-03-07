import 'dart:io';

import 'package:english_voice_ai_clean/features/voice_chat/application/session_settings_controller.dart';
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

    await firstController.setAutoResumeListening(false);
    await firstController.setShowStartupTips(false);
    await firstController.setSelectedScene(SessionScene.city);

    expect(
        firstController.preferencesNotifier.value.autoResumeListening, isFalse);
    expect(firstController.preferencesNotifier.value.showStartupTips, isFalse);
    expect(firstController.preferencesNotifier.value.selectedScene,
        SessionScene.city);

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

    secondController.dispose();
  });
}
