import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Exception die bei Authentifizierungs-Fehlern geworfen wird.
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => code == null ? message : '$code: $message';
}

/// Response-Objekt für Auth-Anfragen (Login/Register).
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

  String? get username {
    final userData = data?['user'];
    if (userData is Map<String, dynamic>) {
      return userData['username']?.toString();
    }
    if (userData is Map) {
      return userData['username']?.toString();
    }
    return data?['username']?.toString();
  }

  String? get userRole {
    final userData = data?['user'];
    if (userData is Map<String, dynamic>) {
      return userData['role']?.toString();
    }
    if (userData is Map) {
      return userData['role']?.toString();
    }
    return data?['role']?.toString();
  }
}

/// Abstrakte Schnittstelle für Token-Speicherung.
///
/// Erlaubt verschiedene Implementierungen (Secure Storage, In-Memory, etc.)
abstract class TokenStorage {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> clearToken();
  Future<String?> readUsername();
  Future<void> writeUsername(String username);
  Future<void> clearUsername();
}

class InMemoryTokenStorage implements TokenStorage {
  String? _token;
  String? _username;

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

  @override
  Future<String?> readUsername() async {
    return _username;
  }

  @override
  Future<void> writeUsername(String username) async {
    _username = username;
  }

  @override
  Future<void> clearUsername() async {
    _username = null;
  }
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'auth_username';
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

  @override
  Future<String?> readUsername() async {
    return _storage.read(key: _usernameKey);
  }

  @override
  Future<void> writeUsername(String username) async {
    await _storage.write(key: _usernameKey, value: username);
  }

  @override
  Future<void> clearUsername() async {
    await _storage.delete(key: _usernameKey);
  }
}

class AuthService {
  AuthService({
    this.baseUrl = ApiConfig.baseUrl,
    http.Client? client,
    TokenStorage? storage,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? SecureTokenStorage();

  final String baseUrl;
  final http.Client _client;
  final TokenStorage _storage;

  // Public getter für Token Storage (für Admin-Screen etc.)
  TokenStorage get storage => _storage;

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

    return await _handleAuthResponse(response, persistToken: true);
  }

  Future<AuthResponse> login({
    required String password,
    String? email,
    String? username,
  }) async {
    // Mindestens email oder username erforderlich
    if ((email == null || email.isEmpty) &&
        (username == null || username.isEmpty)) {
      throw AuthException(
        'Email oder Username erforderlich',
        code: 'MISSING_CREDENTIALS',
      );
    }

    final body = {'password': password};
    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }
    if (username != null && username.isNotEmpty) {
      body['username'] = username;
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );

    return await _handleAuthResponse(response, persistToken: true);
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

    return await _handleAuthResponse(response, persistToken: true);
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

    final result = await _handleAuthResponse(response);
    await _storage.clearToken();
    await _storage.clearUsername();
    return result;
  }

  Future<String?> getStoredToken() {
    return _storage.readToken();
  }

  Future<String?> getStoredUsername() {
    return _storage.readUsername();
  }

  Map<String, String> _jsonHeaders() {
    return const {'Content-Type': 'application/json'};
  }

  Map<String, String> _authHeaders(String token) {
    return {..._jsonHeaders(), 'Authorization': 'Bearer $token'};
  }

  Future<AuthResponse> _handleAuthResponse(
    http.Response response, {
    bool persistToken = false,
  }) async {
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
        await _storage.writeToken(result.token!);
      }
      final username = result.username?.trim();
      if (persistToken && username != null && username.isNotEmpty) {
        await _storage.writeUsername(username);
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
