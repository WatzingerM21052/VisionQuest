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

  /// Aktuelles Level (startet bei 1).
  final int level;

  /// Konsekutive Tage mit mindestens einem Scan.
  final int streak;

  /// Zeitpunkt des letzten erfolgreichen Scans (für Streak-Berechnung).
  final DateTime? lastCompletedDate;

  /// Berechnet die XP am Start des aktuellen Levels.
  ///
  /// Beispiel: Level 3 startet bei 2000 XP (2 * 1000).
  int get currentLevelStartXp => (level - 1) * 1000;

  /// Berechnet die XP die für das nächste Level benötigt werden.
  ///
  /// Beispiel: Level 3 benötigt 3000 XP zum Aufstieg.
  int get nextLevelXp => level * 1000;

  /// Gibt die XP an die im aktuellen Level bereits gesammelt wurden.
  int get xpIntoCurrentLevel => totalXp - currentLevelStartXp;

  /// Gibt die Gesamt-XP an die für das aktuelle Level benötigt werden.
  ///
  /// Standardmäßig 1000 XP pro Level.
  int get xpRequiredForCurrentLevel => nextLevelXp - currentLevelStartXp;

  /// Berechnet den Fortschritt im aktuellen Level (0.0 - 1.0).
  ///
  /// Wird für die XP-Fortschrittsanzeige verwendet.
  double get levelProgress {
    if (xpRequiredForCurrentLevel <= 0) {
      return 1.0;
    }
    return (xpIntoCurrentLevel / xpRequiredForCurrentLevel).clamp(0.0, 1.0);
  }

  /// Erstellt eine Kopie mit optional geänderten Werten.
  ///
  /// [clearLastCompletedDate] kann verwendet werden um das Datum explizit zu löschen.
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
