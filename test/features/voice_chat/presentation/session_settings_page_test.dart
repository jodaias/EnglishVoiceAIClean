import 'dart:io';

import 'package:english_voice_ai_clean/features/voice_chat/application/app_settings_controller.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/app_locale.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/session_scene.dart';
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

  testWidgets(
    'persists session switches and app language across restart-like lifecycle',
    (tester) async {
      final repository = LocalUserPreferencesRepository();
      final firstController = AppSettingsController(
        preferencesRepository: repository,
      );
      await firstController.load();

      await _pumpSessionSettingsPage(tester, firstController);

      expect(find.text('Session Settings'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(2));
      expect(find.text('Studio'), findsOneWidget);

      await tester.tap(find.text('Auto resume listening after bot speech'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show startup tips when opening chat'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('English').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portugues (Brasil)').last);
      await tester.pumpAndSettle();

      final prefsAfterSave = await repository.getSessionUiPreferences();
      expect(prefsAfterSave.autoResumeListening, isFalse);
      expect(prefsAfterSave.showStartupTips, isFalse);
      expect(prefsAfterSave.selectedScene, SessionScene.studio);
      expect(await repository.getAppLocale(), AppLocale.ptBr);
      expect(find.text('Configuracoes da Sessao'), findsOneWidget);

      firstController.dispose();

      final secondController = AppSettingsController(
        preferencesRepository: repository,
      );
      await secondController.load();

      await _pumpSessionSettingsPage(tester, secondController);

      final switches = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(switches[0].value, isFalse);
      expect(switches[1].value, isFalse);
      expect(find.text('Estudio'), findsOneWidget);
      expect(find.text('Configuracoes da Sessao'), findsOneWidget);

      secondController.dispose();
    },
  );
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

  await tester.pumpAndSettle();
}
