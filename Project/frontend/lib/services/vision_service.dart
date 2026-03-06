import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

/// Exception die bei Vision-API Fehlern geworfen wird.
///
/// Wird bei Detection-Fehlern oder Netzwerk-Problemen geworfen.
class VisionException implements Exception {
  final String message;
  final String? code;

  VisionException(this.message, {this.code});

  @override
  String toString() => code == null ? message : '$code: $message';
}

/// Result-Objekt für Object-Detection.
///
/// Enthält:
/// - `label`: Erkanntes Objekt (z.B. "book", "phone")
/// - `confidence`: Vertrauenswert 0.0 - 1.0
/// - `predictions`: Rohe Prediction-Daten vom ML-Model
class VisionResult {
  final String label;
  final double confidence;
  final List<dynamic> predictions;

  VisionResult({
    required this.label,
    required this.confidence,
    required this.predictions,
  });

  factory VisionResult.fromJson(Map<String, dynamic> json) {
    return VisionResult(
      label: json['label']?.toString() ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      predictions: json['predictions'] as List<dynamic>? ?? [],
    );
  }
}

/// Service für Object-Detection via Backend.
///
/// Kommuniziert mit dem `/api/vision/detect` Endpoint.
/// Sendet Bilder (als Multipart Form Data) und erhält VisionResult zurück.
///
/// Unterstützt verschiedene Models (z.B. YOLO) und Detection Modes (balanced/precision/speed).
class VisionService {
  VisionService({
    this.baseUrl = 'http://localhost:5000/api',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// Sendet ein Bild zur Object-Detection an das Backend.
  ///
  /// POST /api/vision/detect (Multipart Form Data)
  ///
  /// Parameter:
  /// - `image`: XFile vom Camera-Plugin
  /// - `token`: JWT Auth-Token
  /// - `model`: Detection Model (z.B. "yolo")
  /// - `focus`: Detection Mode ("balanced", "precision", "speed")
  ///
  /// Gibt [VisionResult] mit erkanntem Objekt zurück.
  ///
  /// Throws [VisionException] bei Netzwerk- oder Detection-Fehlern.
  Future<VisionResult> detectObject({
    required XFile image,
    required String token,
    String model = 'yolo',
    String focus = 'balanced',
  }) async {
    final bytes = await image.readAsBytes();
    final fileName = image.name.isNotEmpty ? image.name : 'image.jpg';

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/vision/detect'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['x-vision-model'] = model;
    request.headers['x-vision-focus'] = focus;
    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: fileName),
    );

    try {
      final response = await http.Response.fromStream(
        await _client.send(request),
      );

      final payload = _tryDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = payload['data'] as Map<String, dynamic>? ?? {};
        return VisionResult.fromJson(data);
      }

      throw VisionException(
        payload['message']?.toString() ?? 'Erkennung fehlgeschlagen',
        code: payload['code']?.toString(),
      );
    } catch (_) {
      rethrow;
    }
  }

  Map<String, dynamic> _tryDecode(String body) {
    if (body.isEmpty) {
      return {};
    }

    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
