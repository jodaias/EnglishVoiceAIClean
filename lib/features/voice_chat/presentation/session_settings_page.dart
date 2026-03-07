import 'package:flutter/material.dart';

import '../application/session_settings_controller.dart';
import '../domain/entities/ai_provider.dart';
import '../domain/entities/app_locale.dart';
import '../domain/entities/session_scene.dart';
import '../domain/entities/session_ui_preferences.dart';
import 'app_settings_scope.dart';
import 'app_text.dart';
import 'dashboard_routes.dart';
import '../infrastructure/local/local_user_preferences_repository.dart';
import 'responsive_content_shell.dart';
import 'voice_chat_page.dart';

class SessionSettingsPage extends StatefulWidget {
  const SessionSettingsPage({super.key});

  @override
  State<SessionSettingsPage> createState() => _SessionSettingsPageState();
}

class _SessionSettingsPageState extends State<SessionSettingsPage> {
  late final SessionSettingsController sessionSettingsController;
  static const List<SessionScene> _sceneOptions = SessionScene.values;

  @override
  void initState() {
    super.initState();
    sessionSettingsController = SessionSettingsController(
      preferencesRepository: LocalUserPreferencesRepository(),
    );
    sessionSettingsController.load();
  }

  @override
  void dispose() {
    sessionSettingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appSettingsController = AppSettingsScope.controllerOf(context);
    final selectedAppLocale = appSettingsController.appLocaleNotifier.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appText(
            context,
            en: 'Session Settings',
            pt: 'Configuracoes da Sessao',
          ),
        ),
      ),
      body: ResponsiveContentShell.premium(
        child: ValueListenableBuilder<bool>(
          valueListenable: sessionSettingsController.isLoadingNotifier,
          builder: (context, isLoading, _) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ValueListenableBuilder<SessionUiPreferences>(
              valueListenable: sessionSettingsController.preferencesNotifier,
              builder: (context, preferences, __) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        appText(
                          context,
                          en: 'Use these options to shape how each speaking session starts. Settings are now persisted locally.',
                          pt: 'Use estas opcoes para ajustar como cada sessao de fala comeca. As configuracoes agora ficam salvas localmente.',
                        ),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AppLocale>(
                      key: ValueKey<AppLocale>(selectedAppLocale),
                      initialValue: selectedAppLocale,
                      decoration: InputDecoration(
                        labelText: appText(
                          context,
                          en: 'App Language',
                          pt: 'Idioma do App',
                        ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: AppLocale.values
                          .map(
                            (locale) => DropdownMenuItem<AppLocale>(
                              value: locale,
                              child: Text(locale.label),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        appSettingsController.setAppLocale(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AiProvider>(
                      key: ValueKey<AiProvider>(preferences.aiProvider),
                      initialValue: preferences.aiProvider,
                      decoration: InputDecoration(
                        labelText: appText(
                          context,
                          en: 'AI Provider',
                          pt: 'Provedor de IA',
                        ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: AiProvider.values
                          .map(
                            (provider) => DropdownMenuItem<AiProvider>(
                              value: provider,
                              child: Text(provider.label),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        sessionSettingsController.setAiProvider(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: preferences.useCustomAiModel,
                      title: Text(
                        appText(
                          context,
                          en: 'Type model manually',
                          pt: 'Digitar modelo manualmente',
                        ),
                      ),
                      subtitle: Text(
                        appText(
                          context,
                          en: 'Turn off to use a ready model list by provider.',
                          pt: 'Desative para usar uma lista pronta por provedor.',
                        ),
                      ),
                      onChanged: sessionSettingsController.setUseCustomAiModel,
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final activeProvider = preferences.aiProvider;
                        final currentModel =
                            _activeModelForProvider(preferences);

                        if (preferences.useCustomAiModel) {
                          return TextFormField(
                            key: ValueKey<String>(
                              'typed_${activeProvider.name}_$currentModel',
                            ),
                            initialValue: currentModel,
                            decoration: InputDecoration(
                              labelText: appText(
                                context,
                                en: '${activeProvider.label} model',
                                pt: 'Modelo ${activeProvider.label}',
                              ),
                              hintText: activeProvider.defaultModel,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (value) {
                              _saveModelForProvider(
                                provider: activeProvider,
                                model: value,
                              );
                            },
                          );
                        }

                        final modelOptions = activeProvider.presetModels;
                        final normalizedCurrent =
                            activeProvider.normalizeModel(currentModel);
                        final selectedModel = modelOptions.contains(
                          normalizedCurrent,
                        )
                            ? normalizedCurrent
                            : activeProvider.defaultModel;

                        return DropdownButtonFormField<String>(
                          key: ValueKey<String>(
                            'select_${activeProvider.name}_$selectedModel',
                          ),
                          initialValue: selectedModel,
                          decoration: InputDecoration(
                            labelText: appText(
                              context,
                              en: '${activeProvider.label} model list',
                              pt: 'Lista de modelos ${activeProvider.label}',
                            ),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: modelOptions
                              .map(
                                (model) => DropdownMenuItem<String>(
                                  value: model,
                                  child: Text(model),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            _saveModelForProvider(
                              provider: activeProvider,
                              model: value,
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<SessionScene>(
                      key: ValueKey<SessionScene>(preferences.selectedScene),
                      initialValue: preferences.selectedScene,
                      decoration: InputDecoration(
                        labelText: appText(
                          context,
                          en: 'Session Scene',
                          pt: 'Cenario da Sessao',
                        ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _sceneOptions
                          .map(
                            (scene) => DropdownMenuItem<SessionScene>(
                              value: scene,
                              child: Text(_sceneLabel(context, scene)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        sessionSettingsController.setSelectedScene(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: preferences.autoResumeListening,
                      title: Text(
                        appText(
                          context,
                          en: 'Auto resume listening after bot speech',
                          pt: 'Retomar escuta automaticamente apos fala do bot',
                        ),
                      ),
                      subtitle: Text(
                        appText(
                          context,
                          en: 'Keeps the flow natural after each answer.',
                          pt: 'Mantem o fluxo natural apos cada resposta.',
                        ),
                      ),
                      onChanged:
                          sessionSettingsController.setAutoResumeListening,
                    ),
                    SwitchListTile.adaptive(
                      value: preferences.showStartupTips,
                      title: Text(
                        appText(
                          context,
                          en: 'Show startup tips when opening chat',
                          pt: 'Mostrar dicas ao abrir o chat',
                        ),
                      ),
                      subtitle: Text(
                        appText(
                          context,
                          en: 'Useful for new users and onboarding moments.',
                          pt: 'Util para novos usuarios e momentos de onboarding.',
                        ),
                      ),
                      onChanged: sessionSettingsController.setShowStartupTips,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        final hint = preferences.showStartupTips
                            ? appText(
                                context,
                                en: 'Tip: choose your language and focus before speaking.',
                                pt: 'Dica: escolha seu idioma e foco antes de falar.',
                              )
                            : null;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VoiceChatPage(startupHint: hint),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text(
                        appText(
                          context,
                          en: 'Open Voice Session',
                          pt: 'Abrir Sessao de Voz',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(DashboardRoutes.dashboard),
                      icon: const Icon(Icons.home_outlined),
                      label: Text(
                        appText(
                          context,
                          en: 'Back to Dashboard',
                          pt: 'Voltar ao Dashboard',
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context)
                .pushReplacementNamed(DashboardRoutes.dashboard);
            return;
          }

          if (index == 1) {
            Navigator.of(context)
                .pushReplacementNamed(DashboardRoutes.practice);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: appText(context, en: 'Dashboard', pt: 'Dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.insights_outlined),
            activeIcon: const Icon(Icons.insights),
            label: appText(context, en: 'Practice', pt: 'Pratica'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: appText(context, en: 'Session', pt: 'Sessao'),
          ),
        ],
      ),
    );
  }

  String _sceneLabel(BuildContext context, SessionScene scene) {
    switch (scene) {
      case SessionScene.studio:
        return appText(context, en: 'Studio', pt: 'Estudio');
      case SessionScene.city:
        return appText(context, en: 'City', pt: 'Cidade');
      case SessionScene.library:
        return appText(context, en: 'Library', pt: 'Biblioteca');
    }
  }

  String _activeModelForProvider(SessionUiPreferences preferences) {
    switch (preferences.aiProvider) {
      case AiProvider.gemini:
        return preferences.geminiModel;
      case AiProvider.openai:
        return preferences.openAiModel;
    }
  }

  Future<void> _saveModelForProvider({
    required AiProvider provider,
    required String model,
  }) {
    switch (provider) {
      case AiProvider.gemini:
        return sessionSettingsController.setGeminiModel(model);
      case AiProvider.openai:
        return sessionSettingsController.setOpenAiModel(model);
    }
  }
}
