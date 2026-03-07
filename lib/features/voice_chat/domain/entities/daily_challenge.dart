class DailyChallenge {
  final String dateKey;
  final String topic;
  final int targetMinutes;
  final bool isCompleted;

  const DailyChallenge({
    required this.dateKey,
    required this.topic,
    required this.targetMinutes,
    required this.isCompleted,
  });

  DailyChallenge copyWith({
    String? dateKey,
    String? topic,
    int? targetMinutes,
    bool? isCompleted,
  }) {
    return DailyChallenge(
      dateKey: dateKey ?? this.dateKey,
      topic: topic ?? this.topic,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'topic': topic,
      'targetMinutes': targetMinutes,
      'isCompleted': isCompleted,
    };
  }

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      dateKey: (json['dateKey'] ?? '').toString(),
      topic: (json['topic'] ?? 'General conversation').toString(),
      targetMinutes: (json['targetMinutes'] as num?)?.toInt() ?? 5,
      isCompleted: json['isCompleted'] == true,
    );
  }
}
