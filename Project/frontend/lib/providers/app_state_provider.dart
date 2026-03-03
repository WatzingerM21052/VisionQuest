import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_state.dart';
import '../models/app_theme_option.dart';
import '../models/quest_log_entry.dart';
import '../models/quest_progress.dart';

/// Globaler Riverpod Provider für [AppState] State Management.
///
/// Dieser Provider ist die zentrale Quelle für alle globalen Applikations-Daten.
/// Kann mit `ref.watch()` oder `ref.read()` in beliebigen Widgets zugegriffen werden.
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((
  ref,
) {
  return AppStateNotifier();
});

/// StateNotifier für [AppState] Management via Riverpod.
///
/// Verwaltet State-Übergänge für:
/// - Theme-Wechsel
/// - Quest-Ergebnisse verarbeiten
/// - Level/XP/Streak berechnen
class AppStateNotifier extends StateNotifier<AppState> {
  /// Erstellt einen neuen AppStateNotifier mit Initial-State.
  AppStateNotifier() : super(AppState.initial());

  /// XP-Punkte benötigt für jeden Level-Aufstieg.
  static const int _xpPerLevel = 1000;

  /// Maximale Einträge im Quest-Log (zur Speicheroptimierung).
  static const int _maxLogEntries = 200;

  /// Ändert das aktuelle Theme der Applikation.
  ///
  /// Parameter: [option] - Ein [AppThemeOption] Value (light, dark, system, etc.)
  void setTheme(AppThemeOption option) {
    state = state.copyWith(theme: option);
  }

  /// Verarbeitet einen neuen Quest-Erfolg (Objekterkennung).
  ///
  /// Diese Methode:
  /// 1. Normalisiert die Confidence auf 0.0-1.0
  /// 2. Berechnet XP basierend auf Genauigkeit (10-100 XP)
  /// 3. Aktualisiert Level und Streak
  /// 4. Speichert Eintrag im Quest-Log (maximal 200 Einträge)
  ///
  /// Parameter:
  ///   - [label]: Name des erkannten Objekts
  ///   - [confidence]: Erkennungsgenauigkeit (0.0-1.0)
  void addQuestResult({required String label, required double confidence}) {
    final normalizedConfidence = confidence.clamp(0.0, 1.0);
    final xp = _xpFromConfidence(normalizedConfidence);
    final now = DateTime.now();

    final previous = state.progress;
    final updatedXp = (previous.totalXp + xp).clamp(0, 1 << 30);
    final updatedLevel = _levelFromXp(updatedXp);
    final updatedStreak = _calculateStreak(previous.lastCompletedDate, now);

    final newEntry = QuestLogEntry(
      label: label,
      xp: xp,
      confidence: normalizedConfidence,
      timestamp: now,
    );

    state = state.copyWith(
      progress: QuestProgress(
        totalXp: updatedXp,
        level: updatedLevel,
        streak: updatedStreak,
        lastCompletedDate: now,
      ),
      logEntries: [newEntry, ...state.logEntries].take(_maxLogEntries).toList(),
    );
  }

  int _xpFromConfidence(double confidence) {
    return (confidence * 100).round().clamp(10, 100);
  }

  int _levelFromXp(int xp) {
    return (xp ~/ _xpPerLevel) + 1;
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
