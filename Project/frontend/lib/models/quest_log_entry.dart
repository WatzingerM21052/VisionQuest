class QuestLogEntry {
  const QuestLogEntry({
    required this.label,
    required this.xp,
    required this.confidence,
    required this.timestamp,
  });

  final String label;
  final int xp;
  final double confidence;
  final DateTime timestamp;
}
