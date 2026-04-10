import '../../../../core/session/auth_session.dart';
import '../../../../core/session/session_manager.dart';
import '../dtos/login_request_dto.dart';
import '../dtos/login_response_dto.dart';
import '../dtos/signup_request_dto.dart';
import '../datasources/local/auth_local_data_source.dart';
import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository({
    required AuthService authService,
    required AuthLocalDataSource localDataSource,
    required SessionManager sessionManager,
  }) : _authService = authService,
       _localDataSource = localDataSource,
       _sessionManager = sessionManager;

  final AuthService _authService;
  final AuthLocalDataSource _localDataSource;
  final SessionManager _sessionManager;

  AuthSession? get currentSession => _sessionManager.currentSession;
  String? get jwt => _sessionManager.jwt;
  Map<String, String> get authorizationHeaders =>
      _sessionManager.authorizationHeaders;

  Future<AuthSession?> restoreSession() async {
    final session = await _localDataSource.readSession();
    if (session == null) {
      _sessionManager.clear();
      return null;
    }

    _sessionManager.setSession(session);
    return session;
  }

  Future<LoginResponseDto> login(
    LoginRequestDto input, {
    required bool persistSession,
  }) async {
    final response = await _authService.login(input);
    final session = AuthSession(userName: response.userName, jwt: response.jwt);

    await _localDataSource.saveSession(session, persistSession: persistSession);

    _sessionManager.setSession(session);
    return response;
  }

  Future<void> logout() async {
    try {
      await _authService.logout(_sessionManager.jwt);
    } finally {
      await _localDataSource.clearSession();
      _sessionManager.clear();
    }
  }

  Future<void> signUp(SignUpRequestDto input) {
    return _authService.signUp(input);
  }
}
