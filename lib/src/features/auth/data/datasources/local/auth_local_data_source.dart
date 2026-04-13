import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../../core/session/auth_session.dart';
import 'web_session_storage.dart';

class AuthLocalDataSource {
  AuthLocalDataSource({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _jwtKey = 'auth.jwt';
  static const _refreshTokenKey = 'auth.refresh_token';
  static const _userNameKey = 'auth.user_name';
  static const _emailKey = 'auth.email';
  static const _darkModeKey = 'auth.dark_mode';

  final FlutterSecureStorage _secureStorage;
  final WebSessionStorage _webSessionStorage = const WebSessionStorage();

  Future<void> saveSession(
    AuthSession session, {
    required bool persistSession,
  }) async {
    if (persistSession) {
      await _secureStorage.write(key: _jwtKey, value: session.jwt);
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: session.refreshToken,
      );
      await _secureStorage.write(key: _userNameKey, value: session.userName);
      await _secureStorage.write(key: _emailKey, value: session.email);
      await _secureStorage.write(
        key: _darkModeKey,
        value: session.darkMode.toString(),
      );
      _webSessionStorage.delete(_jwtKey);
      _webSessionStorage.delete(_refreshTokenKey);
      _webSessionStorage.delete(_userNameKey);
      _webSessionStorage.delete(_emailKey);
      _webSessionStorage.delete(_darkModeKey);
      return;
    }

    await _secureStorage.delete(key: _jwtKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userNameKey);
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _darkModeKey);
    _webSessionStorage.write(_jwtKey, session.jwt);
    _webSessionStorage.write(_refreshTokenKey, session.refreshToken);
    _webSessionStorage.write(_userNameKey, session.userName);
    _webSessionStorage.write(_emailKey, session.email);
    _webSessionStorage.write(_darkModeKey, session.darkMode.toString());
  }

  Future<AuthSession?> readSession() async {
    final sessionJwt = _webSessionStorage.read(_jwtKey);
    final sessionRefreshToken = _webSessionStorage.read(_refreshTokenKey);
    final sessionUserName = _webSessionStorage.read(_userNameKey);
    final sessionEmail = _webSessionStorage.read(_emailKey);
    final sessionDarkMode = _webSessionStorage.read(_darkModeKey);

    if (sessionJwt != null && sessionJwt.isNotEmpty) {
      return AuthSession(
        userName: sessionUserName ?? '',
        email: sessionEmail ?? '',
        darkMode: sessionDarkMode == 'true',
        jwt: sessionJwt,
        refreshToken: sessionRefreshToken ?? '',
      );
    }

    final jwt = await _secureStorage.read(key: _jwtKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    final userName = await _secureStorage.read(key: _userNameKey);
    final email = await _secureStorage.read(key: _emailKey);
    final darkMode = await _secureStorage.read(key: _darkModeKey);

    if (jwt == null || jwt.isEmpty) {
      return null;
    }

    return AuthSession(
      userName: userName ?? '',
      email: email ?? '',
      darkMode: darkMode == 'true',
      jwt: jwt,
      refreshToken: refreshToken ?? '',
    );
  }

  Future<void> updateStoredSession(AuthSession session) async {
    final hasWebSession = (_webSessionStorage.read(_jwtKey) ?? '')
        .trim()
        .isNotEmpty;

    if (hasWebSession) {
      _webSessionStorage.write(_jwtKey, session.jwt);
      _webSessionStorage.write(_refreshTokenKey, session.refreshToken);
      _webSessionStorage.write(_userNameKey, session.userName);
      _webSessionStorage.write(_emailKey, session.email);
      _webSessionStorage.write(_darkModeKey, session.darkMode.toString());
      return;
    }

    await _secureStorage.write(key: _jwtKey, value: session.jwt);
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: session.refreshToken,
    );
    await _secureStorage.write(key: _userNameKey, value: session.userName);
    await _secureStorage.write(key: _emailKey, value: session.email);
    await _secureStorage.write(
      key: _darkModeKey,
      value: session.darkMode.toString(),
    );
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(key: _jwtKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userNameKey);
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _darkModeKey);
    _webSessionStorage.delete(_jwtKey);
    _webSessionStorage.delete(_refreshTokenKey);
    _webSessionStorage.delete(_userNameKey);
    _webSessionStorage.delete(_emailKey);
    _webSessionStorage.delete(_darkModeKey);
  }
}
