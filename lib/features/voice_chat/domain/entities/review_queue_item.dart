class ReviewQueueItem {
  final String exerciseId;
  final DateTime dueAt;
  final int intervalDays;
  final DateTime? lastReviewedAt;
  final int failCount;

  const ReviewQueueItem({
    required this.exerciseId,
    required this.dueAt,
    required this.intervalDays,
    required this.lastReviewedAt,
    required this.failCount,
  });

  ReviewQueueItem copyWith({
    String? exerciseId,
    DateTime? dueAt,
    int? intervalDays,
    DateTime? lastReviewedAt,
    bool clearLastReviewedAt = false,
    int? failCount,
  }) {
    return ReviewQueueItem(
      exerciseId: exerciseId ?? this.exerciseId,
      dueAt: dueAt ?? this.dueAt,
      intervalDays: intervalDays ?? this.intervalDays,
      lastReviewedAt:
          clearLastReviewedAt ? null : (lastReviewedAt ?? this.lastReviewedAt),
      failCount: failCount ?? this.failCount,
    );
  }
}
