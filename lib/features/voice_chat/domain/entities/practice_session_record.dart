import 'conversation_language.dart';

class PracticeSessionRecord {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final String practiceFocus;
  final int userTurns;
  final int elapsedSeconds;
  final ConversationLanguage language;
  final String feedback;

  const PracticeSessionRecord({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.practiceFocus,
    required this.userTurns,
    required this.elapsedSeconds,
    required this.language,
    required this.feedback,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'practiceFocus': practiceFocus,
      'userTurns': userTurns,
      'elapsedSeconds': elapsedSeconds,
      'language': language.name,
      'feedback': feedback,
    };
  }

  factory PracticeSessionRecord.fromJson(Map<String, dynamic> json) {
    final rawLanguage = (json['language'] ?? '').toString();
    final language = ConversationLanguage.values.firstWhere(
      (value) => value.name == rawLanguage,
      orElse: () => ConversationLanguage.englishUs,
    );

    return PracticeSessionRecord(
      id: (json['id'] ?? '').toString(),
      startedAt: DateTime.tryParse((json['startedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endedAt: DateTime.tryParse((json['endedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      practiceFocus:
          (json['practiceFocus'] ?? 'General conversation').toString(),
      userTurns: (json['userTurns'] as num?)?.toInt() ?? 0,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      language: language,
      feedback: (json['feedback'] ?? '').toString(),
    );
  }
}
