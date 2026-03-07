import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

enum AIServiceErrorCode {
  missingApiKey,
  unauthorized,
  forbidden,
  rateLimited,
  quotaExceeded,
  serviceUnavailable,
  network,
  invalidResponse,
  unknown,
}

class AIServiceException implements Exception {
  final AIServiceErrorCode code;
  final String message;
  final int? statusCode;

  const AIServiceException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() {
    final status = statusCode == null ? '' : ' (HTTP $statusCode)';
    return 'AIServiceException[$code$status]: $message';
  }
}

class GeminiService implements AIService {
  final String geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final String geminiModel = _resolveGeminiModel();

  static String _resolveGeminiModel() {
    final configuredModel = (dotenv.env['GEMINI_MODEL'] ?? '').trim();
    return configuredModel.isEmpty ? 'gemini-2.5-flash' : configuredModel;
  }

  @override
  Future<String> getResponse({
    required List<Map<String, String>> conversation,
    required ConversationLanguage language,
    String? practiceFocus,
    int? sessionTurns,
  }) async {
    _assertApiKeyConfigured();

    final prompt = _buildPrompt(
      conversation: conversation,
      language: language,
      practiceFocus: practiceFocus,
      sessionTurns: sessionTurns,
    );

    return _requestGeminiText(prompt);
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
    _assertApiKeyConfigured();

    final prompt = _buildFeedbackPrompt(
      conversation: conversation,
      language: language,
      practiceFocus: practiceFocus,
      sessionTurns: sessionTurns,
      elapsedSeconds: elapsedSeconds,
    );

    return _requestGeminiText(prompt);
  }

  void _assertApiKeyConfigured() {
    if (geminiApiKey.trim().isNotEmpty) return;

    throw const AIServiceException(
      code: AIServiceErrorCode.missingApiKey,
      message: 'GEMINI_API_KEY is missing or empty in environment.',
    );
  }

  Future<String> _requestGeminiText(String prompt) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$geminiApiKey',
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

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      final data = _decodeJsonObject(response.body);

      if (response.statusCode != 200) {
        final apiMessage = _extractApiErrorMessage(data);
        throw AIServiceException(
          code: _mapHttpErrorCode(
            statusCode: response.statusCode,
            apiMessage: apiMessage,
          ),
          message: apiMessage,
          statusCode: response.statusCode,
        );
      }

      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text == null) {
        throw const AIServiceException(
          code: AIServiceErrorCode.invalidResponse,
          message: 'No text content returned from Gemini API response.',
        );
      }

      return text.toString().trim();
    } on AIServiceException {
      rethrow;
    } on SocketException catch (error) {
      throw AIServiceException(
        code: AIServiceErrorCode.network,
        message: 'Network error while calling Gemini API: ${error.message}',
      );
    } on TimeoutException {
      throw const AIServiceException(
        code: AIServiceErrorCode.network,
        message: 'Gemini API request timed out.',
      );
    } catch (error) {
      throw AIServiceException(
        code: AIServiceErrorCode.unknown,
        message: 'Unexpected Gemini API failure: $error',
      );
    }
  }

  Map<String, dynamic> _decodeJsonObject(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _extractApiErrorMessage(Map<String, dynamic> data) {
    final message = data['error']?['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'Unknown Gemini API error.';
  }

  AIServiceErrorCode _mapHttpErrorCode({
    required int statusCode,
    required String apiMessage,
  }) {
    final normalizedMessage = apiMessage.toLowerCase();

    if (statusCode == 401) return AIServiceErrorCode.unauthorized;
    if (statusCode == 403) {
      if (normalizedMessage.contains('quota') ||
          normalizedMessage.contains('rate limit')) {
        return AIServiceErrorCode.quotaExceeded;
      }
      return AIServiceErrorCode.forbidden;
    }
    if (statusCode == 429) return AIServiceErrorCode.rateLimited;
    if (statusCode >= 500) return AIServiceErrorCode.serviceUnavailable;
    return AIServiceErrorCode.unknown;
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

class OpenAIService implements AIService {
  final String openAiApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String model = _resolveOpenAiModel();

  static String _resolveOpenAiModel() {
    final configuredModel = (dotenv.env['OPENAI_MODEL'] ?? '').trim();
    return configuredModel.isEmpty ? 'gpt-4.1' : configuredModel;
  }

  @override
  Future<String> getResponse({
    required List<Map<String, String>> conversation,
    required ConversationLanguage language,
    String? practiceFocus,
    int? sessionTurns,
  }) async {
    _assertApiKeyConfigured();

    final prompt = _buildPrompt(
      conversation: conversation,
      language: language,
      practiceFocus: practiceFocus,
      sessionTurns: sessionTurns,
    );

    return _requestOpenAIText(prompt);
  }

  @override
  Future<String> getSessionFeedback({
    required List<Map<String, String>> conversation,
    required ConversationLanguage language,
    required String practiceFocus,
    required int sessionTurns,
    required int elapsedSeconds,
  }) async {
    _assertApiKeyConfigured();

    final prompt = _buildFeedbackPrompt(
      conversation: conversation,
      language: language,
      practiceFocus: practiceFocus,
      sessionTurns: sessionTurns,
      elapsedSeconds: elapsedSeconds,
    );

    return _requestOpenAIText(prompt);
  }

  void _assertApiKeyConfigured() {
    if (openAiApiKey.trim().isNotEmpty) return;

    throw const AIServiceException(
      code: AIServiceErrorCode.missingApiKey,
      message: 'OPENAI_API_KEY is missing or empty in environment.',
    );
  }

  Future<String> _requestOpenAIText(String prompt) async {
    const endpoint = 'https://api.openai.com/v1/chat/completions';
    final url = Uri.parse(endpoint);

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.6,
    });

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $openAiApiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      final data = _decodeJsonObject(response.body);

      if (response.statusCode != 200) {
        final apiMessage = _extractApiErrorMessage(data);
        throw AIServiceException(
          code: _mapHttpErrorCode(
            statusCode: response.statusCode,
            apiMessage: apiMessage,
          ),
          message: apiMessage,
          statusCode: response.statusCode,
        );
      }

      final text = data['choices']?[0]?['message']?['content'];
      if (text is! String || text.trim().isEmpty) {
        throw const AIServiceException(
          code: AIServiceErrorCode.invalidResponse,
          message: 'No text content returned from OpenAI response.',
        );
      }

      return text.trim();
    } on AIServiceException {
      rethrow;
    } on SocketException catch (error) {
      throw AIServiceException(
        code: AIServiceErrorCode.network,
        message: 'Network error while calling OpenAI API: ${error.message}',
      );
    } on TimeoutException {
      throw const AIServiceException(
        code: AIServiceErrorCode.network,
        message: 'OpenAI API request timed out.',
      );
    } catch (error) {
      throw AIServiceException(
        code: AIServiceErrorCode.unknown,
        message: 'Unexpected OpenAI API failure: $error',
      );
    }
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

  Map<String, dynamic> _decodeJsonObject(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _extractApiErrorMessage(Map<String, dynamic> data) {
    final message = data['error']?['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'Unknown OpenAI API error.';
  }

  AIServiceErrorCode _mapHttpErrorCode({
    required int statusCode,
    required String apiMessage,
  }) {
    final normalizedMessage = apiMessage.toLowerCase();

    if (statusCode == 401) return AIServiceErrorCode.unauthorized;
    if (statusCode == 403) return AIServiceErrorCode.forbidden;
    if (statusCode == 429) {
      if (normalizedMessage.contains('quota')) {
        return AIServiceErrorCode.quotaExceeded;
      }
      return AIServiceErrorCode.rateLimited;
    }
    if (statusCode >= 500) return AIServiceErrorCode.serviceUnavailable;
    return AIServiceErrorCode.unknown;
  }
}
