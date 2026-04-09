import 'auth_session.dart';

class SessionManager {
  AuthSession? _currentSession;

  AuthSession? get currentSession => _currentSession;
  String? get jwt => _currentSession?.jwt;
  bool get isAuthenticated => _currentSession?.isAuthenticated ?? false;

  Map<String, String> get authorizationHeaders {
    final token = jwt;
    if (token == null || token.isEmpty) {
      return const {};
    }

    return {'Authorization': 'Bearer $token'};
  }

  void setSession(AuthSession session) {
    _currentSession = session;
  }

  void clear() {
    _currentSession = null;
  }
}
