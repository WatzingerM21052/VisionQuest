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

  // Get admin statistics
  Future<Map<String, dynamic>> getStats(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          return json['data'] as Map<String, dynamic>;
        }
      }

      throw AdminException(
        'Fehler beim Abrufen der Statistiken',
        code: 'GET_STATS_FAILED',
      );
    } catch (e) {
      throw AdminException(e.toString(), code: 'GET_STATS_ERROR');
    }
  }

  // Get admin action logs
  Future<List<Map<String, dynamic>>> getLogs(
    String token, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/admin/logs?limit=$limit&offset=$offset'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final logs = json['data']['logs'] as List;
          return logs.map((l) => l as Map<String, dynamic>).toList();
        }
      }

      throw AdminException(
        'Fehler beim Abrufen der Logs',
        code: 'GET_LOGS_FAILED',
      );
    } catch (e) {
      throw AdminException(e.toString(), code: 'GET_LOGS_ERROR');
    }
  }

  // Get action history for a user
  Future<List<Map<String, dynamic>>> getUserHistory(
    String token,
    int userId,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/admin/users/$userId/history'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final actions = json['data']['actions'] as List;
          return actions.map((a) => a as Map<String, dynamic>).toList();
        }
      }

      throw AdminException(
        'Fehler beim Abrufen der User-History',
        code: 'GET_HISTORY_FAILED',
      );
    } catch (e) {
      throw AdminException(e.toString(), code: 'GET_HISTORY_ERROR');
    }
  }

  // Suspend a user
  Future<void> suspendUser(String token, int userId, {String? reason}) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/admin/users/$userId/suspend'),
        headers: _authHeaders(token),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdminException(
          json['message'] as String? ?? 'Fehler beim Suspendieren',
          code: 'SUSPEND_USER_FAILED',
        );
      }
    } catch (e) {
      throw AdminException(e.toString(), code: 'SUSPEND_USER_ERROR');
    }
  }

  // Unsuspend a user
  Future<void> unsuspendUser(String token, int userId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/admin/users/$userId/unsuspend'),
        headers: _authHeaders(token),
      );

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdminException(
          json['message'] as String? ?? 'Fehler beim Entsperren',
          code: 'UNSUSPEND_USER_FAILED',
        );
      }
    } catch (e) {
      throw AdminException(e.toString(), code: 'UNSUSPEND_USER_ERROR');
    }
  }

  // Get all suspensions
  Future<List<Map<String, dynamic>>> getSuspensions(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/admin/suspensions'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final suspensions = json['data']['suspensions'] as List;
          return suspensions.map((s) => s as Map<String, dynamic>).toList();
        }
      }

      throw AdminException(
        'Fehler beim Abrufen der Suspensionen',
        code: 'GET_SUSPENSIONS_FAILED',
      );
    } catch (e) {
      throw AdminException(e.toString(), code: 'GET_SUSPENSIONS_ERROR');
    }
  }

  // Export users as CSV
  Future<String> exportUsersCSV(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/admin/users/export?format=csv'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        return response.body;
      }

      throw AdminException(
        'Fehler beim Exportieren',
        code: 'EXPORT_CSV_FAILED',
      );
    } catch (e) {
      throw AdminException(e.toString(), code: 'EXPORT_CSV_ERROR');
    }
  }

  // Export users as JSON
  Future<Map<String, dynamic>> exportUsersJSON(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/admin/users/export?format=json'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          return json['data'] as Map<String, dynamic>;
        }
      }

      throw AdminException(
        'Fehler beim Exportieren',
        code: 'EXPORT_JSON_FAILED',
      );
    } catch (e) {
      throw AdminException(e.toString(), code: 'EXPORT_JSON_ERROR');
    }
  }

  // Get activity dashboard
  Future<Map<String, dynamic>> getActivity(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/admin/activity'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          return json['data'] as Map<String, dynamic>;
        }
      }

      throw AdminException(
        'Fehler beim Abrufen der Activity-Daten',
        code: 'GET_ACTIVITY_FAILED',
      );
    } catch (e) {
      throw AdminException(e.toString(), code: 'GET_ACTIVITY_ERROR');
    }
  }
}
