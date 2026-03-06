import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quest_log_entry.dart';

/// Service für die lokale Persistierung von Quest-Log-Einträgen.
///
/// Nutzt SharedPreferences zum Speichern und Laden der Detection-Historie.
/// Max. 200 Einträge werden gespeichert (FIFO).
class QuestLogStorageService {
  static const String _storageKey = 'quest_log_entries';
  static const int _maxEntries = 200;

  /// Lädt alle gespeicherten Quest-Log-Einträge.
  ///
  /// Returns: Liste von QuestLogEntry oder leere Liste bei Fehler
  static Future<List<QuestLogEntry>> loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => _entryFromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading quest log entries: $e');
      return [];
    }
  }

  /// Speichert Quest-Log-Einträge lokal.
  ///
  /// Behält maximal 200 Einträge (FIFO - älteste werden gelöscht).
  ///
  /// Parameter:
  ///   - [entries]: Liste der zu speichernden Einträge
  ///
  /// Returns: true bei Erfolg, false bei Fehler
  static Future<bool> saveEntries(List<QuestLogEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Nur die letzten 200 Einträge behalten
      final entriesToSave = entries.length > _maxEntries
          ? entries.sublist(entries.length - _maxEntries)
          : entries;

      final jsonList = entriesToSave
          .map((entry) => _entryToJson(entry))
          .toList();
      final jsonString = json.encode(jsonList);

      return await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('Error saving quest log entries: $e');
      return false;
    }
  }

  /// Löscht alle gespeicherten Quest-Log-Einträge.
  ///
  /// Returns: true bei Erfolg, false bei Fehler
  static Future<bool> clearEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing quest log entries: $e');
      return false;
    }
  }

  /// Konvertiert QuestLogEntry zu JSON Map.
  static Map<String, dynamic> _entryToJson(QuestLogEntry entry) {
    return {
      'label': entry.label,
      'xp': entry.xp,
      'confidence': entry.confidence,
      'timestamp': entry.timestamp.toIso8601String(),
    };
  }

  /// Erstellt QuestLogEntry aus JSON Map.
  static QuestLogEntry _entryFromJson(Map<String, dynamic> json) {
    return QuestLogEntry(
      label: json['label'] as String,
      xp: json['xp'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
