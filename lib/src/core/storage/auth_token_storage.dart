import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/models/auth_session.dart';

class AuthTokenStorage {
  AuthTokenStorage._(this._preferences);

  static const _sessionKey = 'auth_session';

  final SharedPreferences _preferences;

  static Future<AuthTokenStorage> create() async {
    final preferences = await SharedPreferences.getInstance();
    return AuthTokenStorage._(preferences);
  }

  Future<void> saveSession(AuthSession session) async {
    await _preferences.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<AuthSession?> loadSession() async {
    final raw = _preferences.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return AuthSession.fromJson(decoded);
  }

  Future<void> clear() async {
    await _preferences.remove(_sessionKey);
  }
}
