import 'package:flutter/widgets.dart';

import '../application/app_settings_controller.dart';
import '../domain/entities/app_locale.dart';

class AppSettingsScope extends InheritedWidget {
  final AppSettingsController controller;
  final AppLocale locale;

  const AppSettingsScope({
    super.key,
    required this.controller,
    required this.locale,
    required super.child,
  });

  static AppSettingsScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
  }

  static AppSettingsController controllerOf(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw StateError('AppSettingsScope not found in widget tree.');
    }
    return scope.controller;
  }

  static AppLocale localeOf(BuildContext context) {
    return maybeOf(context)?.locale ?? AppLocale.enUs;
  }

  @override
  bool updateShouldNotify(AppSettingsScope oldWidget) {
    return locale != oldWidget.locale || controller != oldWidget.controller;
  }
}
