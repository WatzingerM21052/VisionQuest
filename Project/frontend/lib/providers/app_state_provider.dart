import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement.dart';
import '../models/app_state.dart';
import '../models/app_theme_option.dart';
import '../models/detection_focus_option.dart';
import '../models/detection_model_option.dart';
import '../models/quest_log_entry.dart';
import '../models/quest_progress.dart';
import '../services/detection_log_service.dart';

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
/// - Achievement freischalten (Object Scan + Milestones)
/// - Detection History synchronisieren
class AppStateNotifier extends StateNotifier<AppState> {
  /// Erstellt einen neuen AppStateNotifier mit Initial-State.
  AppStateNotifier() : super(AppState.initial());

  /// XP-Punkte benötigt für jeden Level-Aufstieg.
  static const int _xpPerLevel = 1000;

  /// Maximale Einträge im Quest-Log (zur Speicheroptimierung).
  static const int _maxLogEntries = 200;

  /// Ändert das aktuelle Theme der Applikation.
  void setTheme(AppThemeOption option) {
    state = state.copyWith(theme: option);
  }

  /// Ändert das Detection-Model (YOLO, etc.).
  void setDetectionModel(DetectionModelOption option) {
    state = state.copyWith(detectionModel: option);
  }

  /// Ändert den Detection-Focus (balanced, precision, speed).
  void setDetectionFocus(DetectionFocusOption option) {
    state = state.copyWith(detectionFocus: option);
  }

  /// Setzt den eingeloggten Benutzernamen.
  ///
  /// Parameter: [username] - Benutzername nach erfolgreichem Login/Register
  void setUsername(String? username) {
    state = state.copyWith(username: username);
  }

  /// Setzt die Benutzerrolle (user oder admin).
  ///
  /// Parameter: [role] - Benutzerrolle nach erfolgreichem Login/Register
  void setUserRole(String? role) {
    state = state.copyWith(userRole: role);
  }

  /// Lädt die Detection-Historie vom Backend/Server.
  ///
  /// Wird beim App-Start und nach dem Login aufgerufen.
  /// Ignoriert Fehler wenn Benutzer nicht eingeloggt ist.
  Future<void> loadStoredEntries() async {
    try {
      final service = DetectionLogService();
      final entries = await service.getDetectionHistory();
      if (entries.isNotEmpty) {
        state = state.copyWith(logEntries: entries);
      }
    } on DetectionLogException catch (e) {
      // Erwarteter Fehler wenn nicht eingeloggt (NO_TOKEN)
      if (e.code == 'NO_TOKEN') {
        return;
      }
      // Andere Fehler Protokollieren aber nicht werfen
      print('Fehler beim Laden der Detection History: $e');
    } catch (e) {
      // Unerwartete Fehler ignorieren
      print('Fehler beim Laden der Detection History: $e');
    }
  }

  /// Aktualisiert den Fortschritt (XP/Level/Streak), z.B. nach Server-Sync.
  void setProgress({
    required int totalXp,
    required int level,
    int? streak,
    DateTime? lastCompletedDate,
  }) {
    state = state.copyWith(
      progress: state.progress.copyWith(
        totalXp: totalXp,
        level: level,
        streak: streak ?? state.progress.streak,
        lastCompletedDate: lastCompletedDate,
      ),
    );

    // Check Milestone-Achievements nach Progress-Update
    _checkMilestoneAchievements();
  }

  /// Verarbeitet einen neuen Quest-Erfolg (Objekterkennung).
  ///
  /// Diese Methode:
  /// 1. Normalisiert die Confidence auf 0.0-1.0
  /// 2. Berechnet XP basierend auf Genauigkeit (10-100 XP)
  /// 3. Aktualisiert Level und Streak
  /// 4. Speichert Eintrag im Quest-Log (lokal)
  /// 5. Sendet den Scan zum Backend/Server
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

    final updatedEntries = [
      newEntry,
      ...state.logEntries,
    ].take(_maxLogEntries).toList();

    state = state.copyWith(
      progress: QuestProgress(
        totalXp: updatedXp,
        level: updatedLevel,
        streak: updatedStreak,
        lastCompletedDate: now,
      ),
      logEntries: updatedEntries,
    );

    // Check und unlock Milestone-Achievements
    _checkMilestoneAchievements();

    // Sende Scan asynchron zum Backend
    _sendDetectionLogToServer(label, normalizedConfidence);
  }

  /// Sendet einen Detection Log zum Backend (asynchron im Hintergrund)
  void _sendDetectionLogToServer(String label, double confidence) {
    Future.microtask(() async {
      try {
        final service = DetectionLogService();
        await service.logDetection(label, confidence);
      } catch (e) {
        print('Fehler beim Senden des Detection Logs: $e');
        // Fehler werden ignoriert - Daten bleiben lokal
      }
    });
  }

  /// Löscht einen Eintrag aus dem Quest-Log (lokal und vom Backend).
  ///
  /// Parameter: [index] - Index des zu löschenden Eintrags in der logEntries Liste
  void deleteLogEntry(int index) {
    if (index < 0 || index >= state.logEntries.length) {
      return;
    }

    final entry = state.logEntries[index];
    final updatedEntries = List<QuestLogEntry>.from(state.logEntries)
      ..removeAt(index);

    state = state.copyWith(logEntries: updatedEntries);

    // Lösche asynchron vom Backend
    _deleteDetectionLogFromServer(entry);
  }

  /// Löscht einen Detection Log vom Backend (asynchron im Hintergrund)
  void _deleteDetectionLogFromServer(QuestLogEntry entry) {
    Future.microtask(() async {
      try {
        final service = DetectionLogService();
        await service.deleteDetection(entry.label, entry.timestamp);
      } catch (e) {
        print('Fehler beim Löschen des Detection Logs: $e');
        // Fehler werden ignoriert
      }
    });
  }

  /// Entsperrt ein Achievement für den aktuellen Benutzer.
  ///
  /// Parameter: [achievementId] - ID des freizuschaltenden Achievements
  void unlockAchievement(String achievementId) {
    if (state.unlockedAchievements.contains(achievementId)) {
      return; // Bereits entsperrt
    }

    final updatedUnlocked = [...state.unlockedAchievements, achievementId];
    state = state.copyWith(unlockedAchievements: updatedUnlocked);

    // Speichere asynchron im Backend
    _saveAchievementsToServer(updatedUnlocked);
  }

  /// Speichert die entsperrten Achievements im Backend (asynchron).
  void _saveAchievementsToServer(List<String> unlockedAchievements) {
    Future.microtask(() async {
      try {
        final service = DetectionLogService();
        await service.saveAchievements(unlockedAchievements);
      } catch (e) {
        print('Fehler beim Speichern der Achievements: $e');
        // Fehler werden ignoriert - lokal gespeichert
      }
    });
  }

  /// Lädt entsperrte Achievements vom Backend.
  Future<void> loadAchievements() async {
    try {
      final service = DetectionLogService();
      final unlockedIds = await service.loadAchievements();
      state = state.copyWith(unlockedAchievements: unlockedIds);
    } on DetectionLogException catch (e) {
      if (e.code == 'NO_TOKEN') {
        return;
      }
      print('Fehler beim Laden der Achievements: $e');
    } catch (e) {
      print('Fehler beim Laden der Achievements: $e');
    }
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

  /// Prüft und entsperrt Milestone-Achievements basierend auf aktuellem Progress.
  ///
  /// Wird nach jedem Scan (addQuestResult) und Progress-Update (setProgress) aufgerufen.
  /// Checkt automatisch:
  /// - scanner_master: 100+ Scans
  /// - level_10: Level 10 erreicht
  /// - streak_champion: 7+ Tage Streak
  /// - xp_collector: 1000+ XP
  /// - completionist: Alle anderen Achievements freigeschaltet
  void _checkMilestoneAchievements() {
    final progress = state.progress;
    final totalScans = state.logEntries.length;
    final unlocked = state.unlockedAchievements;

    // Scanner-Meister: 100+ Scans
    if (totalScans >= 100 && !unlocked.contains('scanner_master')) {
      unlockAchievement('scanner_master');
    }

    // Level 10
    if (progress.level >= 10 && !unlocked.contains('level_10')) {
      unlockAchievement('level_10');
    }

    // Streak-Champion: 7+ Tage
    if (progress.streak >= 7 && !unlocked.contains('streak_champion')) {
      unlockAchievement('streak_champion');
    }

    // XP-Sammler: 1000+ XP
    if (progress.totalXp >= 1000 && !unlocked.contains('xp_collector')) {
      unlockAchievement('xp_collector');
    }

    // Completionist: Alle anderen Achievements freigeschaltet
    // (Zählt nur object_scan und milestone achievements, nicht meta)
    final nonMetaAchievements = allAchievements
        .where((a) => a.type != AchievementType.meta)
        .map((a) => a.id)
        .toList();

    final unlockedNonMeta = unlocked
        .where((id) => nonMetaAchievements.contains(id))
        .length;

    if (unlockedNonMeta >= nonMetaAchievements.length &&
        !unlocked.contains('completionist')) {
      unlockAchievement('completionist');
    }
  }
}
