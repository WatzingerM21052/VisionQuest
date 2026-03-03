class QuestProgress {
  const QuestProgress({
    required this.totalXp,
    required this.level,
    required this.streak,
    this.lastCompletedDate,
  });

  final int totalXp;
  final int level;
  final int streak;
  final DateTime? lastCompletedDate;

  int get nextLevelXp => level * 1000;

  QuestProgress copyWith({
    int? totalXp,
    int? level,
    int? streak,
    DateTime? lastCompletedDate,
    bool clearLastCompletedDate = false,
  }) {
    return QuestProgress(
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      lastCompletedDate: clearLastCompletedDate
          ? null
          : (lastCompletedDate ?? this.lastCompletedDate),
    );
  }
}
