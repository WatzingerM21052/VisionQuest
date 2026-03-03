import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

class VisionException implements Exception {
  final String message;
  final String? code;

  VisionException(this.message, {this.code});

  @override
  String toString() => code == null ? message : '$code: $message';
}

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

class VisionService {
  VisionService({
    this.baseUrl = 'http://localhost:5000/api',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<VisionResult> detectObject({
    required XFile image,
    required String token,
  }) async {
    final bytes = await image.readAsBytes();
    final fileName = image.name.isNotEmpty ? image.name : 'image.jpg';
    print(
      '[VISION_CLIENT] Sending image: $fileName, size: ${bytes.length} bytes',
    );

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/vision/detect'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: fileName),
    );

    try {
      final response = await http.Response.fromStream(
        await _client.send(request),
      );

      print('[VISION_CLIENT] Response status: ${response.statusCode}');
      print('[VISION_CLIENT] Response body: ${response.body}');

      final payload = _tryDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = payload['data'] as Map<String, dynamic>? ?? {};
        return VisionResult.fromJson(data);
      }

      throw VisionException(
        payload['message']?.toString() ?? 'Erkennung fehlgeschlagen',
        code: payload['code']?.toString(),
      );
    } catch (e) {
      print('[VISION_CLIENT] Error: $e');
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
