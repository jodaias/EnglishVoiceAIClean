class LessonProgress {
  final String lessonId;
  final bool isCompleted;
  final int bestScore;
  final int xpEarned;
  final DateTime? completedAt;
  final int attempts;

  const LessonProgress({
    required this.lessonId,
    required this.isCompleted,
    required this.bestScore,
    required this.xpEarned,
    required this.completedAt,
    required this.attempts,
  });

  factory LessonProgress.empty(String lessonId) {
    return LessonProgress(
      lessonId: lessonId,
      isCompleted: false,
      bestScore: 0,
      xpEarned: 0,
      completedAt: null,
      attempts: 0,
    );
  }

  LessonProgress copyWith({
    String? lessonId,
    bool? isCompleted,
    int? bestScore,
    int? xpEarned,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? attempts,
  }) {
    return LessonProgress(
      lessonId: lessonId ?? this.lessonId,
      isCompleted: isCompleted ?? this.isCompleted,
      bestScore: bestScore ?? this.bestScore,
      xpEarned: xpEarned ?? this.xpEarned,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'isCompleted': isCompleted,
      'bestScore': bestScore,
      'xpEarned': xpEarned,
      'completedAt': completedAt?.toIso8601String(),
      'attempts': attempts,
    };
  }

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      lessonId: (json['lessonId'] ?? '').toString(),
      isCompleted: json['isCompleted'] == true,
      bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0,
      completedAt: DateTime.tryParse((json['completedAt'] ?? '').toString()),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    );
  }
}
