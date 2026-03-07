import 'dart:io';

import 'package:english_voice_ai_clean/features/voice_chat/application/app_settings_controller.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/app_locale.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/local/local_user_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('app_settings_hive_test_');
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

  test('persists app language choice across controller restart', () async {
    final repository = LocalUserPreferencesRepository();

    final firstController = AppSettingsController(
      preferencesRepository: repository,
    );

    await firstController.load();
    expect(firstController.appLocaleNotifier.value, AppLocale.enUs);

    await firstController.setAppLocale(AppLocale.ptBr);
    expect(firstController.appLocaleNotifier.value, AppLocale.ptBr);
    firstController.dispose();

    final secondController = AppSettingsController(
      preferencesRepository: repository,
    );

    await secondController.load();
    expect(secondController.appLocaleNotifier.value, AppLocale.ptBr);

    secondController.dispose();
  });
}
