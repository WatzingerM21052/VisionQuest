import 'app_theme_option.dart';
import 'quest_log_entry.dart';
import 'quest_progress.dart';

class AppState {
  const AppState({
    required this.theme,
    required this.progress,
    required this.logEntries,
  });

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
