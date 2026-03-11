import 'package:flutter/material.dart';

import '../../domain/entities/conversation_language.dart';
import '../../domain/entities/exercise_type.dart';
import '../../domain/entities/lesson_exercise.dart';

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

class _OptionExerciseWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final prompt = _promptFor(exercise, language);
    final options = _optionsFor(exercise, language);
    final selectedIndex = selectedAnswer is int ? selectedAnswer as int : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        if (exercise.type == ExerciseType.listenAndSelect &&
            onPlayAudio != null) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: enabled ? onPlayAudio : null,
            icon: const Icon(Icons.volume_up_outlined),
            label: Text(language == ConversationLanguage.portugueseBr
                ? 'Ouvir audio'
                : 'Play audio'),
          ),
        ],
        const SizedBox(height: 8),
        ...options.asMap().entries.map((entry) {
          return RadioListTile<int>(
            value: entry.key,
            groupValue: selectedIndex,
            onChanged:
                enabled ? (value) => onAnswerChanged(value ?? entry.key) : null,
            title: Text(entry.value),
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _promptFor(widget.exercise, widget.language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        if (widget.exercise.type == ExerciseType.listenAndType &&
            widget.onPlayAudio != null) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: widget.enabled ? widget.onPlayAudio : null,
            icon: const Icon(Icons.volume_up_outlined),
            label: Text(widget.language == ConversationLanguage.portugueseBr
                ? 'Ouvir audio'
                : 'Play audio'),
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
        Text(prompt,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
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
        Text(prompt,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
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
          child: Text(label),
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
        Text(prompt,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        if (reference.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(reference, style: const TextStyle(color: Colors.white70)),
        ],
        const SizedBox(height: 10),
        Text(
          widget.language == ConversationLanguage.portugueseBr
              ? 'Precisao de pronuncia: $clampedAccuracy%'
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
                ? 'Transcricao da fala'
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
        Text(prompt,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
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
  final key =
      language == ConversationLanguage.portugueseBr ? 'promptPt' : 'promptEn';
  return (exercise.content[key] ?? '').toString();
}

List<String> _optionsFor(
    LessonExercise exercise, ConversationLanguage language) {
  final key =
      language == ConversationLanguage.portugueseBr ? 'optionsPt' : 'optionsEn';
  final raw = exercise.content[key];
  if (raw is List) {
    return raw.map((item) => item.toString()).toList(growable: false);
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
