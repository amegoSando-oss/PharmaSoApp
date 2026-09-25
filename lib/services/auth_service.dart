import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class RememberedCredentials {
  final String email;
  final String password;

  RememberedCredentials({required this.email, required this.password});
}

class AuthService extends ChangeNotifier {
  static const _tokenKey = 'pharmaso_token';
  static const _rememberedEmailKey = 'pharmaso_remembered_email';
  static const _rememberedPasswordKey = 'pharmaso_remembered_password';

  final ApiClient apiClient;

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;

  AuthService(this.apiClient);

  bool get isAuthenticated => status == AuthStatus.authenticated;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    apiClient.setToken(token);
    try {
      final payload = await apiClient.get('/auth/me');
      currentUser = AppUser.fromJson((payload as Map<String, dynamic>)['data'] as Map<String, dynamic>);
      status = AuthStatus.authenticated;
    } catch (_) {
      apiClient.setToken(null);
      await prefs.remove(_tokenKey);
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final payload = await apiClient.post('/auth/token', body: {
      'email': email,
      'password': password,
      'name': 'mobile-app',
    });
    final token = (payload['data'] as Map<String, dynamic>)['token'] as String;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    apiClient.setToken(token);

    final me = await apiClient.get('/auth/me');
    currentUser = AppUser.fromJson((me as Map<String, dynamic>)['data'] as Map<String, dynamic>);
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Note: SharedPreferences is unencrypted on-device storage — this is
  /// what was asked for, but it means the password is recoverable by
  /// anything with filesystem access (a rooted device, an adb backup).
  /// flutter_secure_storage (OS keystore/keychain) would be the safer home
  /// for the password specifically, if that trade-off matters here.
  Future<void> saveRememberedCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rememberedEmailKey, email);
    await prefs.setString(_rememberedPasswordKey, password);
  }

  Future<void> clearRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberedEmailKey);
    await prefs.remove(_rememberedPasswordKey);
  }

  Future<RememberedCredentials?> loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_rememberedEmailKey);
    final password = prefs.getString(_rememberedPasswordKey);
    if (email == null || password == null) return null;
    return RememberedCredentials(email: email, password: password);
  }

  Future<void> logout() async {
    try {
      await apiClient.post('/auth/revoke', prefix: 'revoke');
    } catch (_) {
      // Best-effort: still clear local session even if the network call fails.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    apiClient.setToken(null);
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
