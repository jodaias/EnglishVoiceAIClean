import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'session_history_repository.dart';
import '../domain/entities/conversation_language.dart';
import '../domain/entities/conversation_message.dart';
import '../domain/entities/practice_session_record.dart';
import '../infrastructure/ai/ai_service.dart';
import '../infrastructure/speech/speech_service.dart';
import '../infrastructure/tts/tts_service.dart';

class VoiceChatController {
  AIService _aiService;
  final SpeechService speechService;
  final TTSService ttsService;

  final ValueNotifier<List<Map<String, String>>> conversation = ValueNotifier(
    [],
  );
  final ValueNotifier<String> statusNotifier = ValueNotifier('Ready');
  final ValueNotifier<String> lottieAssetNotifier = ValueNotifier(
    'assets/lottie/robot_idle.json',
  );
  final ValueNotifier<ConversationLanguage> languageNotifier = ValueNotifier(
    ConversationLanguage.auto,
  );
  final ValueNotifier<bool> isPausedNotifier = ValueNotifier(false);
  final ValueNotifier<int> userTurnsNotifier = ValueNotifier(0);
  final ValueNotifier<int> elapsedSecondsNotifier = ValueNotifier(0);
  final ValueNotifier<String> practiceFocusNotifier = ValueNotifier(
    'General conversation',
  );
  final ValueNotifier<String?> sessionFeedbackNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isGeneratingFeedbackNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isInResumeGraceNotifier = ValueNotifier(false);
  final ValueNotifier<double> speechSpeedMultiplierNotifier =
      ValueNotifier<double>(1.0);
  final ValueNotifier<bool> requiresInputReviewNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> isReviewingUserInputNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<String> pendingUserInputNotifier = ValueNotifier('');

  bool _isActive = false;
  bool _isSpeaking = false;
  ConversationLanguage _pendingEditLanguage = ConversationLanguage.englishUs;
  int _silentTurns = 0;
  Timer? _sessionTicker;
  DateTime? _sessionStartedAt;
  ConversationLanguage _lastDetectedLanguage = ConversationLanguage.englishUs;
  ConversationLanguage _autoNextPrimaryLanguage =
      ConversationLanguage.englishUs;
  final int maxSilentTurnsBeforePause;
  final Duration loopDelay;
  final Duration pausedPollDelay;
  final Duration resumeGracePeriod;
  final SessionHistoryRepository? sessionHistoryRepository;
  DateTime? _resumeGraceUntil;
  bool _autoResumeListening = true;
  static const List<double> _speedMultipliers = <double>[0.5, 1.0, 1.5, 2.0];
  static const double _baseTtsRateWeb = 0.7;
  static const double _baseTtsRateMobile = 0.5;
  String _lastAIResponse =
      'Hello! I can talk in English and Portuguese. How can I help you today?';

  VoiceChatController({
    required AIService aiService,
    required this.speechService,
    required this.ttsService,
    this.maxSilentTurnsBeforePause = 2,
    this.loopDelay = const Duration(milliseconds: 250),
    this.pausedPollDelay = const Duration(milliseconds: 250),
    this.resumeGracePeriod = const Duration(seconds: 2),
    this.sessionHistoryRepository,
  }) : _aiService = aiService;

  void updateAiService(AIService aiService) {
    _aiService = aiService;
  }

  Future<void> startConversation() async {
    if (_isActive) return;

    _isActive = true;
    isPausedNotifier.value = false;
    _silentTurns = 0;
    userTurnsNotifier.value = 0;
    elapsedSecondsNotifier.value = 0;
    sessionFeedbackNotifier.value = null;
    isGeneratingFeedbackNotifier.value = false;
    _lastDetectedLanguage = ConversationLanguage.englishUs;
    _autoNextPrimaryLanguage = ConversationLanguage.englishUs;
    _resumeGraceUntil = null;
    isInResumeGraceNotifier.value = false;
    _sessionStartedAt = DateTime.now();
    _startSessionTicker();

    await _speakAI(_lastAIResponse, language: ConversationLanguage.englishUs);

    _appendMessage(ConversationMessage(role: 'ai', content: _lastAIResponse));

    unawaited(_runConversationLoop());
  }

  void setPreferredLanguage(ConversationLanguage language) {
    languageNotifier.value = language;
    if (_isActive && isPausedNotifier.value) {
      resumeConversation();
    }
  }

  void setPracticeFocus(String focus) {
    final normalized = focus.trim();
    if (normalized.isEmpty) return;
    practiceFocusNotifier.value = normalized;
  }

  void setAutoResumeListening(bool value) {
    _autoResumeListening = value;
  }

  void setRequireInputReview(bool value) {
    requiresInputReviewNotifier.value = value;
  }

  void updatePendingUserInput(String value) {
    if (!isReviewingUserInputNotifier.value) {
      return;
    }
    pendingUserInputNotifier.value = value;
  }

  Future<bool> confirmPendingUserInput() async {
    final text = pendingUserInputNotifier.value.trim();
    if (text.isEmpty) return false;

    final language = _pendingEditLanguage;

    // Pause loop to avoid conflicts during edit-resend.
    isPausedNotifier.value = true;
    _dismissReviewPanel();

    // Remove the last user + AI exchange from conversation.
    _removeLastExchange();

    // Process edited text through AI.
    _appendMessage(ConversationMessage(role: 'user', content: text));
    _lastDetectedLanguage = language;

    try {
      final aiResponse = await _aiService.getResponse(
        conversation: conversation.value,
        language: language,
        practiceFocus: practiceFocusNotifier.value,
        sessionTurns: userTurnsNotifier.value,
      );
      _lastAIResponse = aiResponse;
      _appendMessage(ConversationMessage(role: 'ai', content: aiResponse));
      await _speakAI(aiResponse, language: language);
    } catch (error) {
      final fallback = _buildAiReplyFallback(
        language: language,
        error: error,
      );
      _appendMessage(ConversationMessage(role: 'ai', content: fallback));
      await _speakAI(fallback, language: language);
    }

    if (requiresInputReviewNotifier.value) {
      _showReviewPanel(text, language);
    }

    if (_autoResumeListening) {
      isPausedNotifier.value = false;
    }

    return true;
  }

  void dismissReviewPanel() {
    _dismissReviewPanel();
  }

  Future<void> setSpeechSpeedMultiplier(
    double multiplier, {
    required ConversationLanguage language,
    String origin = 'manual',
  }) async {
    final normalized = _closestSupportedMultiplier(multiplier);
    await _applySpeechSpeedMultiplier(
      multiplier: normalized,
      language: language,
      origin: origin,
    );
  }

  Future<void> configureInitialSpeechSpeedMultiplier(double multiplier) async {
    final normalized = _closestSupportedMultiplier(multiplier);
    speechSpeedMultiplierNotifier.value = normalized;
    await ttsService.setRate(_ttsRateForMultiplier(normalized));
  }

  void pauseConversation({bool fromInactivity = false}) {
    if (!_isActive) return;

    _dismissReviewPanel();

    isPausedNotifier.value = true;
    _setAvatarIdle();

    final preferred = languageNotifier.value;
    if (fromInactivity) {
      statusNotifier.value = preferred == ConversationLanguage.portugueseBr
          ? 'Sem resposta por alguns segundos. Conversa pausada.'
          : 'No response for a few seconds. Conversation paused.';
      return;
    }

    statusNotifier.value = preferred == ConversationLanguage.portugueseBr
        ? 'Conversa pausada.'
        : 'Conversation paused.';
  }

  void resumeConversation() {
    if (!_isActive) return;

    _silentTurns = 0;
    _resumeGraceUntil = DateTime.now().add(resumeGracePeriod);
    isInResumeGraceNotifier.value = true;
    isPausedNotifier.value = false;
    _setAvatarIdle();

    final preferred = languageNotifier.value;
    statusNotifier.value = preferred == ConversationLanguage.portugueseBr
        ? 'Escuta retomada. Aguarde e fale quando quiser.'
        : 'Listening resumed. Take a breath and speak when ready.';
  }

  void dispose() {
    _isActive = false;
    _dismissReviewPanel();
    isPausedNotifier.value = true;
    isGeneratingFeedbackNotifier.value = false;
    isInResumeGraceNotifier.value = false;
    speechSpeedMultiplierNotifier.dispose();
    requiresInputReviewNotifier.dispose();
    isReviewingUserInputNotifier.dispose();
    pendingUserInputNotifier.dispose();
    _stopSessionTicker();
    unawaited(ttsService.stop());
  }

  Future<void> endSessionWithFeedback() async {
    if (!_isActive || isGeneratingFeedbackNotifier.value) return;

    pauseConversation();
    isGeneratingFeedbackNotifier.value = true;
    statusNotifier.value =
        _lastDetectedLanguage == ConversationLanguage.portugueseBr
            ? 'Gerando feedback da sessao...'
            : 'Generating session feedback...';

    try {
      final rawFeedback = await _aiService.getSessionFeedback(
        conversation: conversation.value,
        language: _lastDetectedLanguage,
        practiceFocus: practiceFocusNotifier.value,
        sessionTurns: userTurnsNotifier.value,
        elapsedSeconds: elapsedSecondsNotifier.value,
      );
      final feedback = _normalizeFeedback(
        rawFeedback,
        language: _lastDetectedLanguage,
      );

      sessionFeedbackNotifier.value = feedback;
      _appendMessage(ConversationMessage(role: 'ai', content: feedback));
      statusNotifier.value =
          _lastDetectedLanguage == ConversationLanguage.portugueseBr
              ? 'Feedback pronto. Revise e retome quando quiser.'
              : 'Feedback ready. Review it and resume whenever you want.';
    } catch (_) {
      sessionFeedbackNotifier.value = _buildStructuredFeedbackFallback(
        language: _lastDetectedLanguage,
      );
      statusNotifier.value =
          _lastDetectedLanguage == ConversationLanguage.portugueseBr
              ? 'Falha ao gerar feedback.'
              : 'Failed to generate feedback.';
    } finally {
      await _persistSession();
      isGeneratingFeedbackNotifier.value = false;
    }
  }

  String _normalizeFeedback(
    String raw, {
    required ConversationLanguage language,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return _buildStructuredFeedbackFallback(language: language);
    }

    final requiredHeadings = <String>[
      'Summary:',
      'Estimated Level:',
      'What You Did Well:',
      'Improve Next:',
      'Try These 3 Sentences:',
      'Next Challenge:',
    ];

    final hasAllHeadings = requiredHeadings.every(
        (heading) => trimmed.toLowerCase().contains(heading.toLowerCase()));
    if (hasAllHeadings) {
      return trimmed;
    }

    return _buildStructuredFeedbackFallback(
        language: language, rawHint: trimmed);
  }

  String _buildStructuredFeedbackFallback({
    required ConversationLanguage language,
    String? rawHint,
  }) {
    final estimatedLevel = _estimateLevel(
      turns: userTurnsNotifier.value,
      elapsedSeconds: elapsedSecondsNotifier.value,
    );

    final summary = language == ConversationLanguage.portugueseBr
        ? 'Você concluiu uma prática focada em ${practiceFocusNotifier.value} e manteve a conversa ativa.'
        : 'You completed a focused practice on ${practiceFocusNotifier.value} and kept the conversation active.';

    final didWell = language == ConversationLanguage.portugueseBr
        ? 'Boa consistência em manter turnos de fala durante a sessão.'
        : 'Great consistency keeping your speaking turns active during the session.';

    final improveNext = language == ConversationLanguage.portugueseBr
        ? 'Na próxima sessão, tente respostas um pouco mais longas e conectores simples.'
        : 'In the next session, try slightly longer answers and simple connectors.';

    final nextChallenge = language == ConversationLanguage.portugueseBr
        ? 'Repita as frases e grave uma rodada de 5 minutos sem pausas longas.'
        : 'Repeat the sentences and complete one 5-minute round without long pauses.';

    final hint = (rawHint ?? '').trim();
    final maybeHint = hint.isEmpty
        ? ''
        : language == ConversationLanguage.portugueseBr
            ? '\nResumo adicional: $hint\n'
            : '\nAdditional note: $hint\n';

    return '''
Summary:
$summary$maybeHint
Estimated Level:
$estimatedLevel

What You Did Well:
$didWell

Improve Next:
$improveNext

Try These 3 Sentences:
I can describe my day clearly.
I will use one new expression today.
Can you correct this sentence for me?

Next Challenge:
$nextChallenge
'''
        .trim();
  }

  String _estimateLevel({required int turns, required int elapsedSeconds}) {
    if (turns >= 12 && elapsedSeconds >= 600) {
      return 'Advanced';
    }
    if (turns >= 6 && elapsedSeconds >= 240) {
      return 'Intermediate';
    }
    return 'Beginner';
  }

  Future<void> _runConversationLoop() async {
    while (_isActive) {
      if (isPausedNotifier.value) {
        await Future.delayed(pausedPollDelay);
        continue;
      }

      final capturedInput = await _captureUserInput();
      if (!_isActive) return;
      if (isPausedNotifier.value) continue;

      if (capturedInput == null || capturedInput.text.trim().isEmpty) {
        if (_isInResumeGracePeriod()) {
          await Future.delayed(loopDelay);
          continue;
        }

        _silentTurns += 1;
        if (_silentTurns >= maxSilentTurnsBeforePause) {
          pauseConversation(fromInactivity: true);
        }
        await Future.delayed(loopDelay);
        continue;
      }

      // New user input - dismiss any edit panel from the previous turn.
      _dismissReviewPanel();

      _silentTurns = 0;
      _resumeGraceUntil = null;
      isInResumeGraceNotifier.value = false;
      userTurnsNotifier.value = userTurnsNotifier.value + 1;

      final userInput = capturedInput.text;
      final detectedLanguage = capturedInput.language;
      _lastDetectedLanguage = detectedLanguage;
      _appendMessage(ConversationMessage(role: 'user', content: userInput));

      final commandHandled = await _handleCommand(
        userInput: userInput,
        language: detectedLanguage,
      );

      if (commandHandled) {
        await Future.delayed(loopDelay);
        continue;
      }

      try {
        final aiResponse = await _aiService.getResponse(
          conversation: conversation.value,
          language: detectedLanguage,
          practiceFocus: practiceFocusNotifier.value,
          sessionTurns: userTurnsNotifier.value,
        );

        _lastAIResponse = aiResponse;
        _appendMessage(ConversationMessage(role: 'ai', content: aiResponse));
        await _speakAI(aiResponse, language: detectedLanguage);
      } catch (error) {
        final fallback = _buildAiReplyFallback(
          language: detectedLanguage,
          error: error,
        );

        _appendMessage(ConversationMessage(role: 'ai', content: fallback));
        await _speakAI(fallback, language: detectedLanguage);
      }

      // Show review panel so user can edit-resend if needed.
      if (requiresInputReviewNotifier.value) {
        _showReviewPanel(userInput, detectedLanguage);
      }

      await Future.delayed(loopDelay);
    }
  }

  void _showReviewPanel(String text, ConversationLanguage language) {
    pendingUserInputNotifier.value = text;
    _pendingEditLanguage = language;
    isReviewingUserInputNotifier.value = true;

    final preferred = languageNotifier.value;
    statusNotifier.value = preferred == ConversationLanguage.portugueseBr
        ? 'Edite e reenvie se necessario.'
        : 'Edit and resend if needed.';
  }

  void _dismissReviewPanel() {
    if (isReviewingUserInputNotifier.value) {
      isReviewingUserInputNotifier.value = false;
      pendingUserInputNotifier.value = '';
    }
  }

  void _removeLastExchange() {
    final current = List<Map<String, String>>.from(conversation.value);
    if (current.isNotEmpty && current.last['role'] == 'ai') {
      current.removeLast();
    }
    if (current.isNotEmpty && current.last['role'] == 'user') {
      current.removeLast();
    }
    conversation.value = current;
  }

  bool _isInResumeGracePeriod() {
    final until = _resumeGraceUntil;
    if (until == null) return false;

    if (DateTime.now().isAfter(until)) {
      _resumeGraceUntil = null;
      isInResumeGraceNotifier.value = false;
      return false;
    }

    return true;
  }

  Future<_CapturedUserInput?> _captureUserInput() async {
    if (isPausedNotifier.value) {
      return null;
    }

    _setAvatarIdle();
    final preferred = languageNotifier.value;

    if (preferred != ConversationLanguage.auto) {
      final result = await speechService.listen(
        isSpeaking: _isSpeaking,
        localeId: preferred.speechLocale,
      );
      final normalized = (result ?? '').trim();
      if (normalized.isEmpty) {
        return null;
      }
      return _CapturedUserInput(
        text: normalized,
        language: preferred,
      );
    }

    final primaryLanguage = _autoNextPrimaryLanguage;
    final secondaryLanguage =
        primaryLanguage == ConversationLanguage.portugueseBr
            ? ConversationLanguage.englishUs
            : ConversationLanguage.portugueseBr;
    _autoNextPrimaryLanguage = secondaryLanguage;

    final primaryResult = await speechService.listen(
      isSpeaking: _isSpeaking,
      localeId: primaryLanguage.speechLocale,
    );
    final normalizedPrimary = (primaryResult ?? '').trim();

    if (requiresInputReviewNotifier.value) {
      final secondaryResult = await speechService.listen(
        isSpeaking: _isSpeaking,
        localeId: secondaryLanguage.speechLocale,
      );
      final normalizedSecondary = (secondaryResult ?? '').trim();
      return _pickBestAutoCapture(
        primaryText: normalizedPrimary,
        primaryLanguage: primaryLanguage,
        secondaryText: normalizedSecondary,
        secondaryLanguage: secondaryLanguage,
      );
    }

    if (normalizedPrimary.isNotEmpty) {
      if (_isWeakCapture(normalizedPrimary)) {
        final secondaryResult = await speechService.listen(
          isSpeaking: _isSpeaking,
          localeId: secondaryLanguage.speechLocale,
        );
        final normalizedSecondary = (secondaryResult ?? '').trim();
        if (_isBetterFallbackCandidate(
          primaryText: normalizedPrimary,
          secondaryText: normalizedSecondary,
        )) {
          return _CapturedUserInput(
            text: normalizedSecondary,
            language: _inferLanguageFromText(
              normalizedSecondary,
              secondaryLanguage,
            ),
          );
        }
      }

      return _CapturedUserInput(
        text: normalizedPrimary,
        language: _inferLanguageFromText(normalizedPrimary, primaryLanguage),
      );
    }

    final secondaryResult = await speechService.listen(
      isSpeaking: _isSpeaking,
      localeId: secondaryLanguage.speechLocale,
    );
    final normalizedSecondary = (secondaryResult ?? '').trim();
    if (normalizedSecondary.isEmpty) {
      return null;
    }

    return _CapturedUserInput(
      text: normalizedSecondary,
      language: _inferLanguageFromText(
        normalizedSecondary,
        secondaryLanguage,
      ),
    );
  }

  _CapturedUserInput? _pickBestAutoCapture({
    required String primaryText,
    required ConversationLanguage primaryLanguage,
    required String secondaryText,
    required ConversationLanguage secondaryLanguage,
  }) {
    final normalizedPrimary = primaryText.trim();
    final normalizedSecondary = secondaryText.trim();

    if (normalizedPrimary.isEmpty && normalizedSecondary.isEmpty) {
      return null;
    }
    if (normalizedPrimary.isEmpty) {
      return _CapturedUserInput(
        text: normalizedSecondary,
        language: _inferLanguageFromText(
          normalizedSecondary,
          secondaryLanguage,
        ),
      );
    }
    if (normalizedSecondary.isEmpty) {
      return _CapturedUserInput(
        text: normalizedPrimary,
        language: _inferLanguageFromText(normalizedPrimary, primaryLanguage),
      );
    }

    final primaryScore = _captureQualityScore(normalizedPrimary);
    final secondaryScore = _captureQualityScore(normalizedSecondary);

    if (secondaryScore > primaryScore) {
      return _CapturedUserInput(
        text: normalizedSecondary,
        language: _inferLanguageFromText(
          normalizedSecondary,
          secondaryLanguage,
        ),
      );
    }

    return _CapturedUserInput(
      text: normalizedPrimary,
      language: _inferLanguageFromText(normalizedPrimary, primaryLanguage),
    );
  }

  int _captureQualityScore(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return -1;

    final words = _wordCount(normalized);
    final lengthScore = normalized.length.clamp(0, 120);
    final punctuationBonus = RegExp(r'[\.,\?!]').hasMatch(normalized) ? 4 : 0;
    return (words * 12) + lengthScore + punctuationBonus;
  }

  bool _isWeakCapture(String text) {
    final tokens = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    return tokens.length <= 2 || text.trim().length <= 12;
  }

  bool _isBetterFallbackCandidate({
    required String primaryText,
    required String secondaryText,
  }) {
    final normalizedSecondary = secondaryText.trim();
    if (normalizedSecondary.isEmpty) {
      return false;
    }

    final primaryWords = _wordCount(primaryText);
    final secondaryWords = _wordCount(normalizedSecondary);
    if (secondaryWords > primaryWords) {
      return true;
    }

    return normalizedSecondary.length > primaryText.trim().length + 4;
  }

  int _wordCount(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .length;
  }

  /// Lightweight text-based language inference for auto mode.
  ///
  /// Returns the language that best matches the text content, overriding the
  /// STT-locale guess when the evidence is strong enough.
  ConversationLanguage _inferLanguageFromText(
    String text,
    ConversationLanguage sttGuess,
  ) {
    final lower = text.toLowerCase();
    final words =
        lower.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return sttGuess;

    const englishMarkers = {
      'i',
      'the',
      'is',
      'are',
      'was',
      'were',
      'you',
      'my',
      'your',
      'we',
      'they',
      'he',
      'she',
      'it',
      'do',
      'does',
      'did',
      'have',
      'has',
      'had',
      'will',
      'would',
      'can',
      'could',
      'should',
      'not',
      'this',
      'that',
      'what',
      'how',
      'why',
      'where',
      'when',
      'with',
      'for',
      'and',
      'but',
      'just',
      'about',
      'like',
      'want',
      'think',
      'know',
      'hello',
      'hi',
      'please',
      'thank',
      'thanks',
      'yes',
      'no',
      'okay',
    };
    const portugueseMarkers = {
      'eu',
      'voce',
      'ele',
      'ela',
      'nos',
      'eles',
      'elas',
      'meu',
      'minha',
      'seu',
      'sua',
      'nao',
      'sim',
      'como',
      'que',
      'por',
      'para',
      'com',
      'uma',
      'esse',
      'essa',
      'isso',
      'este',
      'esta',
      'isto',
      'aqui',
      'ali',
      'entao',
      'muito',
      'mais',
      'tambem',
      'ainda',
      'ja',
      'agora',
      'quero',
      'posso',
      'pode',
      'falar',
      'fazer',
      'dizer',
      'obrigado',
      'obrigada',
      'oi',
      'ola',
      'bom',
      'boa',
      'dia',
      'tudo',
      'bem',
    };

    int enHits = 0;
    int ptHits = 0;
    for (final w in words) {
      // Strip basic punctuation for matching
      final clean = w.replaceAll(RegExp(r'[^a-z]'), '');
      if (englishMarkers.contains(clean)) enHits++;
      if (portugueseMarkers.contains(clean)) ptHits++;
    }

    // Only override STT guess when the difference is clear
    if (enHits > ptHits && enHits >= 2) return ConversationLanguage.englishUs;
    if (ptHits > enHits && ptHits >= 2)
      return ConversationLanguage.portugueseBr;

    return sttGuess;
  }

  Future<bool> _handleCommand({
    required String userInput,
    required ConversationLanguage language,
  }) async {
    final lower = userInput.toLowerCase();

    final askedRepeat = lower.contains('repeat') ||
        lower.contains('repete') ||
        lower.contains('repetir');
    if (askedRepeat) {
      await _speakAI(_lastAIResponse, language: language);
      return true;
    }

    final askedSlow = lower.contains('slow down') ||
        lower.contains('slower') ||
        lower.contains('mais devagar') ||
        lower.contains('fale devagar') ||
        lower.contains('diminuir velocidade') ||
        lower.contains('reduzir velocidade') ||
        lower.contains('decrease speed');
    if (askedSlow) {
      await _shiftSpeechSpeed(step: -1, language: language);
      return true;
    }

    final askedFaster = lower.contains('speed up') ||
        lower.contains('faster') ||
        lower.contains('mais rapido') ||
        lower.contains('mais rapida') ||
        lower.contains('aumentar velocidade') ||
        lower.contains('fale mais rapido');
    if (askedFaster) {
      await _shiftSpeechSpeed(step: 1, language: language);
      return true;
    }

    final askedHalfSpeed = lower.contains('0.5x') ||
        lower.contains('0,5x') ||
        lower.contains('meia velocidade') ||
        lower.contains('metade da velocidade');
    if (askedHalfSpeed) {
      await _applySpeechSpeedMultiplier(
        multiplier: 0.5,
        language: language,
        origin: 'explicit-0.5x',
      );
      return true;
    }

    final askedOneSpeed = lower.contains('1x') ||
        lower.contains('1.0x') ||
        lower.contains('1,0x');
    if (askedOneSpeed) {
      await _applySpeechSpeedMultiplier(
        multiplier: 1.0,
        language: language,
        origin: 'normal',
      );
      return true;
    }

    final askedOneHalfSpeed = lower.contains('1.5x') || lower.contains('1,5x');
    if (askedOneHalfSpeed) {
      await _applySpeechSpeedMultiplier(
        multiplier: 1.5,
        language: language,
        origin: 'explicit-1.5x',
      );
      return true;
    }

    final askedTwoSpeed = lower.contains('2x') ||
        lower.contains('2.0x') ||
        lower.contains('2,0x') ||
        lower.contains('dobro da velocidade');
    if (askedTwoSpeed) {
      await _applySpeechSpeedMultiplier(
        multiplier: 2.0,
        language: language,
        origin: 'explicit-2.0x',
      );
      return true;
    }

    final askedNormalSpeed = lower.contains('normal speed') ||
        lower.contains('velocidade normal') ||
        lower.contains('normalizar velocidade');
    if (askedNormalSpeed) {
      await _applySpeechSpeedMultiplier(
        multiplier: 1.0,
        language: language,
        origin: 'normal',
      );
      return true;
    }

    final askedPause = lower.contains('pause') ||
        lower.contains('pausar') ||
        lower.contains('stop listening') ||
        lower.contains('parar de ouvir');
    if (askedPause) {
      pauseConversation();
      return true;
    }

    return false;
  }

  Future<void> _shiftSpeechSpeed({
    required int step,
    required ConversationLanguage language,
  }) async {
    final current = speechSpeedMultiplierNotifier.value;
    final index = _speedMultipliers.indexOf(current);
    final safeIndex = index < 0 ? 1 : index;
    final next = (safeIndex + step).clamp(0, _speedMultipliers.length - 1);
    await _applySpeechSpeedMultiplier(
      multiplier: _speedMultipliers[next],
      language: language,
      origin: step > 0 ? 'faster' : 'slower',
    );
  }

  Future<void> _applySpeechSpeedMultiplier({
    required double multiplier,
    required ConversationLanguage language,
    required String origin,
  }) async {
    final normalized = _closestSupportedMultiplier(multiplier);
    speechSpeedMultiplierNotifier.value = normalized;
    await ttsService.setRate(_ttsRateForMultiplier(normalized));

    final msg = _buildRateMessage(
      language: language,
      origin: origin,
      multiplier: normalized,
    );
    _appendMessage(ConversationMessage(role: 'ai', content: msg));
    await _speakAI(msg, language: language);
  }

  double _closestSupportedMultiplier(double input) {
    var closest = _speedMultipliers.first;
    var bestDistance = (input - closest).abs();

    for (final option in _speedMultipliers.skip(1)) {
      final distance = (input - option).abs();
      if (distance < bestDistance) {
        closest = option;
        bestDistance = distance;
      }
    }

    return closest;
  }

  double _ttsRateForMultiplier(double multiplier) {
    const baseRate = kIsWeb ? _baseTtsRateWeb : _baseTtsRateMobile;
    return (baseRate * multiplier).clamp(0.2, 1.0);
  }

  String _buildRateMessage({
    required ConversationLanguage language,
    required String origin,
    required double multiplier,
  }) {
    final speedLabel = _formatSpeedLabel(multiplier);

    if (language == ConversationLanguage.portugueseBr) {
      if (origin == 'faster' ||
          origin == 'explicit-1.5x' ||
          origin == 'explicit-2.0x') {
        return 'Certo, vou falar mais rapido. Velocidade em $speedLabel.';
      }
      if (origin == 'normal' || origin == 'manual') {
        return 'Velocidade normal restaurada em $speedLabel.';
      }
      return 'Certo, vou falar mais devagar. Velocidade em $speedLabel.';
    }

    if (origin == 'faster' ||
        origin == 'explicit-1.5x' ||
        origin == 'explicit-2.0x') {
      return 'Sure, I will speak faster. Speed set to $speedLabel.';
    }
    if (origin == 'normal' || origin == 'manual') {
      return 'Speech speed reset to normal at $speedLabel.';
    }
    return 'Sure, I will speak slower. Speed set to $speedLabel.';
  }

  String _buildAiReplyFallback({
    required ConversationLanguage language,
    required Object error,
  }) {
    if (error is AIServiceException) {
      return _buildAiServiceFallbackByCode(
        language: language,
        code: error.code,
      );
    }

    if (language == ConversationLanguage.portugueseBr) {
      return 'Desculpe, tive um problema para responder agora. Pode tentar de novo?';
    }
    return 'Sorry, I had an issue replying right now. Could you try again?';
  }

  String _buildAiServiceFallbackByCode({
    required ConversationLanguage language,
    required AIServiceErrorCode code,
  }) {
    final isPortuguese = language == ConversationLanguage.portugueseBr;

    switch (code) {
      case AIServiceErrorCode.missingApiKey:
        return isPortuguese
            ? 'Não consegui responder porque a chave da IA não foi configurada no app. Verifique o arquivo .env e gere um novo APK.'
            : 'I could not reply because the AI key is missing in the app configuration. Please verify .env and build a new APK.';
      case AIServiceErrorCode.unauthorized:
      case AIServiceErrorCode.forbidden:
        return isPortuguese
            ? 'A chave da IA foi rejeitada neste dispositivo. Verifique restrições da chave para o app em release e tente novamente.'
            : 'The AI key was rejected on this device. Please review key restrictions for the release app and try again.';
      case AIServiceErrorCode.rateLimited:
      case AIServiceErrorCode.quotaExceeded:
        return isPortuguese
            ? 'A API de IA atingiu o limite de uso agora. Aguarde um pouco e tente novamente.'
            : 'The AI API usage limit was reached just now. Please wait a moment and try again.';
      case AIServiceErrorCode.network:
        return isPortuguese
            ? 'Não consegui acessar a internet para responder. Confira sua conexão e tente novamente.'
            : 'I could not reach the internet to reply. Please check your connection and try again.';
      case AIServiceErrorCode.serviceUnavailable:
        return isPortuguese
            ? 'O serviço de IA está temporariamente indisponível. Tente novamente em instantes.'
            : 'The AI service is temporarily unavailable. Please try again shortly.';
      case AIServiceErrorCode.invalidResponse:
      case AIServiceErrorCode.unknown:
        return isPortuguese
            ? 'Recebi uma resposta invalida da IA agora. Pode tentar novamente?'
            : 'I got an invalid AI response just now. Could you try again?';
    }
  }

  String _formatSpeedLabel(double multiplier) {
    final hasTwoDecimals = (multiplier * 100).round() % 10 != 0;
    final precision = hasTwoDecimals ? 2 : 1;
    return '${multiplier.toStringAsFixed(precision)}x';
  }

  void _appendMessage(ConversationMessage message) {
    conversation.value = [...conversation.value, message.toMap()];
  }

  void _startSessionTicker() {
    _sessionTicker?.cancel();
    _sessionTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _sessionStartedAt;
      if (startedAt == null) return;
      elapsedSecondsNotifier.value =
          DateTime.now().difference(startedAt).inSeconds;
    });
  }

  void _stopSessionTicker() {
    _sessionTicker?.cancel();
    _sessionTicker = null;
  }

  Future<void> _speakAI(
    String text, {
    required ConversationLanguage language,
  }) async {
    _setAvatarTalking(language: language);
    await ttsService.speak(text, locale: language.ttsLocale);
    _setAvatarIdle();

    if (_isActive && !_autoResumeListening) {
      pauseConversation();
    }
  }

  void _setAvatarTalking({required ConversationLanguage language}) {
    _isSpeaking = true;
    statusNotifier.value = language == ConversationLanguage.portugueseBr
        ? 'Avatar falando...'
        : 'Avatar speaking...';
    lottieAssetNotifier.value = 'assets/lottie/robot_talking.json';
  }

  void _setAvatarIdle() {
    _isSpeaking = false;
    final preferred = languageNotifier.value;
    statusNotifier.value = preferred == ConversationLanguage.portugueseBr
        ? 'Ouvindo...'
        : 'Listening...';
    lottieAssetNotifier.value = 'assets/lottie/robot_idle.json';
  }

  Future<void> _persistSession() async {
    final repository = sessionHistoryRepository;
    final startedAt = _sessionStartedAt;
    if (repository == null || startedAt == null) {
      return;
    }

    final feedback = (sessionFeedbackNotifier.value ?? '').trim();
    final record = PracticeSessionRecord(
      id: startedAt.microsecondsSinceEpoch.toString(),
      startedAt: startedAt,
      endedAt: DateTime.now(),
      practiceFocus: practiceFocusNotifier.value,
      userTurns: userTurnsNotifier.value,
      elapsedSeconds: elapsedSecondsNotifier.value,
      language: _lastDetectedLanguage,
      feedback: feedback,
    );

    try {
      await repository.saveSession(record);
    } catch (_) {
      // Keep conversation flow resilient if local persistence fails.
    }
  }
}

class _CapturedUserInput {
  final String text;
  final ConversationLanguage language;

  _CapturedUserInput({
    required this.text,
    required this.language,
  });
}
