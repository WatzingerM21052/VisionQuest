/// Verwaltet die Quest-Progression des Spielers (Level, XP, Streak).
///
/// Diese unveränderliche Klasse enthält alle Fortschritts-Metriken
/// und bietet berechnete Eigenschaften für XP-Balken und Level-Info.
class QuestProgress {
  /// Erstellt einen neuen Quest-Fortschritt.
  ///
  /// Parameter:
  ///   - [totalXp]: Gesamt-Erfahrungspunkte (kumulativ)
  ///   - [level]: Aktuelles Spieler-Level (1-basiert)
  ///   - [streak]: Aktuelle Streak-Zahl (konsekutive Tage)
  ///   - [lastCompletedDate]: Datum des letzten Quest-Erfolgs (für Streak-Logik)
  const QuestProgress({
    required this.totalXp,
    required this.level,
    required this.streak,
    this.lastCompletedDate,
  });

  /// Gesamt-Erfahrungspunkte des Spielers.
  final int totalXp;
  final int level;
  final int streak;
  final DateTime? lastCompletedDate;

  int get currentLevelStartXp => (level - 1) * 1000;

  int get nextLevelXp => level * 1000;

  int get xpIntoCurrentLevel => totalXp - currentLevelStartXp;

  int get xpRequiredForCurrentLevel => nextLevelXp - currentLevelStartXp;

  double get levelProgress {
    if (xpRequiredForCurrentLevel <= 0) {
      return 1;
    }
    return (xpIntoCurrentLevel / xpRequiredForCurrentLevel).clamp(0, 1);
  }

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
