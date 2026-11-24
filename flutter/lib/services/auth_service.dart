import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.ra,
    required this.role,
    required this.course,
    required this.periodSemester,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      ra: (json['ra'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      course: (json['course'] ?? '').toString(),
      periodSemester: (json['periodSemester'] ?? '').toString(),
    );
  }

  final String id;
  final String name;
  final String ra;
  final String role;
  final String course;
  final String periodSemester;

  bool get isProfessor => role == 'PROFESSOR';
  bool get isStudent => role == 'STUDENT';
}

class AuthService {
  AuthService({http.Client? client})
      : _client = client ?? http.Client(),
        _storage = const FlutterSecureStorage();

  AuthService.forTest({
    required http.Client client,
    required FlutterSecureStorage storage,
  })  : _client = client,
        _storage = storage;

  final http.Client _client;
  final FlutterSecureStorage _storage;

  static const _accessKey = 'identitas_access_token';
  static const _refreshKey = 'identitas_refresh_token';
  static const _userKey = 'identitas_user';

  Future<({AuthUser user, String accessToken, String refreshToken})> login({
    required String ra,
    required String password,
  }) async {
    final response = await _post(
      '/auth',
      {'ra': ra.trim(), 'password': password},
    );

    final accessToken = response['accessToken'] as String;
    final refreshToken = response['refreshToken'] as String;
    final user = AuthUser.fromJson(
      response['user'] as Map<String, dynamic>,
    );

    await _saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );
    return (user: user, accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<AuthUser?> restoreSession() async {
    String? accessToken;
    String? refreshToken;
    String? userJson;
    try {
      accessToken = await _storage.read(key: _accessKey);
      refreshToken = await _storage.read(key: _refreshKey);
      userJson = await _storage.read(key: _userKey);
    } catch (_) {
      return null;
    }
    if (accessToken == null || refreshToken == null || userJson == null) {
      return null;
    }

    ApiConfig.token = accessToken;
    try {
      final response = await _get('/auth/profile');
      final user = AuthUser.fromJson(response);
      return user;
    } on AuthException catch (_) {
      try {
        final refreshed = await refresh();
        if (refreshed) return await restoreSession();
      } catch (_) {}
    }

    await logout();
    return null;
  }

  Future<bool> refresh() async {
    final refreshToken = await _storage.read(key: _refreshKey);
    if (refreshToken == null) return false;

    final response = await _post('/auth/refresh', {
      'refreshToken': refreshToken,
    }, authenticated: false);
    final accessToken = response['accessToken'] as String;
    final nextRefreshToken = response['refreshToken'] as String;
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: nextRefreshToken);
    ApiConfig.token = accessToken;
    return true;
  }

  Future<void> logout() async {
    ApiConfig.token = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
  }

  Future<void> _saveSession({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) async {
    ApiConfig.token = accessToken;
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
    await _storage.write(
      key: _userKey,
      value: jsonEncode({
        '_id': user.id,
        'name': user.name,
        'ra': user.ra,
        'role': user.role,
        'course': user.course,
        'periodSemester': user.periodSemester,
      }),
    );
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 10));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: authenticated ? _headers() : _headers(includeAuth: false),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    return _decode(response);
  }

  Map<String, String> _headers({bool includeAuth = true}) => {
        'Content-Type': 'application/json',
        if (includeAuth && ApiConfig.token != null)
          'Authorization': 'Bearer ${ApiConfig.token}',
      };

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as dynamic;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map
          ? body.cast<String, dynamic>()
          : <String, dynamic>{};
    }

    final message = body is Map ? body['message'] : null;
    throw AuthException(
      message is List
          ? message.join('\n')
          : (message?.toString() ??
              'Erro ${response.statusCode} ao autenticar.'),
    );
  }
}
