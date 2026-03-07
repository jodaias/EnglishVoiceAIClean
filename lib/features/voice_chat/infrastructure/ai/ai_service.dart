import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/conversation_language.dart';

abstract class AIService {
  Future<String> getResponse({
    required List<Map<String, String>> conversation,
    required ConversationLanguage language,
    String? practiceFocus,
    int? sessionTurns,
  });

  Future<String> getSessionFeedback({
    required List<Map<String, String>> conversation,
    required ConversationLanguage language,
    required String practiceFocus,
    required int sessionTurns,
    required int elapsedSeconds,
  });
}

class GeminiService implements AIService {
  final String geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  @override
  Future<String> getResponse({
    required List<Map<String, String>> conversation,
    required ConversationLanguage language,
    String? practiceFocus,
    int? sessionTurns,
  }) async {
    final prompt = _buildPrompt(
      conversation: conversation,
      language: language,
      practiceFocus: practiceFocus,
      sessionTurns: sessionTurns,
    );
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API error: ${data['error']?['message'] ?? 'Unknown error'}',
      );
    }

    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (text == null) {
      throw Exception('No content returned from Gemini.');
    }

    return text.toString().trim();
  }

  String _buildPrompt({
    required List<Map<String, String>> conversation,
    required ConversationLanguage language,
    String? practiceFocus,
    int? sessionTurns,
  }) {
    final languageRule = language == ConversationLanguage.portugueseBr
        ? 'Responda em portugues brasileiro.'
        : 'Reply in American English.';

    final transcript = conversation
        .map((msg) => '${msg['role']}: ${msg['content']}')
        .join('\n');

    final focus = (practiceFocus ?? 'General conversation').trim();
    final turns = sessionTurns ?? 0;

    return '''
You are a friendly voice English coach with a human-like avatar.
$languageRule
Primary objective: help the user improve spoken English naturally.
Keep every answer concise and voice-friendly.
Use 1 to 4 short sentences unless the user asks for detail.
If the user writes in English and there is a clear mistake, include a gentle correction in plain text.
After answering, ask one short follow-up question to keep conversation practice going.
Avoid markdown, bullet lists, hashtags, and emojis in responses.
Current lesson focus: $focus.
Current session turns so far: $turns.
Conversation transcript:
$transcript
''';
  }

  @override
  Future<String> getSessionFeedback({
    required List<Map<String, String>> conversation,
    required ConversationLanguage language,
    required String practiceFocus,
    required int sessionTurns,
    required int elapsedSeconds,
  }) async {
    final prompt = _buildFeedbackPrompt(
      conversation: conversation,
      language: language,
      practiceFocus: practiceFocus,
      sessionTurns: sessionTurns,
      elapsedSeconds: elapsedSeconds,
    );

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API error: ${data['error']?['message'] ?? 'Unknown error'}',
      );
    }

    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (text == null) {
      throw Exception('No feedback returned from Gemini.');
    }

    return text.toString().trim();
  }

  String _buildFeedbackPrompt({
    required List<Map<String, String>> conversation,
    required ConversationLanguage language,
    required String practiceFocus,
    required int sessionTurns,
    required int elapsedSeconds,
  }) {
    final languageRule = language == ConversationLanguage.portugueseBr
        ? 'Escreva em portugues brasileiro, com exemplos curtos em ingles quando util e para aprendizagem.'
        : 'Write in American English.';

    final transcript = conversation
        .map((msg) => '${msg['role']}: ${msg['content']}')
        .join('\n');

    return '''
You are an English coach creating a concise end-of-session report.
$languageRule
Practice focus: $practiceFocus
User turns: $sessionTurns
Session time in seconds: $elapsedSeconds

Rules:
- Output plain text only.
- Keep report short and practical.
- Include exactly these headings in this order:
Summary:
Estimated Level:
What You Did Well:
Improve Next:
Try These 3 Sentences:
Next Challenge:
- Under "Estimated Level:", use one value only: Beginner, Intermediate, or Advanced.
- Under "Try These 3 Sentences:", provide exactly 3 short English sentences, each on its own line.

Conversation transcript:
$transcript
''';
  }
}
