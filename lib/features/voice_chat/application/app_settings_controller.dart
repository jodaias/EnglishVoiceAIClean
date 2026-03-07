import 'package:flutter/foundation.dart';

import '../domain/entities/app_locale.dart';
import '../infrastructure/local/local_user_preferences_repository.dart';

class AppSettingsController {
  final LocalUserPreferencesRepository preferencesRepository;

  final ValueNotifier<AppLocale> appLocaleNotifier =
      ValueNotifier<AppLocale>(AppLocale.enUs);

  AppSettingsController({required this.preferencesRepository});

  Future<void> load() async {
    final appLocale = await preferencesRepository.getAppLocale();
    appLocaleNotifier.value = appLocale;
  }

  Future<void> setAppLocale(AppLocale appLocale) async {
    appLocaleNotifier.value = appLocale;
    await preferencesRepository.saveAppLocale(appLocale);
  }

  void dispose() {
    appLocaleNotifier.dispose();
  }
}
