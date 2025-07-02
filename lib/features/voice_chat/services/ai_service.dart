import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

abstract class AIService {
  Future<String> getResponse(List<Map<String, String>> conversation);
}

class OpenAIService implements AIService {
  final String openAIApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<String> getResponse(List<Map<String, String>> conversation) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $openAIApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content":
                "You're a friendly English teacher. Keep responses short and helpful."
          },
          ...conversation
              .map((e) => {"role": e['role'], "content": e['content']})
              .toList(),
        ]
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
          "OpenAI API error: ${data['error']?['message'] ?? 'Unknown error'}");
    }

    return data['choices'][0]['message']['content'].toString().trim();
  }
}

class GeminiService implements AIService {
  final String geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<String> getResponse(List<Map<String, String>> conversation) async {
    final prompt = _convertConversationToPrompt(conversation);
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey');

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
          "Gemini API error: ${data['error']?['message'] ?? 'Unknown error'}");
    }

    final text = data['candidates']?[0]['content']?['parts']?[0]?['text'];
    if (text == null) {
      throw Exception("No content returned from Gemini.");
    }

    return text.toString().trim();
  }

  String _convertConversationToPrompt(List<Map<String, String>> conversation) {
    return "system: You're a friendly English teacher. Keep responses short and helpful. ${conversation.map((msg) => "${msg['role']}: ${msg['content']}").join("\n")}";
  }
}
