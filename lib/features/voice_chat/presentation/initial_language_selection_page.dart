import 'package:flutter/material.dart';

import '../domain/entities/app_locale.dart';
import '../domain/entities/conversation_language.dart';
import '../infrastructure/local/local_user_preferences_repository.dart';
import 'app_settings_scope.dart';
import 'dashboard_routes.dart';

class InitialLanguageSelectionPage extends StatefulWidget {
  const InitialLanguageSelectionPage({super.key});

  @override
  State<InitialLanguageSelectionPage> createState() =>
      _InitialLanguageSelectionPageState();
}

class _InitialLanguageSelectionPageState
    extends State<InitialLanguageSelectionPage> {
  final LocalUserPreferencesRepository _preferencesRepository =
      LocalUserPreferencesRepository();
  bool _isSaving = false;

  Future<void> _selectLanguage({
    required AppLocale appLocale,
    required ConversationLanguage conversationLanguage,
  }) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final appSettingsController = AppSettingsScope.controllerOf(context);
    await appSettingsController.setAppLocale(appLocale);
    await _preferencesRepository.savePreferredLanguage(conversationLanguage);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(DashboardRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Choose your language\nEscolha seu idioma',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'This setting can be changed later in the app settings.\nVoce pode alterar isso depois nas configuracoes do app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 28),
                  _LanguageButton(
                    title: 'English',
                    subtitle: 'Continue in English (US)',
                    icon: Icons.language,
                    enabled: !_isSaving,
                    onTap: () => _selectLanguage(
                      appLocale: AppLocale.enUs,
                      conversationLanguage: ConversationLanguage.englishUs,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LanguageButton(
                    title: 'Portugues',
                    subtitle: 'Continuar em portugues (Brasil)',
                    icon: Icons.translate,
                    enabled: !_isSaving,
                    onTap: () => _selectLanguage(
                      appLocale: AppLocale.ptBr,
                      conversationLanguage: ConversationLanguage.portugueseBr,
                    ),
                  ),
                  if (_isSaving) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
