import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../../core/session/auth_session.dart';

class AuthLocalDataSource {
  AuthLocalDataSource({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _jwtKey = 'auth.jwt';
  static const _userNameKey = 'auth.user_name';

  final FlutterSecureStorage _secureStorage;

  Future<void> saveSession(AuthSession session) async {
    await _secureStorage.write(key: _jwtKey, value: session.jwt);
    await _secureStorage.write(key: _userNameKey, value: session.userName);
  }

  Future<AuthSession?> readSession() async {
    final jwt = await _secureStorage.read(key: _jwtKey);
    final userName = await _secureStorage.read(key: _userNameKey);

    if (jwt == null || jwt.isEmpty) {
      return null;
    }

    return AuthSession(
      userName: userName ?? '',
      jwt: jwt,
    );
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(key: _jwtKey);
    await _secureStorage.delete(key: _userNameKey);
  }
}
