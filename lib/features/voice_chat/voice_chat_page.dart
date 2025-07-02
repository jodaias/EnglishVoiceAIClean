import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'services/ai_service.dart';
import 'services/speech_service.dart';
import 'services/tts_service.dart';
import 'voice_chat_controller.dart';

class VoiceChatPage extends StatefulWidget {
  @override
  _VoiceChatPageState createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage> {
  late VoiceChatController controller;
  String status = 'Ready';

  @override
  void initState() {
    super.initState();
    controller = VoiceChatController(
      aiService: GeminiService(),
      speechService: SpeechService(),
      ttsService: TTSService(),
    );

    controller.startConversation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speak English with AI'),
        actions: [
          ValueListenableBuilder<String>(
            valueListenable: controller.statusNotifier,
            builder: (context, status, _) => Padding(
              padding: EdgeInsets.all(16),
              child: Text(status),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<String>(
            valueListenable: controller.lottieAssetNotifier,
            builder: (context, lottieAsset, _) => Container(
              height: 200,
              child: Lottie.asset(lottieAsset),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<Map<String, String>>>(
              valueListenable: controller.conversation,
              builder: (context, conversation, _) {
                return ListView.builder(
                  itemCount: conversation.length,
                  itemBuilder: (_, i) {
                    final msg = conversation[i];
                    final isUser = msg['role'] == 'user';
                    return Container(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blueAccent : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Text(
                          msg['content'] ?? '',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ValueListenableBuilder<String>(
            valueListenable: controller.statusNotifier,
            builder: (context, status, _) => Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                status == 'Listening...'
                    ? '🎤 Awaiting your response...'
                    : status == 'AI is speaking...'
                        ? '🤖 AI is speaking...'
                        : '✅ Ready',
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
