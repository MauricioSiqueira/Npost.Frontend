import '../../../../core/session/auth_session.dart';
import '../../../../core/session/jwt_expiration.dart';
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
  String? get refreshToken => _sessionManager.refreshToken;
  Map<String, String> get authorizationHeaders =>
      _sessionManager.authorizationHeaders;

  Future<AuthSession?> restoreSession() async {
    final session = await _localDataSource.readSession();
    if (session == null) {
      _sessionManager.clear();
      return null;
    }

    _sessionManager.setSession(session);

    if (!JwtExpiration.isExpiredOrInvalid(session.jwt)) {
      return session;
    }

    final refreshResult = await _refreshSessionInternal(
      clearSessionOnUnauthorized: true,
    );
    if (refreshResult == _RefreshSessionResult.success) {
      return _sessionManager.currentSession;
    }

    if (refreshResult == _RefreshSessionResult.unauthorized) {
      return null;
    }

    return _sessionManager.currentSession;
  }

  Future<LoginResponseDto> login(
    LoginRequestDto input, {
    required bool persistSession,
  }) async {
    final response = await _authService.login(input);
    final session = _buildSessionFromLoginResponse(
      response,
      fallbackEmail: input.email,
    );

    await _localDataSource.saveSession(session, persistSession: persistSession);

    _sessionManager.setSession(session);
    return response;
  }

  Future<bool> updateThemePreference(bool darkMode) async {
    final canProceed = await ensureValidAccessToken();
    if (!canProceed) {
      throw const AuthException(
        message: 'Sessao expirada. Faca login novamente.',
        isUnauthorized: true,
      );
    }

    final currentSession = _sessionManager.currentSession;
    final jwt = currentSession?.jwt;
    if (currentSession == null || jwt == null || jwt.isEmpty) {
      throw const AuthException(message: 'Sessao invalida.');
    }

    final updatedDarkMode = await _authService.updateThemePreference(
      jwt: jwt,
      darkMode: darkMode,
    );
    final updatedSession = currentSession.copyWith(darkMode: updatedDarkMode);

    await _localDataSource.updateStoredSession(updatedSession);
    _sessionManager.setSession(updatedSession);

    return updatedDarkMode;
  }

  Future<void> logout() async {
    try {
      final canProceed = await ensureValidAccessToken();
      if (canProceed) {
        await _authService.logout(_sessionManager.jwt);
      }
    } finally {
      await _localDataSource.clearSession();
      _sessionManager.clear();
    }
  }

  Future<void> clearSession() async {
    await _localDataSource.clearSession();
    _sessionManager.clear();
  }

  Future<bool> ensureValidAccessToken() async {
    final session = _sessionManager.currentSession;
    if (session == null) {
      return false;
    }

    if (!JwtExpiration.isExpiredOrInvalid(session.jwt)) {
      return true;
    }

    final refreshResult = await _refreshSessionInternal(
      clearSessionOnUnauthorized: true,
    );
    return refreshResult != _RefreshSessionResult.unauthorized;
  }

  Future<bool> tryRefreshSession() async {
    final refreshResult = await _refreshSessionInternal(
      clearSessionOnUnauthorized: true,
    );
    if (refreshResult == _RefreshSessionResult.failed) {
      throw const AuthException(
        message: 'Nao foi possivel renovar a sessao automaticamente.',
      );
    }

    return refreshResult == _RefreshSessionResult.success;
  }

  Future<void> signUp(SignUpRequestDto input) {
    return _authService.signUp(input);
  }

  Future<_RefreshSessionResult> _refreshSessionInternal({
    required bool clearSessionOnUnauthorized,
  }) async {
    final session = _sessionManager.currentSession;
    final refresh = session?.refreshToken.trim() ?? '';
    if (refresh.isEmpty) {
      if (clearSessionOnUnauthorized) {
        await clearSession();
      }

      return _RefreshSessionResult.unauthorized;
    }

    try {
      final response = await _authService.refresh(refresh);
      final updatedSession = _buildSessionFromLoginResponse(
        response,
        previousSession: session,
      );

      await _localDataSource.updateStoredSession(updatedSession);
      _sessionManager.setSession(updatedSession);
      return _RefreshSessionResult.success;
    } on AuthException catch (error) {
      if (error.isUnauthorized) {
        if (clearSessionOnUnauthorized) {
          await clearSession();
        }

        return _RefreshSessionResult.unauthorized;
      }

      return _RefreshSessionResult.failed;
    }
  }

  AuthSession _buildSessionFromLoginResponse(
    LoginResponseDto response, {
    AuthSession? previousSession,
    String? fallbackEmail,
  }) {
    return AuthSession(
      userName: response.userName.isNotEmpty
          ? response.userName
          : (previousSession?.userName ?? ''),
      email: response.email.isNotEmpty
          ? response.email
          : (previousSession?.email ?? fallbackEmail ?? ''),
      darkMode: response.darkMode,
      jwt: response.jwt,
      refreshToken: response.refreshToken,
    );
  }
}

enum _RefreshSessionResult { success, unauthorized, failed }
