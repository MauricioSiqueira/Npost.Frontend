import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../../core/session/auth_session.dart';
import 'web_session_storage.dart';

class AuthLocalDataSource {
  AuthLocalDataSource({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _jwtKey = 'auth.jwt';
  static const _userNameKey = 'auth.user_name';

  final FlutterSecureStorage _secureStorage;
  final WebSessionStorage _webSessionStorage = const WebSessionStorage();

  Future<void> saveSession(
    AuthSession session, {
    required bool persistSession,
  }) async {
    if (persistSession) {
      await _secureStorage.write(key: _jwtKey, value: session.jwt);
      await _secureStorage.write(key: _userNameKey, value: session.userName);
      _webSessionStorage.delete(_jwtKey);
      _webSessionStorage.delete(_userNameKey);
      return;
    }

    await _secureStorage.delete(key: _jwtKey);
    await _secureStorage.delete(key: _userNameKey);
    _webSessionStorage.write(_jwtKey, session.jwt);
    _webSessionStorage.write(_userNameKey, session.userName);
  }

  Future<AuthSession?> readSession() async {
    final sessionJwt = _webSessionStorage.read(_jwtKey);
    final sessionUserName = _webSessionStorage.read(_userNameKey);

    if (sessionJwt != null && sessionJwt.isNotEmpty) {
      return AuthSession(userName: sessionUserName ?? '', jwt: sessionJwt);
    }

    final jwt = await _secureStorage.read(key: _jwtKey);
    final userName = await _secureStorage.read(key: _userNameKey);

    if (jwt == null || jwt.isEmpty) {
      return null;
    }

    return AuthSession(userName: userName ?? '', jwt: jwt);
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(key: _jwtKey);
    await _secureStorage.delete(key: _userNameKey);
    _webSessionStorage.delete(_jwtKey);
    _webSessionStorage.delete(_userNameKey);
  }
}
