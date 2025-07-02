import 'package:english_voice_ai_clean/features/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(VoiceEnglishAIApp());
}

class VoiceEnglishAIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI English Teacher',
      theme: ThemeData.dark(),
      home: SplashPage(),
    );
  }
}
