/// Datensatz für einen einzelnen Quest-Erfolg im Log.
///
/// Wird in der Quest-Log-Liste gespeichert und zeigt Details
/// über gefundene Objekte sowie erhaltene Erfahrungspunkte.
class QuestLogEntry {
  /// Erstellt einen neuen Quest-Log-Eintrag.
  ///
  /// Parameter:
  ///   - [label]: Name des erkannten Objekts (z.B. "Apfel")
  ///   - [xp]: Verdiente Erfahrungspunkte (10-100)
  ///   - [confidence]: Erkennungsgenauigkeit als Dezimalzahl (0.0-1.0)
  ///   - [timestamp]: Zeitpunkt des Fund-Erfolgs
  const QuestLogEntry({
    required this.label,
    required this.xp,
    required this.confidence,
    required this.timestamp,
  });

  /// Name des erkannten Objekts.
  final String label;

  /// Verdiente Erfahrungspunkte von diesem Fund.
  final int xp;

  /// Erkennungsgenauigkeit des Vision-Service (0.0 = unsicher, 1.0 = sicher).
  final double confidence;

  /// Zeitpunkt, zu dem das Objekt gefunden wurde.
  final DateTime timestamp;
}
