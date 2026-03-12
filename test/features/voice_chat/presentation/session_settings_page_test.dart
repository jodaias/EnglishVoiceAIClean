import 'dart:io';

import 'package:english_voice_ai_clean/features/voice_chat/application/app_settings_controller.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/ai_provider.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/app_locale.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/session_scene.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/session_ui_preferences.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/local/local_user_preferences_repository.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/app_settings_scope.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/session_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('session_settings_page_');
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

  testWidgets('renders persisted settings values from repository',
      (tester) async {
    final repository = LocalUserPreferencesRepository();
    await repository.saveSessionUiPreferences(
      const SessionUiPreferences.defaults().copyWith(
        autoResumeListening: false,
        showStartupTips: false,
        reviewBeforeSend: true,
        selectedScene: SessionScene.city,
        aiProvider: AiProvider.gemini,
        useCustomAiModel: true,
        geminiModel: 'gemini-2.5-pro',
      ),
    );

    final appSettingsController = AppSettingsController(
      preferencesRepository: repository,
    );
    await appSettingsController.load();

    await _pumpSessionSettingsPage(tester, appSettingsController);

    expect(find.text('Session Settings'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Gemini'), findsOneWidget);

    final switches =
        tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
    expect(switches[0].value, isFalse);
    expect(switches[1].value, isTrue);
    expect(switches[2].value, isFalse);

    appSettingsController.dispose();
  });

  testWidgets('updates app locale label when app locale changes',
      (tester) async {
    final repository = LocalUserPreferencesRepository();
    final appSettingsController = AppSettingsController(
      preferencesRepository: repository,
    );
    await appSettingsController.load();

    await _pumpSessionSettingsPage(tester, appSettingsController);
    expect(find.text('Session Settings'), findsOneWidget);

    await appSettingsController.setAppLocale(AppLocale.ptBr);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Configurações da Sessão'), findsOneWidget);

    appSettingsController.dispose();
  });
}

Future<void> _pumpSessionSettingsPage(
  WidgetTester tester,
  AppSettingsController appSettingsController,
) async {
  await tester.pumpWidget(
    ValueListenableBuilder<AppLocale>(
      valueListenable: appSettingsController.appLocaleNotifier,
      builder: (context, locale, _) {
        return AppSettingsScope(
          controller: appSettingsController,
          locale: locale,
          child: const MaterialApp(
            home: SessionSettingsPage(),
          ),
        );
      },
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
