import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/quest_log_entry.dart';

class DetectionLogException implements Exception {
  final String message;
  final String? code;

  DetectionLogException(this.message, {this.code});

  @override
  String toString() => code == null ? message : '$code: $message';
}

class DetectionLogService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _secureStorage = 'auth_token';
  final _storage = const FlutterSecureStorage();

  /// Speichert einen neuen Detection Scan auf dem Server
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

  /// Holt die komplette Detection History des Users
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

  /// Holt nur die heutigen Detections
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

  /// Holt Stats für Detections
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

  /// Löscht die komplette Detection History (GDPR)
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

  /// Holt den gespeicherten Auth-Token
  Future<String?> getStoredToken() async {
    return await _getToken();
  }

  /// Holt den Token aus dem SecureStorage
  Future<String?> _getToken() async {
    return await _storage.read(key: _secureStorage);
  }
}

/// Stats Modell für Detection Log
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
