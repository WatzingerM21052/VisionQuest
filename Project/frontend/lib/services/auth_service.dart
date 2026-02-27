import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => code == null ? message : '$code: $message';
}

class AuthResponse {
  final bool success;
  final String message;
  final String? code;
  final Map<String, dynamic>? data;
  final int statusCode;

  const AuthResponse({
    required this.success,
    required this.message,
    required this.statusCode,
    this.code,
    this.data,
  });

  String? get token => data?['token'] as String?;
}

abstract class TokenStorage {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> clearToken();
}

class InMemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> readToken() async {
    return _token;
  }

  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() async {
    return _storage.read(key: _tokenKey);
  }

  @override
  Future<void> writeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  @override
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}

class AuthService {
  AuthService({
    this.baseUrl = 'http://localhost:5000/api',
    http.Client? client,
    TokenStorage? storage,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? SecureTokenStorage();

  final String baseUrl;
  final http.Client _client;
  final TokenStorage _storage;

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    return _handleAuthResponse(response, persistToken: true);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    return _handleAuthResponse(response, persistToken: true);
  }

  Future<AuthResponse> refreshToken() async {
    final token = await _storage.readToken();
    if (token == null) {
      throw AuthException('Kein Token gespeichert', code: 'NO_TOKEN');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: _authHeaders(token),
    );

    return _handleAuthResponse(response, persistToken: true);
  }

  Future<AuthResponse> logout() async {
    final token = await _storage.readToken();
    if (token == null) {
      throw AuthException('Kein Token gespeichert', code: 'NO_TOKEN');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: _authHeaders(token),
    );

    final result = _handleAuthResponse(response);
    await _storage.clearToken();
    return result;
  }

  Future<String?> getStoredToken() {
    return _storage.readToken();
  }

  Map<String, String> _jsonHeaders() {
    return const {'Content-Type': 'application/json'};
  }

  Map<String, String> _authHeaders(String token) {
    return {..._jsonHeaders(), 'Authorization': 'Bearer $token'};
  }

  AuthResponse _handleAuthResponse(
    http.Response response, {
    bool persistToken = false,
  }) {
    final Map<String, dynamic> payload = _tryDecode(response.body);
    final success = response.statusCode >= 200 && response.statusCode < 300;
    final message = payload['message']?.toString() ?? 'Unbekannte Antwort';
    final code = payload['code']?.toString();
    final data = payload['data'] as Map<String, dynamic>?;

    final result = AuthResponse(
      success: success,
      message: message,
      statusCode: response.statusCode,
      code: code,
      data: data,
    );

    if (success) {
      if (persistToken && result.token != null) {
        _storage.writeToken(result.token!);
      }
      return result;
    }

    throw AuthException(message, code: code);
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
