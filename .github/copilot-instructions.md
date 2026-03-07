# Copilot Instructions - EnglishVoiceAIClean

## Objetivo do Produto
Aplicativo de conversacao por voz com avatar que compreende e responde em `en-US` e `pt-BR`, com comportamento natural de assistente humano.

## Arquitetura Obrigatoria
Use esta estrutura para qualquer evolucao:

- `lib/features/voice_chat/presentation/`: telas, widgets e estados visuais
- `lib/features/voice_chat/application/`: orquestracao da conversa e regras de fluxo
- `lib/features/voice_chat/domain/`: entidades, enums e regras puras de negocio
- `lib/features/voice_chat/infrastructure/`: integracoes externas (STT, TTS, LLM, APIs)

## Regras de Conversacao Bilingue
- Sempre suportar `en_US` e `pt_BR`.
- Quando o modo for `auto`, tentar captacao em `en_US` e fallback em `pt_BR`.
- Detectar idioma da entrada para definir idioma da resposta.
- Responder no mesmo idioma do usuario, exceto quando ele pedir traducao ou troca de idioma.
- Se o usuario ficar em silencio por ciclos consecutivos de escuta, pausar a conversa automaticamente.
- Exibir acao clara para retomar a conversa apos pausa por inatividade.

## Regras de Avatar
- Avatar deve ter ao menos dois estados: `idle/listening` e `talking`.
- Trocar animacao conforme estado de TTS e STT.
- Nao ouvir enquanto o TTS estiver ativo para evitar eco.

## Regras de IA
- Prompt de sistema deve definir persona amigavel, objetiva e natural.
- Respostas curtas por padrao (1-4 frases), com tom conversacional humano.
- Se a entrada estiver em portugues, responder em portugues brasileiro.
- Se a entrada estiver em ingles, responder em ingles americano.
- Priorizar aprendizado de ingles: corrigir erros de forma gentil quando houver erro claro.
- Sempre manter a conversa ativa com uma pergunta curta de continuidade.
- Evitar markdown e listas na resposta falada para melhorar naturalidade do TTS.

## Padrao de Codigo
- Evitar logica de negocio em widgets.
- Evitar loop infinito sem cancelamento.
- Toda classe de servico externo deve ter interface clara e metodos assincronos.
- Incluir tratamento de erro com fallback amigavel para o usuario.

## Qualidade
Antes de finalizar alteracoes:
- garantir que imports antigos continuem funcionando (arquivos ponte quando necessario);
- validar que o fluxo voz -> IA -> voz nao bloqueia UI;
- validar comportamento em `en_US` e `pt_BR`.

## Nao Fazer
- Nao codificar idioma fixo unico.
- Nao acoplar STT, TTS e IA diretamente na tela.
- Nao remover estados de avatar durante a fala.

## Dependencias Principais (pubspec.yaml)
- `flutter` SDK >=3.0.0 <4.0.0
- `http: ^0.13.6` — chamadas HTTP (API Gemini)
- `speech_to_text: ^7.3.0` — reconhecimento de voz (STT)
- `flutter_tts: ^3.6.3` — sintese de voz (TTS)
- `flutter_dotenv: ^5.1.0` — carregamento de variaveis de ambiente
- `lottie: ^2.6.0` — animacoes do avatar
- `hive_flutter: ^1.1.0` — persistencia local (preferencias, historico)

## Gerenciamento de Estado
- **Sem pacotes externos** (sem Riverpod, Bloc, Provider, etc.).
- Usa `ValueNotifier` + `ValueListenableBuilder` em todo o app.
- `AppSettingsScope` (InheritedWidget) distribui configuracoes globais na arvore.

## Comandos Uteis
```bash
flutter run                              # Rodar em debug
flutter build apk --release --split-per-abi  # Build Android release
flutter test                             # Rodar todos os testes
flutter test test/features/voice_chat/application/  # Testes de application
flutter pub run flutter_launcher_icons:main  # Gerar icones
flutter pub run flutter_native_splash:create # Gerar splash
```

## Variaveis de Ambiente
- Arquivo `.env` (mobile) e `env/web.env` (web).
- Chaves esperadas: `GEMINI_API_KEY`, flags de feature opcionais.
- Carregamento via `flutter_dotenv` no `main.dart`.

## Rotas (DashboardRoutes)
- `/dashboard` — tela principal
- `/practice` — overview de pratica
- `/reading-listening` — exercicios de leitura/escuta
- `/session-history` — historico de sessoes
- `/session` — tela de conversa por voz (VoiceChatPage)
- `/language` — selecao de idioma

## Resumo dos Arquivos-Chave

### Application (orquestracao)
- `voice_chat_controller.dart`: Controlador principal do loop voz→IA→voz. ValueNotifiers: `conversation`, `statusNotifier`, `lottieAssetNotifier`, `languageNotifier`, `isPausedNotifier`. Metodos: `startConversation()`, `setPreferredLanguage()`, `setPracticeFocus()`, `setSpeechSpeedMultiplier()`, `confirmPendingUserInput()`.
- `app_settings_controller.dart`: Persiste locale do app (en-US/pt-BR). Notifier: `appLocaleNotifier`. Metodos: `load()`, `setAppLocale()`.
- `session_settings_controller.dart`: Preferencias por sessao (cena, provider IA, modelo, flags). Notifier: `preferencesNotifier` (SessionUiPreferences). Metodos: `setSelectedScene()`, `setAiProvider()`, `setGeminiModel()`, `setAutoResumeListening()`, `setReviewBeforeSend()`.
- `voice_chat_session_config.dart`: Config imutavel de timings do loop (sttListenFor, sttPauseFor, maxSilentTurnsBeforePause, etc.). Factory: `fromEnv()`.
- `app_feature_flags.dart`: Flags de feature: `premiumInsightsEnabled`, `premiumDailyChallengePlusEnabled`. Factory: `fromEnv()`.
- `session_history_repository.dart`: Interface de repositorio de historico.
- `session_history_service.dart`: Servico de historico de sessoes.
- `pronunciation_comparer.dart`: Compara pronuncia do usuario com referencia.
- `reading_listening_catalog.dart` / `reading_listening_controller.dart`: Catalogo e controlador de exercicios.
- `practice_hub_controller.dart`: Controlador do hub de pratica.

### Infrastructure (integracoes externas)
- `ai_service.dart`: Interface `AIService` + implementacao `GeminiService` (REST, modelo padrao `gemini-2.5-flash`). Metodos: `getResponse()`, `getSessionFeedback()`.
- `speech_service.dart`: Wrapper STT com adapter pattern. Classes: `SpeechRecognizerAdapter`, `SpeechToTextAdapter`, `SpeechService`. Metodo: `listen()`.
- `tts_service.dart`: Wrapper TTS com selecao de voz por locale. Metodos: `speak()`, `stop()`, `setRate()`. Prefere vozes neural/premium.
- `local_session_history_repository.dart`: Persistencia Hive para historico.
- `local_user_preferences_repository.dart`: Persistencia Hive para preferencias.
- `stt_pronunciation_capture_service.dart`: Captura de pronuncia via STT.
- `learning_audio_tts_service.dart`: Audio para exercicios de aprendizado.

### Domain (entidades)
- `conversation_message.dart`: `ConversationMessage(role, content)` — mensagem imutavel.
- `session_scene.dart`: Enum `SessionScene` {studio, city, library} com `assetPath`.
- `app_locale.dart`: Enum/classe de locale do app.
- `conversation_language.dart`: Enum de idioma da conversa.
- `ai_provider.dart`: Enum de provedores de IA.
- `pronunciation_result.dart`: Resultado de avaliacao de pronuncia.
- `session_ui_preferences.dart`: Preferencias visuais da sessao.
- `daily_challenge.dart` / `daily_challenge_history.dart`: Desafio diario.
- `practice_session_record.dart`: Registro de sessao de pratica.
- `reading_listening_exercise.dart`: Exercicio de leitura/escuta.

### Presentation (telas)
- `voice_chat_page.dart`: Tela principal de conversa por voz com avatar.
- `initial_dashboard_page.dart`: Dashboard principal com navegacao.
- `app_settings_scope.dart`: InheritedWidget — accessors: `controllerOf()`, `localeOf()`.
- `session_settings_page.dart`: Tela de configuracoes da sessao.
- `language_mode_page.dart`: Selecao de idioma.
- `practice_overview_page.dart`: Visao geral de pratica.
- `reading_listening_page.dart`: Tela de exercicios.
- `session_history_page.dart`: Historico de sessoes.
- `responsive_content_shell.dart`: Shell responsivo para conteudo.
- `practice_hub_sheet.dart`: Bottom sheet do hub de pratica.
- `dashboard_routes.dart`: Constantes de rotas.
- `app_text.dart`: Textos localizados do app.

## Estrutura Completa do Projeto

```
lib/
├── main.dart                          # Entry point do app
├── features/
│   ├── splash/
│   │   └── splash_page.dart           # Tela de splash/loading inicial
│   └── voice_chat/
│       ├── application/               # Orquestracao, controllers, regras de fluxo
│       │   ├── app_feature_flags.dart
│       │   ├── app_settings_controller.dart
│       │   ├── learning_audio_service.dart
│       │   ├── practice_hub_controller.dart
│       │   ├── pronunciation_capture_service.dart
│       │   ├── pronunciation_comparer.dart
│       │   ├── reading_listening_catalog.dart
│       │   ├── reading_listening_controller.dart
│       │   ├── session_history_repository.dart
│       │   ├── session_history_service.dart
│       │   ├── session_settings_controller.dart
│       │   ├── voice_chat_controller.dart
│       │   └── voice_chat_session_config.dart
│       ├── domain/                    # Entidades, enums, regras de negocio puras
│       │   └── entities/
│       │       ├── ai_provider.dart
│       │       ├── app_locale.dart
│       │       ├── conversation_language.dart
│       │       ├── conversation_message.dart
│       │       ├── daily_challenge.dart
│       │       ├── daily_challenge_history.dart
│       │       ├── practice_session_record.dart
│       │       ├── pronunciation_result.dart
│       │       ├── reading_listening_exercise.dart
│       │       ├── session_scene.dart
│       │       └── session_ui_preferences.dart
│       ├── infrastructure/            # Integracoes externas (STT, TTS, LLM, storage)
│       │   ├── ai/
│       │   │   └── ai_service.dart
│       │   ├── local/
│       │   │   ├── local_session_history_repository.dart
│       │   │   └── local_user_preferences_repository.dart
│       │   ├── speech/
│       │   │   ├── speech_service.dart
│       │   │   └── stt_pronunciation_capture_service.dart
│       │   └── tts/
│       │       ├── learning_audio_tts_service.dart
│       │       └── tts_service.dart
│       └── presentation/             # Telas, widgets, estados visuais
│           ├── app_settings_scope.dart
│           ├── app_text.dart
│           ├── dashboard_routes.dart
│           ├── initial_dashboard_page.dart
│           ├── language_mode_page.dart
│           ├── practice_hub_sheet.dart
│           ├── practice_overview_page.dart
│           ├── reading_listening_page.dart
│           ├── responsive_content_shell.dart
│           ├── session_history_page.dart
│           ├── session_settings_page.dart
│           └── voice_chat_page.dart

test/
└── features/
    └── voice_chat/
        ├── application/
        │   ├── app_settings_controller_persistence_test.dart
        │   ├── practice_hub_controller_integration_test.dart
        │   ├── pronunciation_comparer_test.dart
        │   ├── reading_listening_controller_test.dart
        │   ├── session_settings_controller_persistence_test.dart
        │   ├── voice_chat_controller_test.dart
        │   └── voice_chat_session_config_test.dart
        ├── infrastructure/
        │   └── speech/
        │       └── speech_service_test.dart
        └── presentation/
            ├── responsive_content_shell_test.dart
            └── session_settings_page_test.dart

assets/
├── images/
│   ├── englishaichat_logo.png
│   └── scenes/
│       ├── city_scene.png
│       ├── library_scene.png
│       └── studio_scene.png
└── lottie/
    ├── robot_idle.json                # Animacao avatar idle/listening
    └── robot_talking.json             # Animacao avatar falando

env/
└── web.env                            # Variaveis de ambiente (API keys)
```
