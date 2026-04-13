import 'auth_session.dart';

class SessionManager {
  AuthSession? _currentSession;

  AuthSession? get currentSession => _currentSession;
  String? get jwt => _currentSession?.jwt;
  String? get refreshToken => _currentSession?.refreshToken;
  bool get isAuthenticated => _currentSession?.isAuthenticated ?? false;

  Map<String, String> get authorizationHeaders {
    final token = jwt;
    if (token == null || token.isEmpty) {
      return const {};
    }

    final trimmed = token.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return {'Authorization': trimmed};
    }

    return {'Authorization': 'Bearer $trimmed'};
  }

  void setSession(AuthSession session) {
    _currentSession = session;
  }

  void clear() {
    _currentSession = null;
  }
}
