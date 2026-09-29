import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../models/user.dart';
import 'data_cache.dart';

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
  static const _cachedUserKey = 'auth_me';
  // Deliberately separate from _rememberedEmailKey/_rememberedPasswordKey
  // (the user-visible "Remember me" toggle, which only controls whether the
  // Login form is pre-filled next time): offline sign-in must work for
  // whoever last successfully logged in on this device regardless of
  // whether they opted into that toggle, since typing the same correct
  // password again is itself the thing proving it's really them.
  static const _lastLoginEmailKey = 'pharmaso_last_login_email';
  static const _lastLoginPasswordKey = 'pharmaso_last_login_password';

  final ApiClient apiClient;

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;

  Completer<bool>? _silentLoginCompleter;

  AuthService(this.apiClient) {
    apiClient.onUnauthenticated = silentLogin;
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Performs a silent background login using the saved credentials from the last
  /// successful login on this device.
  ///
  /// Deduplicates concurrent calls so multiple requests receiving 401 at the same
  /// time share a single background re-authentication attempt.
  Future<bool> silentLogin() async {
    if (_silentLoginCompleter != null) {
      debugPrint('[AuthService] silentLogin: attempt already in progress, awaiting result...');
      return _silentLoginCompleter!.future;
    }

    final completer = Completer<bool>();
    _silentLoginCompleter = completer;

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_lastLoginEmailKey);
      final password = prefs.getString(_lastLoginPasswordKey);

      if (email == null || password == null) {
        debugPrint('[AuthService] silentLogin: no saved last-login credentials on device');
        completer.complete(false);
        return false;
      }

      debugPrint('[AuthService] silentLogin: attempting background re-login for $email...');
      final payload = await apiClient.post('/auth/token', body: {
        'login': email,
        'password': password,
        'name': 'mobile-app',
      });

      final newToken = (payload['data'] as Map<String, dynamic>)['token'] as String;
      await prefs.setString(_tokenKey, newToken);
      apiClient.setToken(newToken);

      final me = await apiClient.get('/auth/me');
      final data = (me as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      currentUser = AppUser.fromJson(data);
      status = AuthStatus.authenticated;
      await DataCache.instance.put(_cachedUserKey, data);

      debugPrint('[AuthService] silentLogin: success! Acquired new token & refreshed cached profile for ${currentUser?.email}');
      notifyListeners();
      completer.complete(true);
      return true;
    } catch (e) {
      debugPrint('[AuthService] silentLogin: background login failed ($e)');
      completer.complete(false);
      return false;
    } finally {
      _silentLoginCompleter = null;
    }
  }

  /// A saved token is enough to use the app offline — this only ever clears
  /// it when the *server* actually says it's invalid (401/403), never just
  /// because there was no response at all. Otherwise a rep who opens the app
  /// with no signal would get bounced to the login screen despite having a
  /// perfectly good session, defeating the whole point of working offline.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    debugPrint('[AuthService] restoreSession: saved token ${token == null ? 'MISSING' : 'present len ${token.length}'}');
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    apiClient.setToken(token);
    try {
      final payload = await apiClient.get('/auth/me');
      final data = (payload as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      currentUser = AppUser.fromJson(data);
      status = AuthStatus.authenticated;
      await DataCache.instance.put(_cachedUserKey, data);
      debugPrint('[AuthService] restoreSession: verified online, cached profile for ${currentUser?.email}');
    } on ApiException catch (e) {
      // A real response, not just silence — only this means the token is
      // actually rejected server-side (expired/revoked/wrong scope).
      if (e.statusCode == 401 || e.statusCode == 403) {
        debugPrint('[AuthService] restoreSession: server rejected token (${e.statusCode}) — attempting silent re-login');
        final reLoggedIn = await silentLogin();
        if (!reLoggedIn) {
          debugPrint('[AuthService] restoreSession: silent login failed — logging out');
          apiClient.setToken(null);
          await prefs.remove(_tokenKey);
          status = AuthStatus.unauthenticated;
          await DataCache.instance.delete(_cachedUserKey);
        }
      } else {
        debugPrint('[AuthService] restoreSession: server error (${e.statusCode}) unrelated to auth — falling back to cache');
        await _restoreFromCacheOrKeepUnknown();
      }
    } catch (e) {
      // No response at all — offline. Keep the saved token and fall back to
      // the last-known user profile (always present once any login has ever
      // succeeded on this device, since login() caches it too) so the rest
      // of the app can treat this as a normal authenticated session.
      debugPrint('[AuthService] restoreSession: no response ($e) — falling back to cache');
      await _restoreFromCacheOrKeepUnknown();
    }
    debugPrint('[AuthService] restoreSession: final status=$status, user=${currentUser?.email}');
    notifyListeners();
  }

  /// Silent background counterpart to [restoreSession] — call this whenever
  /// the app notices it's back online *while already running* (not just at
  /// cold start), so a token that got revoked/expired server-side while this
  /// device was offline eventually gets noticed instead of the app quietly
  /// 401ing forever. Exactly the same rule as [restoreSession]: only an
  /// actual 401/403 from the server signs this rep out — a network hiccup
  /// mid-check changes nothing about the current session, and there's no
  /// screen in context here to show an error on anyway.
  Future<void> revalidateTokenIfNeeded() async {
    if (!isAuthenticated) return;
    try {
      final payload = await apiClient.get('/auth/me');
      final data = (payload as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      currentUser = AppUser.fromJson(data);
      await DataCache.instance.put(_cachedUserKey, data);
      debugPrint('[AuthService] revalidateTokenIfNeeded: still valid, refreshed cached profile for ${currentUser?.email}');
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        debugPrint('[AuthService] revalidateTokenIfNeeded: server rejected token (${e.statusCode}) — attempting silent re-login');
        final reLoggedIn = await silentLogin();
        if (!reLoggedIn) {
          debugPrint('[AuthService] revalidateTokenIfNeeded: silent login failed — logging out');
          final prefs = await SharedPreferences.getInstance();
          apiClient.setToken(null);
          await prefs.remove(_tokenKey);
          currentUser = null;
          status = AuthStatus.unauthenticated;
          await DataCache.instance.delete(_cachedUserKey);
          notifyListeners();
        }
      } else {
        debugPrint('[AuthService] revalidateTokenIfNeeded: server error (${e.statusCode}) unrelated to auth — keeping current session');
      }
    } catch (_) {
      // No response — connectivity blipped again already; leave as-is.
    }
  }

  Future<void> _restoreFromCacheOrKeepUnknown() async {
    final cached = await DataCache.instance.get(_cachedUserKey);
    if (cached is Map) {
      currentUser = AppUser.fromJson(cached.cast<String, dynamic>());
      status = AuthStatus.authenticated;
      debugPrint('[AuthService] _restoreFromCacheOrKeepUnknown: hit — restored ${currentUser?.email} from cache');
    } else {
      // Never successfully logged in on this device before — nothing to
      // offer offline, so there's no choice but to send this rep to login.
      status = AuthStatus.unauthenticated;
      debugPrint('[AuthService] _restoreFromCacheOrKeepUnknown: miss — no cached profile on this device');
    }
  }

  Future<void> login(String login, String password) async {
    final payload = await apiClient.post('/auth/token', body: {
      // IssueTokenRequest validates a `login` field, not `email` —
      // TokenService::issue() resolves it against username, email, or
      // phone, whichever it turns out to be. Sending `email` here made
      // `login` always missing, so every attempt failed 422 regardless of
      // the credentials entered.
      'login': login,
      'password': password,
      'name': 'mobile-app',
    });
    final token = (payload['data'] as Map<String, dynamic>)['token'] as String;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    // Unconditional — see _lastLoginEmailKey's doc comment above.
    await prefs.setString(_lastLoginEmailKey, login);
    await prefs.setString(_lastLoginPasswordKey, password);
    apiClient.setToken(token);

    final me = await apiClient.get('/auth/me');
    final data = (me as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    currentUser = AppUser.fromJson(data);
    status = AuthStatus.authenticated;
    // Awaited, not fire-and-forget: this cache is the only thing that makes
    // offline access possible later, so it must be durably written before
    // login() returns — a fire-and-forget write racing against the app
    // being killed moments later could leave it never persisted.
    await DataCache.instance.put(_cachedUserKey, data);
    notifyListeners();
  }

  /// Offline counterpart to [login] — for the Login screen itself, when a
  /// rep types their email/password but there's no connection to actually
  /// hit `/auth/token` (e.g. restoreSession() had nothing to restore this
  /// session, or they're just retrying an attempt that already failed
  /// offline). Since there's no server to check the password against, the
  /// closest safe proxy is: does it match this device's last successful
  /// *online* login (regardless of the "Remember me" toggle — see
  /// _lastLoginEmailKey's doc comment), and is there still a saved token +
  /// cached profile from that login to reuse? Both must hold, so this only
  /// ever succeeds for the same rep who already has a genuine session on
  /// this exact device — it can't be used to newly authenticate as someone
  /// who has never logged in here before, or after an explicit sign-out
  /// (which clears all of this below).
  /// Returns false (never throws) for "no match" — the caller shows one
  /// honest message rather than distinguishing every possible reason.
  Future<bool> loginOffline(String login, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString(_lastLoginEmailKey);
    final lastPassword = prefs.getString(_lastLoginPasswordKey);
    if (lastEmail == null || lastPassword == null) {
      debugPrint('[AuthService] loginOffline: no prior successful login saved on this device — refusing');
      return false;
    }
    final matches = lastEmail.trim().toLowerCase() == login.trim().toLowerCase() && lastPassword == password;
    if (!matches) {
      debugPrint('[AuthService] loginOffline: typed credentials don\'t match the last successful login on this device — refusing');
      return false;
    }

    final token = prefs.getString(_tokenKey);
    final cached = await DataCache.instance.get(_cachedUserKey);
    if (token == null || cached is! Map) {
      debugPrint(
          '[AuthService] loginOffline: credentials matched but nothing to restore (token ${token == null ? 'MISSING' : 'present'}, cached profile ${cached is Map ? 'present' : 'MISSING'}) — likely signed out since that last login, or the token was since rejected by the server');
      return false;
    }

    apiClient.setToken(token);
    currentUser = AppUser.fromJson(cached.cast<String, dynamic>());
    status = AuthStatus.authenticated;
    debugPrint('[AuthService] loginOffline: restored ${currentUser?.email} using saved token');
    notifyListeners();
    return true;
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

  /// Signs out of *this session* only — revokes the token server-side (so
  /// it's truly dead the next time this device is actually online and
  /// checks it) and clears the in-memory/active state, but deliberately
  /// leaves the saved token, cached profile, and last-login credentials on
  /// disk untouched. That's what makes [loginOffline] able to sign this rep
  /// back in with just the correct password and no connection, even right
  /// after tapping sign out — the alternative (wiping everything here) would
  /// mean sign-out permanently requires a fresh online login afterward,
  /// which isn't the behavior wanted for this app. The server-side
  /// revocation still means a real 401 shows up and finishes the cleanup
  /// properly the next time this device verifies the token online.
  Future<void> logout() async {
    try {
      await apiClient.post('/auth/revoke', prefix: 'revoke');
    } catch (_) {
      // Best-effort: still clear local session even if the network call fails.
    }
    apiClient.setToken(null);
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
