import 'package:flutter/widgets.dart';

import '../domain/entities/app_locale.dart';
import 'app_settings_scope.dart';

String appText(
  BuildContext context, {
  required String en,
  required String pt,
}) {
  final locale = AppSettingsScope.localeOf(context);
  return locale == AppLocale.ptBr ? pt : en;
}
