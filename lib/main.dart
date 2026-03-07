import 'package:english_voice_ai_clean/features/splash/splash_page.dart';
import 'package:english_voice_ai_clean/features/voice_chat/application/app_settings_controller.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/app_locale.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/local/local_user_preferences_repository.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/app_settings_scope.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/dashboard_routes.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/initial_dashboard_page.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/language_mode_page.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/practice_overview_page.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/reading_listening_page.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/session_history_page.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/session_settings_page.dart';
import 'package:english_voice_ai_clean/features/voice_chat/presentation/video_call_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await dotenv.load(fileName: kIsWeb ? 'env/web.env' : '.env');
  runApp(const VoiceEnglishAIApp());
}

class VoiceEnglishAIApp extends StatefulWidget {
  const VoiceEnglishAIApp({super.key});

  @override
  State<VoiceEnglishAIApp> createState() => _VoiceEnglishAIAppState();
}

class _VoiceEnglishAIAppState extends State<VoiceEnglishAIApp> {
  late final AppSettingsController appSettingsController;

  @override
  void initState() {
    super.initState();
    appSettingsController = AppSettingsController(
      preferencesRepository: LocalUserPreferencesRepository(),
    );
    appSettingsController.load();
  }

  @override
  void dispose() {
    appSettingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLocale>(
      valueListenable: appSettingsController.appLocaleNotifier,
      builder: (context, appLocale, _) {
        return AppSettingsScope(
          controller: appSettingsController,
          locale: appLocale,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'AI English Teacher',
            theme: ThemeData.dark(),
            locale: Locale(appLocale.languageCode, appLocale.countryCode),
            home: const SplashPage(),
            routes: {
              DashboardRoutes.dashboard: (_) => const InitialDashboardPage(),
              DashboardRoutes.practice: (_) => const PracticeOverviewPage(),
              DashboardRoutes.readingListening: (_) =>
                  const ReadingListeningPage(),
              DashboardRoutes.sessionHistory: (_) => const SessionHistoryPage(),
              DashboardRoutes.session: (_) => const SessionSettingsPage(),
              DashboardRoutes.language: (_) => const LanguageModePage(),
              DashboardRoutes.videoCall: (_) => const VideoCallPage(),
            },
          ),
        );
      },
    );
  }
}
