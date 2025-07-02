import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/voice_chat/voice_chat_page.dart';

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
      home: VoiceChatPage(),
    );
  }
}
