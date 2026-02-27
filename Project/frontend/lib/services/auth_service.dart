import 'dart:convert';

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
    throw UnimplementedError();
  }

  @override
  Future<void> writeToken(String token) async {
    throw UnimplementedError();
  }

  @override
  Future<void> clearToken() async {
    throw UnimplementedError();
  }
}

class AuthService {
  AuthService({
    this.baseUrl = 'http://localhost:5000/api',
    http.Client? client,
    TokenStorage? storage,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? InMemoryTokenStorage();

  final String baseUrl;
  final http.Client _client;
  final TokenStorage _storage;

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  Future<AuthResponse> refreshToken() async {
    throw UnimplementedError();
  }

  Future<AuthResponse> logout() async {
    throw UnimplementedError();
  }

  Future<String?> getStoredToken() {
    throw UnimplementedError();
  }

  Map<String, String> _jsonHeaders() {
    throw UnimplementedError();
  }

  Map<String, String> _authHeaders(String token) {
    throw UnimplementedError();
  }

  AuthResponse _handleAuthResponse(
    http.Response response, {
    bool persistToken = false,
  }) {
    throw UnimplementedError();
  }

  Map<String, dynamic> _tryDecode(String body) {
    throw UnimplementedError();
  }
}
