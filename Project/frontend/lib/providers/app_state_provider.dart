import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_state.dart';
import '../models/app_theme_option.dart';
import '../models/quest_log_entry.dart';
import '../models/quest_progress.dart';

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
      return AppStateNotifier();
    });

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState.initial());

  void setTheme(AppThemeOption option) {
    state = state.copyWith(theme: option);
  }

  void addQuestResult({required String label, required double confidence}) {
    final xp = (confidence * 100).round().clamp(10, 100);
    final now = DateTime.now();

    final previous = state.progress;
    final updatedXp = previous.totalXp + xp;
    final updatedLevel = (updatedXp ~/ 1000) + 1;
    final updatedStreak = _calculateStreak(previous.lastCompletedDate, now);

    final newEntry = QuestLogEntry(
      label: label,
      xp: xp,
      confidence: confidence,
      timestamp: now,
    );

    state = state.copyWith(
      progress: QuestProgress(
        totalXp: updatedXp,
        level: updatedLevel,
        streak: updatedStreak,
        lastCompletedDate: now,
      ),
      logEntries: [newEntry, ...state.logEntries],
    );
  }

  int _calculateStreak(DateTime? previousDate, DateTime currentDate) {
    if (previousDate == null) {
      return 1;
    }

    final previousDay = DateTime(
      previousDate.year,
      previousDate.month,
      previousDate.day,
    );
    final currentDay = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    final dayDiff = currentDay.difference(previousDay).inDays;

    if (dayDiff == 0) {
      return state.progress.streak;
    }
    if (dayDiff == 1) {
      return state.progress.streak + 1;
    }
    return 1;
  }
}
