import 'dart:convert';
import 'package:http/http.dart' as http;

class User {
  final int id;
  final String username;
  final String email;
  final int level;
  final int xp;
  final String role;
  final bool isActive;
  final String createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.level,
    required this.xp,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    dynamic pick(String lower, String upper) {
      if (json.containsKey(lower)) return json[lower];
      if (json.containsKey(upper)) return json[upper];
      return null;
    }

    int toInt(dynamic value, int fallback) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    String toStr(dynamic value, String fallback) {
      if (value == null) return fallback;
      return value.toString();
    }

    return User(
      id: toInt(pick('id', 'ID'), 0),
      username: toStr(pick('username', 'USERNAME'), ''),
      email: toStr(pick('email', 'EMAIL'), ''),
      level: toInt(pick('level', 'LEVEL'), 1),
      xp: toInt(pick('xp', 'XP'), 0),
      role: toStr(pick('role', 'ROLE'), 'user'),
      isActive: toInt(pick('is_active', 'IS_ACTIVE'), 1) == 1,
      createdAt: toStr(pick('created_at', 'CREATED_AT'), ''),
    );
  }
}

class AdminException implements Exception {
  final String message;
  final String? code;

  AdminException(this.message, {this.code});

  @override
  String toString() => code == null ? message : '$code: $message';
}

class AdminService {
  AdminService({
    this.baseUrl = 'http://localhost:5000/api',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> _authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all users
  Future<List<User>> getAllUsers(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final users = json['data']['users'] as List;
          return users
              .map((u) => User.fromJson(u as Map<String, dynamic>))
              .toList();
        }
      }

      throw AdminException(
        'Fehler beim Abrufen der User-Liste',
        code: 'GET_USERS_FAILED',
      );
    } catch (e) {
      throw AdminException(e.toString(), code: 'GET_USERS_ERROR');
    }
  }

  // Update user
  Future<void> updateUser(
    String token,
    int userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: _authHeaders(token),
        body: jsonEncode(updates),
      );

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdminException(
          json['message'] as String? ?? 'Fehler beim Aktualisieren',
          code: 'UPDATE_USER_FAILED',
        );
      }
    } catch (e) {
      throw AdminException(e.toString(), code: 'UPDATE_USER_ERROR');
    }
  }

  // Delete user
  Future<void> deleteUser(String token, int userId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: _authHeaders(token),
      );

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdminException(
          json['message'] as String? ?? 'Fehler beim Löschen',
          code: 'DELETE_USER_FAILED',
        );
      }
    } catch (e) {
      throw AdminException(e.toString(), code: 'DELETE_USER_ERROR');
    }
  }
}
