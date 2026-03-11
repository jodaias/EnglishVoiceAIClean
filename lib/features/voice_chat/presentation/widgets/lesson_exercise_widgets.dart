import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/conversation_language.dart';
import '../../domain/entities/exercise_type.dart';
import '../../domain/entities/lesson_exercise.dart';
import '../../domain/entities/reading_listening_exercise.dart';

typedef LessonAnswerChanged = void Function(Object answer);

class LessonExerciseRenderer extends StatelessWidget {
  final LessonExercise exercise;
  final ConversationLanguage language;
  final Object? selectedAnswer;
  final int pronunciationAccuracyPercent;
  final bool enabled;
  final LessonAnswerChanged onAnswerChanged;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onStartSpeechCapture;

  const LessonExerciseRenderer({
    super.key,
    required this.exercise,
    required this.language,
    required this.selectedAnswer,
    required this.onAnswerChanged,
    this.pronunciationAccuracyPercent = 0,
    this.enabled = true,
    this.onPlayAudio,
    this.onStartSpeechCapture,
  });

  @override
  Widget build(BuildContext context) {
    switch (exercise.type) {
      case ExerciseType.multipleChoice:
      case ExerciseType.listenAndSelect:
      case ExerciseType.fillInTheBlank:
        return _OptionExerciseWidget(
          exercise: exercise,
          language: language,
          selectedAnswer: selectedAnswer,
          enabled: enabled,
          onAnswerChanged: onAnswerChanged,
          onPlayAudio: onPlayAudio,
        );
      case ExerciseType.listenAndType:
      case ExerciseType.translate:
        return _TextExerciseWidget(
          exercise: exercise,
          language: language,
          selectedAnswer: selectedAnswer,
          enabled: enabled,
          onAnswerChanged: onAnswerChanged,
          onPlayAudio: onPlayAudio,
        );
      case ExerciseType.wordOrder:
        return _WordOrderExerciseWidget(
          exercise: exercise,
          language: language,
          selectedAnswer: selectedAnswer,
          enabled: enabled,
          onAnswerChanged: onAnswerChanged,
        );
      case ExerciseType.matchPairs:
        return _MatchPairsExerciseWidget(
          exercise: exercise,
          language: language,
          selectedAnswer: selectedAnswer,
          enabled: enabled,
          onAnswerChanged: onAnswerChanged,
        );
      case ExerciseType.speakTheSentence:
        return _SpeakSentenceExerciseWidget(
          exercise: exercise,
          language: language,
          selectedAnswer: selectedAnswer,
          pronunciationAccuracyPercent: pronunciationAccuracyPercent,
          enabled: enabled,
          onAnswerChanged: onAnswerChanged,
          onStartSpeechCapture: onStartSpeechCapture,
        );
      case ExerciseType.trueOrFalse:
        return _TrueFalseExerciseWidget(
          exercise: exercise,
          language: language,
          selectedAnswer: selectedAnswer,
          enabled: enabled,
          onAnswerChanged: onAnswerChanged,
        );
    }
  }
}

class _OptionExerciseWidget extends StatefulWidget {
  final LessonExercise exercise;
  final ConversationLanguage language;
  final Object? selectedAnswer;
  final bool enabled;
  final LessonAnswerChanged onAnswerChanged;
  final VoidCallback? onPlayAudio;

  const _OptionExerciseWidget({
    required this.exercise,
    required this.language,
    required this.selectedAnswer,
    required this.enabled,
    required this.onAnswerChanged,
    this.onPlayAudio,
  });

  @override
  State<_OptionExerciseWidget> createState() => _OptionExerciseWidgetState();
}

class _OptionExerciseWidgetState extends State<_OptionExerciseWidget> {
  bool _showAudioText = false;

  @override
  void didUpdateWidget(covariant _OptionExerciseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _showAudioText = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListeningExercise =
        widget.exercise.type == ExerciseType.listenAndSelect;
    final canRevealText = _canRevealAudioText(widget.exercise);

    final prompt = isListeningExercise && !_showAudioText
        ? _hiddenAudioPrompt(widget.language)
        : _promptFor(widget.exercise, widget.language);
    final options = _optionsFor(widget.exercise, widget.language);
    final selectedIndex =
        widget.selectedAnswer is int ? widget.selectedAnswer as int : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WordMeaningText(
          text: prompt,
          language: widget.language,
          enableWordTap: !(isListeningExercise && !_showAudioText),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        if (isListeningExercise && widget.onPlayAudio != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: widget.enabled ? widget.onPlayAudio : null,
                icon: const Icon(Icons.volume_up_outlined),
                label: Text(widget.language == ConversationLanguage.portugueseBr
                    ? 'Ouvir áudio'
                    : 'Play audio'),
              ),
              if (canRevealText)
                OutlinedButton.icon(
                  onPressed: widget.enabled
                      ? () {
                          setState(() {
                            _showAudioText = !_showAudioText;
                          });
                        }
                      : null,
                  icon: Icon(_showAudioText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  label: Text(_showAudioText
                      ? (widget.language == ConversationLanguage.portugueseBr
                          ? 'Ocultar texto'
                          : 'Hide text')
                      : (widget.language == ConversationLanguage.portugueseBr
                          ? 'Mostrar texto'
                          : 'Show text')),
                ),
            ],
          ),
        ],
        if (isListeningExercise && !canRevealText) ...[
          const SizedBox(height: 6),
          Text(
            widget.language == ConversationLanguage.portugueseBr
                ? 'Nível avançado: texto oculto para foco em escuta.'
                : 'Advanced level: text hidden to focus on listening.',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
        const SizedBox(height: 8),
        ...options.asMap().entries.map((entry) {
          return RadioListTile<int>(
            value: entry.key,
            groupValue: selectedIndex,
            onChanged: widget.enabled
                ? (value) => widget.onAnswerChanged(value ?? entry.key)
                : null,
            title: _WordMeaningText(
              text: entry.value,
              language: widget.language,
              enableWordTap: false,
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }
}

class _TextExerciseWidget extends StatefulWidget {
  final LessonExercise exercise;
  final ConversationLanguage language;
  final Object? selectedAnswer;
  final bool enabled;
  final LessonAnswerChanged onAnswerChanged;
  final VoidCallback? onPlayAudio;

  const _TextExerciseWidget({
    required this.exercise,
    required this.language,
    required this.selectedAnswer,
    required this.enabled,
    required this.onAnswerChanged,
    this.onPlayAudio,
  });

  @override
  State<_TextExerciseWidget> createState() => _TextExerciseWidgetState();
}

class _TextExerciseWidgetState extends State<_TextExerciseWidget> {
  late final TextEditingController _controller;
  bool _showAudioText = false;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: (widget.selectedAnswer ?? '').toString());
  }

  @override
  void didUpdateWidget(covariant _TextExerciseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = (widget.selectedAnswer ?? '').toString();
    if (next != _controller.text) {
      _controller.text = next;
    }
    if (oldWidget.exercise.id != widget.exercise.id) {
      _showAudioText = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListeningExercise =
        widget.exercise.type == ExerciseType.listenAndType;
    final canRevealText = _canRevealAudioText(widget.exercise);
    final prompt = isListeningExercise && !_showAudioText
        ? _hiddenAudioPrompt(widget.language)
        : _displayPrompt(widget.exercise, widget.language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WordMeaningText(
          text: prompt,
          language: widget.language,
          enableWordTap: !(isListeningExercise && !_showAudioText),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        if (isListeningExercise && widget.onPlayAudio != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: widget.enabled ? widget.onPlayAudio : null,
                icon: const Icon(Icons.volume_up_outlined),
                label: Text(widget.language == ConversationLanguage.portugueseBr
                    ? 'Ouvir áudio'
                    : 'Play audio'),
              ),
              if (canRevealText)
                OutlinedButton.icon(
                  onPressed: widget.enabled
                      ? () {
                          setState(() {
                            _showAudioText = !_showAudioText;
                          });
                        }
                      : null,
                  icon: Icon(_showAudioText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  label: Text(_showAudioText
                      ? (widget.language == ConversationLanguage.portugueseBr
                          ? 'Ocultar texto'
                          : 'Hide text')
                      : (widget.language == ConversationLanguage.portugueseBr
                          ? 'Mostrar texto'
                          : 'Show text')),
                ),
            ],
          ),
        ],
        if (isListeningExercise && !canRevealText) ...[
          const SizedBox(height: 6),
          Text(
            widget.language == ConversationLanguage.portugueseBr
                ? 'Nível avançado: texto oculto para foco em escuta.'
                : 'Advanced level: text hidden to focus on listening.',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          enabled: widget.enabled,
          controller: _controller,
          onChanged: (value) => widget.onAnswerChanged(value),
          decoration: InputDecoration(
            hintText: widget.language == ConversationLanguage.portugueseBr
                ? 'Digite sua resposta'
                : 'Type your answer',
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _WordOrderExerciseWidget extends StatelessWidget {
  final LessonExercise exercise;
  final ConversationLanguage language;
  final Object? selectedAnswer;
  final bool enabled;
  final LessonAnswerChanged onAnswerChanged;

  const _WordOrderExerciseWidget({
    required this.exercise,
    required this.language,
    required this.selectedAnswer,
    required this.enabled,
    required this.onAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = _promptFor(exercise, language);
    final tokens = _tokens(exercise.content['correctTokens']);
    final current = selectedAnswer is List
        ? (selectedAnswer as List)
            .map((e) => e.toString())
            .toList(growable: false)
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WordMeaningText(
          text: prompt,
          language: language,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(current.join(' ')),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tokens.map((token) {
            return ActionChip(
              label: Text(token),
              onPressed: enabled
                  ? () {
                      final next = List<String>.from(current)..add(token);
                      onAnswerChanged(next);
                    }
                  : null,
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: enabled && current.isNotEmpty
                  ? () {
                      final next = List<String>.from(current)..removeLast();
                      onAnswerChanged(next);
                    }
                  : null,
              icon: const Icon(Icons.backspace_outlined),
              label: Text(language == ConversationLanguage.portugueseBr
                  ? 'Remover'
                  : 'Backspace'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: enabled ? () => onAnswerChanged(<String>[]) : null,
              child: Text(language == ConversationLanguage.portugueseBr
                  ? 'Limpar'
                  : 'Clear'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MatchPairsExerciseWidget extends StatefulWidget {
  final LessonExercise exercise;
  final ConversationLanguage language;
  final Object? selectedAnswer;
  final bool enabled;
  final LessonAnswerChanged onAnswerChanged;

  const _MatchPairsExerciseWidget({
    required this.exercise,
    required this.language,
    required this.selectedAnswer,
    required this.enabled,
    required this.onAnswerChanged,
  });

  @override
  State<_MatchPairsExerciseWidget> createState() =>
      _MatchPairsExerciseWidgetState();
}

class _MatchPairsExerciseWidgetState extends State<_MatchPairsExerciseWidget> {
  String? _selectedLeft;
  String? _selectedRight;

  @override
  Widget build(BuildContext context) {
    final prompt = _promptFor(widget.exercise, widget.language);
    final pairs = _pairs(widget.exercise.content['correctPairs']);
    final current = widget.selectedAnswer is Map
        ? (widget.selectedAnswer as Map)
            .map((key, value) => MapEntry(key.toString(), value.toString()))
        : <String, String>{};
    final leftItems = pairs.keys.toList(growable: false);
    final rightItems = pairs.values.toList(growable: false);

    final matchedLeft = current.keys.toSet();
    final matchedRight = current.values.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WordMeaningText(
          text: prompt,
          language: widget.language,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          widget.language == ConversationLanguage.portugueseBr
              ? 'Toque em um item da esquerda e um da direita para conectar.'
              : 'Tap one item on the left and one on the right to connect.',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: leftItems.map((left) {
                  final isMatched = matchedLeft.contains(left);
                  final isSelected = _selectedLeft == left;
                  return _selectionCard(
                    label: left,
                    selected: isSelected,
                    matched: isMatched,
                    enabled: widget.enabled,
                    onTap: () {
                      if (!widget.enabled) {
                        return;
                      }
                      if (isMatched) {
                        final next = Map<String, String>.from(current)
                          ..remove(left);
                        widget.onAnswerChanged(next);
                        return;
                      }
                      setState(() {
                        _selectedLeft = left;
                      });
                      _tryConnect(current);
                    },
                  );
                }).toList(growable: false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: rightItems.map((right) {
                  final isMatched = matchedRight.contains(right);
                  final isSelected = _selectedRight == right;
                  return _selectionCard(
                    label: right,
                    selected: isSelected,
                    matched: isMatched,
                    enabled: widget.enabled,
                    onTap: () {
                      if (!widget.enabled || isMatched) {
                        return;
                      }
                      setState(() {
                        _selectedRight = right;
                      });
                      _tryConnect(current);
                    },
                  );
                }).toList(growable: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _selectionCard({
    required String label,
    required bool selected,
    required bool matched,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final borderColor = matched
        ? Colors.green.shade300
        : selected
            ? Colors.blue.shade300
            : Colors.white24;
    final bgColor = matched
        ? Colors.green.withOpacity(0.2)
        : selected
            ? Colors.blue.withOpacity(0.2)
            : Colors.white10;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: _WordMeaningText(
            text: label,
            language: widget.language,
            enableWordTap: false,
          ),
        ),
      ),
    );
  }

  void _tryConnect(Map<String, String> current) {
    if (_selectedLeft == null || _selectedRight == null) {
      return;
    }

    final left = _selectedLeft!;
    final right = _selectedRight!;
    final next = Map<String, String>.from(current);

    final conflictedLeft = next.entries
        .where((entry) => entry.value == right && entry.key != left)
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final key in conflictedLeft) {
      next.remove(key);
    }

    next[left] = right;
    widget.onAnswerChanged(next);

    setState(() {
      _selectedLeft = null;
      _selectedRight = null;
    });
  }
}

class _SpeakSentenceExerciseWidget extends StatefulWidget {
  final LessonExercise exercise;
  final ConversationLanguage language;
  final Object? selectedAnswer;
  final int pronunciationAccuracyPercent;
  final bool enabled;
  final LessonAnswerChanged onAnswerChanged;
  final VoidCallback? onStartSpeechCapture;

  const _SpeakSentenceExerciseWidget({
    required this.exercise,
    required this.language,
    required this.selectedAnswer,
    required this.pronunciationAccuracyPercent,
    required this.enabled,
    required this.onAnswerChanged,
    this.onStartSpeechCapture,
  });

  @override
  State<_SpeakSentenceExerciseWidget> createState() =>
      _SpeakSentenceExerciseWidgetState();
}

class _SpeakSentenceExerciseWidgetState
    extends State<_SpeakSentenceExerciseWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: (widget.selectedAnswer ?? '').toString());
  }

  @override
  void didUpdateWidget(covariant _SpeakSentenceExerciseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = (widget.selectedAnswer ?? '').toString();
    if (next != _controller.text) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _promptFor(widget.exercise, widget.language);
    final reference =
        (widget.exercise.content['referenceText'] ?? '').toString();
    final clampedAccuracy = widget.pronunciationAccuracyPercent.clamp(0, 100);
    final accuracyProgress = clampedAccuracy / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WordMeaningText(
          text: prompt,
          language: widget.language,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        if (reference.isNotEmpty) ...[
          const SizedBox(height: 6),
          _WordMeaningText(
            text: reference,
            language: widget.language,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          widget.language == ConversationLanguage.portugueseBr
              ? 'Precisão de pronúncia: $clampedAccuracy%'
              : 'Pronunciation accuracy: $clampedAccuracy%',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: accuracyProgress,
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              clampedAccuracy >= 85
                  ? Colors.greenAccent.shade400
                  : clampedAccuracy >= 60
                      ? Colors.orangeAccent.shade200
                      : Colors.redAccent.shade200,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (widget.onStartSpeechCapture != null)
          FilledButton.icon(
            onPressed: widget.enabled ? widget.onStartSpeechCapture : null,
            icon: const Icon(Icons.mic_outlined),
            label: Text(widget.language == ConversationLanguage.portugueseBr
                ? 'Capturar fala'
                : 'Capture speech'),
          ),
        const SizedBox(height: 8),
        TextField(
          enabled: widget.enabled,
          controller: _controller,
          onChanged: (value) => widget.onAnswerChanged(value),
          decoration: InputDecoration(
            hintText: widget.language == ConversationLanguage.portugueseBr
                ? 'Transcrição da fala'
                : 'Speech transcript',
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _TrueFalseExerciseWidget extends StatelessWidget {
  final LessonExercise exercise;
  final ConversationLanguage language;
  final Object? selectedAnswer;
  final bool enabled;
  final LessonAnswerChanged onAnswerChanged;

  const _TrueFalseExerciseWidget({
    required this.exercise,
    required this.language,
    required this.selectedAnswer,
    required this.enabled,
    required this.onAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = _promptFor(exercise, language);
    final selected = selectedAnswer is bool ? selectedAnswer as bool : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WordMeaningText(
          text: prompt,
          language: language,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(language == ConversationLanguage.portugueseBr
                  ? 'Verdadeiro'
                  : 'True'),
              selected: selected == true,
              onSelected: enabled ? (_) => onAnswerChanged(true) : null,
            ),
            ChoiceChip(
              label: Text(language == ConversationLanguage.portugueseBr
                  ? 'Falso'
                  : 'False'),
              selected: selected == false,
              onSelected: enabled ? (_) => onAnswerChanged(false) : null,
            ),
          ],
        ),
      ],
    );
  }
}

String _promptFor(LessonExercise exercise, ConversationLanguage language) {
  final promptEn = (exercise.content['promptEn'] ?? '').toString().trim();
  if (promptEn.isNotEmpty) {
    return promptEn;
  }
  // Fallback for legacy records that may not include english prompt.
  return (exercise.content['promptPt'] ?? '').toString();
}

String _displayPrompt(LessonExercise exercise, ConversationLanguage language) {
  if (exercise.type == ExerciseType.listenAndType) {
    return _listeningTranscriptFor(exercise, language);
  }
  return _promptFor(exercise, language);
}

String _listeningTranscriptFor(
  LessonExercise exercise,
  ConversationLanguage language,
) {
  final explicitAudioText =
      (exercise.content['audioTextEn'] ?? '').toString().trim();
  if (explicitAudioText.isNotEmpty) {
    return explicitAudioText;
  }

  final ptAudioFallback =
      (exercise.content['audioTextPt'] ?? '').toString().trim();
  if (ptAudioFallback.isNotEmpty) {
    return ptAudioFallback;
  }

  final promptEn = (exercise.content['promptEn'] ?? '').toString().trim();
  if (promptEn.isNotEmpty) {
    final colon = promptEn.indexOf(':');
    if (colon >= 0 && colon + 1 < promptEn.length) {
      final candidate = promptEn.substring(colon + 1).trim();
      if (candidate.isNotEmpty) {
        return candidate;
      }
    }
    return promptEn;
  }

  // Legacy fallback for previously seeded content without explicit audioText keys.
  final prompt = _promptFor(exercise, language).trim();
  final colon = prompt.indexOf(':');
  if (colon >= 0 && colon + 1 < prompt.length) {
    final candidate = prompt.substring(colon + 1).trim();
    if (candidate.isNotEmpty) {
      return candidate;
    }
  }
  return prompt;
}

bool _canRevealAudioText(LessonExercise exercise) {
  return exercise.difficulty != ReadingListeningDifficulty.advanced;
}

String _hiddenAudioPrompt(ConversationLanguage language) {
  return language == ConversationLanguage.portugueseBr
      ? 'Ouça o áudio e responda sem ler o texto.'
      : 'Listen to the audio and answer without reading the text.';
}

List<String> _optionsFor(
    LessonExercise exercise, ConversationLanguage language) {
  final rawEn = exercise.content['optionsEn'];
  if (rawEn is List) {
    return rawEn.map((item) => item.toString()).toList(growable: false);
  }

  // Fallback for legacy records that may not include english options.
  final rawPt = exercise.content['optionsPt'];
  if (rawPt is List) {
    return rawPt.map((item) => item.toString()).toList(growable: false);
  }
  return const <String>[];
}

List<String> _tokens(Object? raw) {
  if (raw is List) {
    return raw.map((item) => item.toString()).toList(growable: false);
  }
  return const <String>[];
}

Map<String, String> _pairs(Object? raw) {
  if (raw is! Map) {
    return const <String, String>{};
  }
  return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
}

class _WordMeaningText extends StatelessWidget {
  final String text;
  final ConversationLanguage language;
  final TextStyle? style;
  final bool enableWordTap;

  const _WordMeaningText({
    required this.text,
    required this.language,
    this.style,
    this.enableWordTap = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableWordTap) {
      return Text(text, style: style);
    }

    final tokens = RegExp(r"[A-Za-z']+|[^A-Za-z']+")
        .allMatches(text)
        .map((m) => m.group(0) ?? '')
        .toList(growable: false);
    final words = tokens
        .where(_isEnglishWord)
        .map((token) => token.toLowerCase())
        .toList(growable: false);

    if (tokens.isEmpty) {
      return Text(text, style: style);
    }

    if (!_isLikelyEnglishText(words)) {
      return Text(text, style: style);
    }

    final effectiveStyle = style ?? const TextStyle();
    return Text.rich(
      TextSpan(
        style: effectiveStyle,
        children: tokens.asMap().entries.map((entry) {
          final token = entry.value;
          if (!_isEnglishWord(token)) {
            return TextSpan(text: token);
          }

          final wordIndex = _wordIndexFromTokenIndex(tokens, entry.key);
          final meaningHint = _resolveWordMeaningMessage(words, wordIndex);
          Offset? tapAnchor;

          void showMeaning() {
            _showWordMeaningTooltip(
              context,
              meaningHint == null
                  ? 'Significado ainda não cadastrado.'
                  : meaningHint.message,
              isContextual: meaningHint?.isContextual ?? false,
              anchor: tapAnchor,
            );
          }

          return TextSpan(
            text: token,
            style: effectiveStyle.copyWith(
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
            ),
            recognizer: TapGestureRecognizer()
              ..onTapDown = (details) {
                tapAnchor = details.globalPosition;
                showMeaning();
              }
              ..onTap = showMeaning,
          );
        }).toList(growable: false),
      ),
    );
  }

  bool _isEnglishWord(String token) {
    if (token.trim().isEmpty) {
      return false;
    }

    return RegExp(r"^[A-Za-z']+$").hasMatch(token);
  }

  int _wordIndexFromTokenIndex(List<String> tokens, int tokenIndex) {
    var count = 0;
    for (var i = 0; i < tokenIndex; i++) {
      if (_isEnglishWord(tokens[i])) {
        count++;
      }
    }
    return count;
  }

  bool _isLikelyEnglishText(List<String> words) {
    if (words.isEmpty) {
      return false;
    }

    final englishSignals =
        words.where((word) => _englishSignalWords.contains(word)).length;
    final portugueseSignals =
        words.where((word) => _portugueseSignalWords.contains(word)).length;
    final mappedWords =
        words.where((word) => _wordMeaningsPt.containsKey(word)).length;

    if (portugueseSignals >= 2 && portugueseSignals > englishSignals) {
      return false;
    }

    if (englishSignals > 0) {
      return true;
    }

    return mappedWords >= 2 && portugueseSignals == 0;
  }

  _MeaningHint? _resolveWordMeaningMessage(List<String> words, int wordIndex) {
    if (wordIndex < 0 || wordIndex >= words.length) {
      return null;
    }

    final word = words[wordIndex];
    final previous = wordIndex > 0 ? words[wordIndex - 1] : null;
    final next = wordIndex + 1 < words.length ? words[wordIndex + 1] : null;

    if (word == 'work') {
      if (previous == 'at' || previous == 'to' || previous == 'for') {
        return const _MeaningHint(' trabalho', isContextual: true);
      }
      if (_subjectPronouns.contains(previous) || next == 'at') {
        return const _MeaningHint(
          ' trabalhar\nEx.: I work in a cafe = Eu trabalho em uma cafeteria.',
          isContextual: true,
        );
      }
      return const _MeaningHint(
        'Significados: trabalho ou trabalhar\nEx.: Work is busy today = O trabalho esta corrido hoje.',
        isContextual: true,
      );
    }

    if (word == 'watch') {
      if (_objectWords.contains(next) || previous == 'to') {
        return const _MeaningHint(
          ' assistir\nEx.: Watch this video = Assista a este video.',
          isContextual: true,
        );
      }
      return const _MeaningHint(
        'Significados: relogio ou assistir\nEx.: My watch is new = Meu relogio e novo.',
        isContextual: true,
      );
    }

    if (word == 'call') {
      if (_pronouns.contains(next) || next == 'you' || previous == 'can') {
        return const _MeaningHint(
          ' ligar/chamar\nEx.: Call me later = Me liga mais tarde.',
          isContextual: true,
        );
      }
      return const _MeaningHint(
        ' ligacao/chamada',
        isContextual: true,
      );
    }

    if (word == 'order') {
      if (_foodWords.contains(next) ||
          previous == 'can' ||
          previous == 'please') {
        return const _MeaningHint(
          ' pedir\nEx.: I want to order coffee = Quero pedir cafe.',
          isContextual: true,
        );
      }
      return const _MeaningHint(
        'Significados: ordem ou ordenar',
        isContextual: true,
      );
    }

    if (word == 'like') {
      if (_pronouns.contains(previous) && next != null) {
        return const _MeaningHint(
          ' gostar\nEx.: I like this class = Eu gosto desta aula.',
          isContextual: true,
        );
      }
      return const _MeaningHint(
        'Significados: como ou igual a',
        isContextual: true,
      );
    }

    if (word == 'table') {
      if (previous == 'times') {
        return const _MeaningHint(' tabela', isContextual: true);
      }
      return const _MeaningHint(' mesa');
    }

    if (word == 'match') {
      if (next == 'pairs') {
        return const _MeaningHint(
          ' associar\nEx.: Match pairs = Associe os pares.',
          isContextual: true,
        );
      }
      return const _MeaningHint(
        'Significados: partida ou combinacao',
        isContextual: true,
      );
    }

    if (word == 'class') {
      if (next == 'today' || previous == 'in' || previous == 'after') {
        return const _MeaningHint(' aula', isContextual: true);
      }
      return const _MeaningHint(
        'Significados: turma ou classe',
        isContextual: true,
      );
    }

    final baseMeaning = _wordMeaningsPt[word];
    if (baseMeaning == null) {
      return null;
    }
    return _MeaningHint(' $baseMeaning');
  }
}

class _MeaningHint {
  final String message;
  final bool isContextual;

  const _MeaningHint(this.message, {this.isContextual = false});
}

const Set<String> _subjectPronouns = <String>{
  'i',
  'you',
  'we',
  'they',
  'he',
  'she',
  'it',
};

const Set<String> _pronouns = <String>{
  'i',
  'you',
  'he',
  'she',
  'we',
  'they',
  'me',
  'him',
  'her',
  'us',
  'them',
};

const Set<String> _objectWords = <String>{
  'movie',
  'series',
  'video',
  'tv',
  'film',
};

const Set<String> _foodWords = <String>{
  'coffee',
  'tea',
  'water',
  'juice',
  'breakfast',
  'lunch',
  'dinner',
  'food',
  'menu',
};

const Set<String> _englishSignalWords = <String>{
  'i',
  'you',
  'we',
  'they',
  'he',
  'she',
  'it',
  'the',
  'a',
  'an',
  'to',
  'in',
  'on',
  'at',
  'is',
  'are',
  'my',
  'your',
  'hello',
  'good',
  'choose',
  'listen',
  'type',
  'match',
  'true',
  'false',
  'say',
};

const Set<String> _portugueseSignalWords = <String>{
  'voce',
  'voces',
  'nao',
  'que',
  'com',
  'para',
  'uma',
  'um',
  'de',
  'da',
  'do',
  'das',
  'dos',
  'em',
  'por',
  'como',
  'onde',
  'quando',
  'qual',
  'quais',
  'traduzir',
  'digite',
  'ouca',
  'responda',
};

OverlayEntry? _activeMeaningTooltip;

void _showWordMeaningTooltip(
  BuildContext context,
  String message, {
  bool isContextual = false,
  Offset? anchor,
}) {
  _activeMeaningTooltip?.remove();
  _activeMeaningTooltip = null;

  final overlay = Overlay.of(context, rootOverlay: true);
  if (!context.mounted || overlay == null) {
    return;
  }

  final entry = OverlayEntry(
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final horizontalPadding = 16.0;
      final maxTooltipWidth = (screenWidth - (horizontalPadding * 2)).clamp(
        140.0,
        420.0,
      );

      double width = maxTooltipWidth;
      double left = horizontalPadding;
      double top = 96;

      if (anchor != null) {
        width = 260.0.clamp(160.0, maxTooltipWidth);
        final desiredLeft = anchor.dx - (width / 2);
        final maxLeft = (screenWidth - width - horizontalPadding)
            .clamp(horizontalPadding, screenWidth);
        left = desiredLeft.clamp(horizontalPadding, maxLeft);
        top = (anchor.dy - 34).clamp(8.0, 10000.0);
      }

      return Positioned(
        left: left,
        width: width,
        top: top,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF263238).withOpacity(0.96),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isContextual)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.orangeAccent.shade100),
                      ),
                      child: const Text(
                        'Contexto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  _activeMeaningTooltip = entry;

  Future<void>.delayed(const Duration(milliseconds: 2400), () {
    if (_activeMeaningTooltip == entry) {
      entry.remove();
      _activeMeaningTooltip = null;
    }
  });
}

const Map<String, String> _wordMeaningsPt = <String, String>{
  'a': 'um/uma',
  'about': 'sobre',
  'after': 'depois',
  'afternoon': 'tarde',
  'again': 'novamente',
  'airport': 'aeroporto',
  'already': 'já',
  'always': 'sempre',
  'am': 'estou',
  'an': 'um/uma',
  'and': 'e',
  'answer': 'resposta',
  'apartment': 'apartamento',
  'are': 'está',
  'ask': 'perguntar',
  'at': 'em',
  'bad': 'ruim',
  'bag': 'bolsa',
  'bathroom': 'banheiro',
  'be': 'ser/estar',
  'because': 'porque',
  'before': 'antes',
  'best': 'melhor',
  'bill': 'conta',
  'book': 'livro',
  'breakfast': 'café da manhã',
  'bus': 'ônibus',
  'but': 'mas',
  'buy': 'comprar',
  'by': 'por',
  'call': 'ligar/chamar',
  'can': 'pode',
  'cafe': 'cafeteria',
  'chair': 'cadeira',
  'cheap': 'barato',
  'choose': 'escolher',
  'city': 'cidade',
  'class': 'aula',
  'close': 'fechar',
  'coffee': 'café',
  'come': 'vir',
  'correct': 'correto',
  'could': 'poderia',
  'day': 'dia',
  'dinner': 'jantar',
  'doctor': 'médico',
  'does': 'faz',
  'do': 'fazer',
  'did': 'fez',
  'e': 'e',
  'evening': 'noite',
  'exercise': 'exercício',
  'excuse': 'com licença',
  'expensive': 'caro',
  'false': 'falso',
  'finish': 'terminar',
  'food': 'comida',
  'for': 'para',
  'forget': 'esquecer',
  'from': 'de',
  'go': 'ir',
  'good': 'bom',
  'great': 'ótimo',
  'had': 'teve',
  'has': 'tem',
  'have': 'ter',
  'hello': 'olá',
  'health': 'saúde',
  'help': 'ajuda',
  'here': 'aqui',
  'he': 'ele',
  'hi': 'oi',
  'home': 'casa',
  'morning': 'manha',
  'hospital': 'hospital',
  'night': 'noite',
  'how': 'como',
  'i': 'eu',
  'if': 'se',
  'in': 'em',
  'is': 'e',
  'it': 'isso/ele/ela',
  'its': 'seu/sua',
  'juice': 'suco',
  'know': 'saber',
  'later': 'depois',
  'learn': 'aprender',
  'lesson': 'lição',
  'less': 'menos',
  'like': 'gostar',
  'listen': 'escutar',
  'look': 'olhar',
  'love': 'amar',
  'lunch': 'almoço',
  'match': 'combinar/associar',
  'me': 'me',
  'meet': 'conhecer',
  'menu': 'cardápio',
  'month': 'mês',
  'more': 'mais',
  'my': 'meu',
  'name': 'nome',
  'need': 'precisar',
  'never': 'nunca',
  'new': 'novo',
  'nice': 'legal',
  'no': 'não',
  'not': 'não',
  'now': 'agora',
  'of': 'de',
  'office': 'escritório',
  'old': 'velho/antigo',
  'on': 'em/sobre',
  'only': 'apenas',
  'open': 'abrir',
  'or': 'ou',
  'order': 'ordenar/pedir',
  'our': 'nosso',
  'plane': 'avião',
  'please': 'por favor',
  'pleasure': 'prazer',
  'price': 'preço',
  'question': 'pergunta',
  'read': 'ler',
  'remember': 'lembrar',
  'restaurant': 'restaurante',
  'say': 'dizer',
  'school': 'escola',
  'see': 'ver',
  'she': 'ela',
  'should': 'deveria',
  'so': 'então/assim',
  'sorry': 'desculpe',
  'sometimes': 'às vezes',
  'soon': 'em breve',
  'speak': 'falar',
  'start': 'começar',
  'station': 'estação',
  'still': 'ainda',
  'stop': 'parar',
  'street': 'rua',
  'student': 'aluno',
  'study': 'estudar',
  'table': 'mesa',
  'tea': 'chá',
  'teacher': 'professor',
  'tell': 'contar/dizer',
  'than': 'do que',
  'thank': 'agradecer',
  'thanks': 'obrigado',
  'that': 'aquilo/esse',
  'the': 'o/a',
  'their': 'deles/delas',
  'them': 'eles/elas',
  'then': 'entao',
  'there': 'lá',
  'these': 'estes/essas',
  'they': 'eles/elas',
  'this': 'isso/este',
  'those': 'aqueles/aquelas',
  'ticket': 'passagem/bilhete',
  'time': 'tempo/hora',
  'to': 'para',
  'today': 'hoje',
  'tomorrow': 'amanhã',
  'train': 'trem',
  'translate': 'traduzir',
  'true': 'verdadeiro',
  'type': 'digitar',
  'understand': 'entender',
  'very': 'muito',
  'wait': 'esperar',
  'want': 'querer',
  'was': 'era/estava',
  'watch': 'assistir',
  'water': 'água',
  'we': 'nos',
  'week': 'semana',
  'were': 'eram/estavam',
  'what': 'o que',
  'when': 'quando',
  'where': 'onde',
  'which': 'qual',
  'who': 'quem',
  'why': 'por que',
  'with': 'com',
  'without': 'sem',
  'work': 'trabalho',
  'would': 'iria',
  'write': 'escrever',
  'wrong': 'errado',
  'year': 'ano',
  'yes': 'sim',
  'yesterday': 'ontem',
  'you': 'você',
  'your': 'seu/sua',
  'yours': 'seu/sua',
};
