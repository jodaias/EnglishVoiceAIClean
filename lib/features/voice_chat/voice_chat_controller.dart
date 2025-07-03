import 'package:flutter/material.dart';
import 'services/ai_service.dart';
import 'services/speech_service.dart';
import 'services/tts_service.dart';

class VoiceChatController {
  final AIService aiService;
  final SpeechService speechService;
  final TTSService ttsService;

  ValueNotifier<List<Map<String, String>>> conversation = ValueNotifier([]);

  String lastAIResponse = "Hello! Let's practice English. How are you today?";

  bool isSpeaking = false;

  ValueNotifier<String> statusNotifier = ValueNotifier('Ready');
  ValueNotifier<String> lottieAssetNotifier =
      ValueNotifier('assets/lottie/robot_idle.json');

  VoiceChatController({
    required this.aiService,
    required this.speechService,
    required this.ttsService,
  });

  Future<void> startConversation() async {
    final greeting = lastAIResponse;
    robotTalking();
    await ttsService.speak(greeting);
    robotIdle();

    conversation.value = [
      ...conversation.value,
      {'role': 'ai', 'content': greeting}
    ];

    await Future.delayed(Duration(milliseconds: 300));
    _startLoop();
  }

  Future<void> _startLoop() async {
    while (true) {
      robotIdle();
      await processConversation();
      await Future.delayed(Duration(milliseconds: 300));
    }
  }

  void updateStatus(String status, String lottieAsset) {
    statusNotifier.value = status;
    lottieAssetNotifier.value = lottieAsset;
  }

  void robotTalking() {
    isSpeaking = true;
    updateStatus('AI is speaking...', 'assets/lottie/robot_talking.json');
  }

  void robotIdle() {
    isSpeaking = false;
    updateStatus('Listening...', 'assets/lottie/robot_idle.json');
  }

  Future<String?> processConversation() async {
    final userInput = await speechService.listen(isSpeaking: isSpeaking);
    if (userInput == null || userInput.isEmpty) return null;

    conversation.value = [
      ...conversation.value,
      {'role': 'user', 'content': userInput}
    ];

    if (userInput.toLowerCase().contains('repeat')) {
      robotTalking();
      await ttsService.speak(lastAIResponse);
      robotIdle();
      return userInput;
    }

    if (userInput.toLowerCase().contains('slow down')) {
      await ttsService.setRate(0.3);
      robotTalking();
      await ttsService.speak("Speaking slower now.");
      robotIdle();
      return userInput;
    } else {
      await ttsService.setRate(0.6);
    }

    final aiResponse = await aiService.getResponse(conversation.value);

    conversation.value = [
      ...conversation.value,
      {'role': 'ai', 'content': aiResponse}
    ];
    lastAIResponse = aiResponse;

    robotTalking();
    await ttsService.speak(aiResponse);
    robotIdle();

    return userInput;
  }
}
