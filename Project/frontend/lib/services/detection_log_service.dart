import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/quest_log_entry.dart';

/// Exception die bei Detection-Log API-Fehlern geworfen wird.
///
/// Enthält eine Fehlermeldung und optional einen Error-Code vom Backend.
class DetectionLogException implements Exception {
  final String message;
  final String? code;

  DetectionLogException(this.message, {this.code});

  @override
  String toString() => code == null ? message : '$code: $message';
}

/// Service für Detection-Log Verwaltung.
///
/// Kommuniziert mit dem Backend `/api/detection-log` Endpoint.
/// Features:
/// - Scan-Results speichern (logDetection)
/// - History laden (getDetectionHistory, getTodayDetections)
/// - Stats abrufen (getDetectionStats)
/// - Logs löschen (deleteDetection, deleteDetectionHistory)
class DetectionLogService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _secureStorage = 'auth_token';
  final _storage = const FlutterSecureStorage();

  /// Speichert einen neuen Detection Scan auf dem Server.
  ///
  /// POST /api/detection-log mit JSON Body:
  /// ```json
  /// {"label": "book", "confidence": 0.95}
  /// ```
  ///
  /// Throws [DetectionLogException] bei Netzwerk- oder Auth-Fehlern.
  Future<void> logDetection(String label, double confidence) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw DetectionLogException(
          'Authentifizierung erforderlich',
          code: 'NO_TOKEN',
        );
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/detection-log'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'label': label, 'confidence': confidence}),
      );

      if (response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw DetectionLogException(
          errorData['message'] ?? 'Fehler beim Speichern des Scans',
          code: errorData['code'],
        );
      }
    } catch (e) {
      if (e is DetectionLogException) {
        rethrow;
      }
      throw DetectionLogException('Fehler beim Speichern des Scans: $e');
    }
  }

  /// Holt die komplette Detection History des Users.
  ///
  /// GET /api/detection-log?days=7 (optional)
  /// Gibt Liste von QuestLogEntry zurück.
  ///
  /// Throws [DetectionLogException] bei Netzwerk- oder Auth-Fehlern.
  Future<List<QuestLogEntry>> getDetectionHistory({int? daysBack}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw DetectionLogException(
          'Authentifizierung erforderlich',
          code: 'NO_TOKEN',
        );
      }

      String url = '$_baseUrl/detection-log';
      if (daysBack != null) {
        url += '?days=$daysBack';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final entries =
            (data['data']['entries'] as List?)?.cast<Map<String, dynamic>>() ??
            [];

        return entries.map((entry) {
          final createdAt = entry['CREATED_AT'] as String?;
          return QuestLogEntry(
            label: entry['LABEL'] as String,
            xp: 10, // Default XP (wird vom Backend nicht mitgesendet, aber Frontend braucht es)
            confidence: (entry['CONFIDENCE'] as num).toDouble(),
            timestamp: createdAt != null
                ? DateTime.parse(createdAt)
                : DateTime.now(),
          );
        }).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw DetectionLogException(
          errorData['message'] ?? 'Fehler beim Abrufen der History',
          code: errorData['code'],
        );
      }
    } catch (e) {
      if (e is DetectionLogException) {
        rethrow;
      }
      throw DetectionLogException('Fehler beim Abrufen der History: $e');
    }
  }

  /// Holt nur die heutigen Detections.
  ///
  /// GET /api/detection-log/today
  /// Gibt Liste von QuestLogEntry zurück (nur heute).
  ///
  /// Throws [DetectionLogException] bei Netzwerk- oder Auth-Fehlern.
  Future<List<QuestLogEntry>> getTodayDetections() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw DetectionLogException(
          'Authentifizierung erforderlich',
          code: 'NO_TOKEN',
        );
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/detection-log/today'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final entries =
            (data['data']['entries'] as List?)?.cast<Map<String, dynamic>>() ??
            [];

        return entries.map((entry) {
          final createdAt = entry['created_at'] as String?;
          return QuestLogEntry(
            label: entry['label'] as String,
            xp: 10, // Default XP
            confidence: (entry['confidence'] as num).toDouble(),
            timestamp: createdAt != null
                ? DateTime.parse(createdAt)
                : DateTime.now(),
          );
        }).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw DetectionLogException(
          errorData['message'] ?? 'Fehler beim Abrufen der heutigen Detections',
          code: errorData['code'],
        );
      }
    } catch (e) {
      if (e is DetectionLogException) {
        rethrow;
      }
      throw DetectionLogException(
        'Fehler beim Abrufen der heutigen Detections: $e',
      );
    }
  }

  /// Holt Statistiken für alle Detections.
  ///
  /// GET /api/detection-log/stats
  /// Gibt DetectionStats Objekt zurück.
  ///
  /// Throws [DetectionLogException] bei Netzwerk- oder Auth-Fehlern.
  Future<DetectionStats> getDetectionStats() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw DetectionLogException(
          'Authentifizierung erforderlich',
          code: 'NO_TOKEN',
        );
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/detection-log/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DetectionStats.fromJson(data['data']);
      } else {
        final errorData = jsonDecode(response.body);
        throw DetectionLogException(
          errorData['message'] ?? 'Fehler beim Abrufen der Stats',
          code: errorData['code'],
        );
      }
    } catch (e) {
      if (e is DetectionLogException) {
        rethrow;
      }
      throw DetectionLogException('Fehler beim Abrufen der Stats: $e');
    }
  }

  /// Löscht die komplette Detection History (GDPR).
  ///
  /// DELETE /api/detection-log
  /// Entfernt alle Scan-Logs des Users (für GDPR-Compliance).
  ///
  /// Throws [DetectionLogException] bei Netzwerk- oder Auth-Fehlern.
  Future<void> deleteDetectionHistory() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw DetectionLogException(
          'Authentifizierung erforderlich',
          code: 'NO_TOKEN',
        );
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/detection-log'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw DetectionLogException(
          errorData['message'] ?? 'Fehler beim Löschen der History',
          code: errorData['code'],
        );
      }
    } catch (e) {
      if (e is DetectionLogException) {
        rethrow;
      }
      throw DetectionLogException('Fehler beim Löschen der History: $e');
    }
  }

  /// Holt den gespeicherten Auth-Token aus SecureStorage.
  ///
  /// Gibt `null` zurück wenn kein Token vorhanden.
  Future<String?> getStoredToken() async {
    return await _getToken();
  }

  /// Löscht einen einzelnen Detection Log Eintrag.
  ///
  /// DELETE /api/detection-log?label=book&timestamp=2024-01-01T12:00:00
  /// Entfernt einen spezifischen Scan aus der History.
  ///
  /// Throws [DetectionLogException] bei Netzwerk- oder Auth-Fehlern.
  Future<void> deleteDetection(String label, DateTime timestamp) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw DetectionLogException(
          'Authentifizierung erforderlich',
          code: 'NO_TOKEN',
        );
      }

      final response = await http.delete(
        Uri.parse(
          '$_baseUrl/detection-log?label=$label&timestamp=${timestamp.toIso8601String()}',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw DetectionLogException(
          errorData['message'] ?? 'Fehler beim Löschen des Eintrags',
          code: errorData['code'],
        );
      }
    } catch (e) {
      if (e is DetectionLogException) {
        rethrow;
      }
      throw DetectionLogException('Fehler beim Löschen des Eintrags: $e');
    }
  }

  /// Speichert die entsperrten Achievements im Backend.
  ///
  /// POST /api/achievements mit JSON Body:
  /// ```json
  /// {"unlockedAchievements": ["phone_finder", "book_lover", ...]}
  /// ```
  ///
  /// Throws [DetectionLogException] bei Netzwerk- oder Auth-Fehlern.
  Future<void> saveAchievements(List<String> unlockedAchievementIds) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw DetectionLogException(
          'Authentifizierung erforderlich',
          code: 'NO_TOKEN',
        );
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/achievements'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'unlockedAchievements': unlockedAchievementIds}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw DetectionLogException(
          errorData['message'] ?? 'Fehler beim Speichern der Achievements',
          code: errorData['code'],
        );
      }
    } catch (e) {
      if (e is DetectionLogException) {
        rethrow;
      }
      throw DetectionLogException('Fehler beim Speichern der Achievements: $e');
    }
  }

  /// Lädt die entsperrten Achievements vom Backend.
  ///
  /// GET /api/achievements
  /// Gibt Liste der Achievement-IDs zurück (z.B. ["phone_finder", "book_lover"]).
  ///
  /// Throws [DetectionLogException] bei Netzwerk- oder Auth-Fehlern.
  Future<List<String>> loadAchievements() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw DetectionLogException(
          'Authentifizierung erforderlich',
          code: 'NO_TOKEN',
        );
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/achievements'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final achievements =
            (data['data']['unlockedAchievements'] as List?)?.cast<String>() ??
            [];
        return achievements;
      } else {
        final errorData = jsonDecode(response.body);
        throw DetectionLogException(
          errorData['message'] ?? 'Fehler beim Laden der Achievements',
          code: errorData['code'],
        );
      }
    } catch (e) {
      if (e is DetectionLogException) {
        rethrow;
      }
      throw DetectionLogException('Fehler beim Laden der Achievements: $e');
    }
  }

  /// Holt den JWT-Token aus dem FlutterSecureStorage.
  ///
  /// Private Helper-Methode für alle API-Calls.
  /// Gibt `null` zurück wenn kein Token vorhanden.
  Future<String?> _getToken() async {
    return await _storage.read(key: _secureStorage);
  }
}

/// Stats-Modell für Detection-Log Statistiken.
///
/// Enthält:
/// - `todayScans`: Anzahl Scans heute
/// - `allTimeScans`: Gesamt-Anzahl Scans
/// - `uniqueObjectsFound`: Verschiedene Objekt-Typen gescannt
/// - `lastScanTime`: Zeitpunkt des letzten Scans (ISO 8601 String)
class DetectionStats {
  final int todayScans;
  final int allTimeScans;
  final int uniqueObjectsFound;
  final String? lastScanTime;

  DetectionStats({
    required this.todayScans,
    required this.allTimeScans,
    required this.uniqueObjectsFound,
    this.lastScanTime,
  });

  factory DetectionStats.fromJson(Map<String, dynamic> json) {
    return DetectionStats(
      todayScans: json['todayScans'] as int? ?? 0,
      allTimeScans: json['allTimeScans'] as int? ?? 0,
      uniqueObjectsFound: json['uniqueObjectsFound'] as int? ?? 0,
      lastScanTime: json['lastScanTime'] as String?,
    );
  }
}
