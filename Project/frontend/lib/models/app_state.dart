import 'app_theme_option.dart';
import 'quest_log_entry.dart';
import 'quest_progress.dart';

/// Root-State der VisionQuest-Applikation verwaltet von Riverpod.
///
/// Diese Klasse ist der Single Source of Truth für:
/// - Das aktuelle Theme der App
/// - Den Quest-Fortschritt des Spielers (Level, XP, Streak)
/// - Die Historie aller gefundenen Objekte
class AppState {
  /// Erstellt einen neuen App-State.
  ///
  /// Parameter:
  ///   - [theme]: Aktuelles Theme ([AppThemeOption])
  ///   - [progress]: Quest-Progression ([QuestProgress])
  ///   - [logEntries]: Liste aller Quest-Erfolge (max 200 Einträge)
  const AppState({
    required this.theme,
    required this.progress,
    required this.logEntries,
  });

  /// Erstellt einen Standard-State für neue Sessions.
  ///
  /// Initialisiert:
  /// - Theme auf System-Einstellung
  /// - Spieler auf Level 1, 0 XP
  /// - Leeres Quest-Log
  factory AppState.initial() {
    return const AppState(
      theme: AppThemeOption.system,
      progress: QuestProgress(totalXp: 0, level: 1, streak: 0),
      logEntries: [],
    );
  }

  final AppThemeOption theme;
  final QuestProgress progress;
  final List<QuestLogEntry> logEntries;

  AppState copyWith({
    AppThemeOption? theme,
    QuestProgress? progress,
    List<QuestLogEntry>? logEntries,
  }) {
    return AppState(
      theme: theme ?? this.theme,
      progress: progress ?? this.progress,
      logEntries: logEntries ?? this.logEntries,
    );
  }
}
