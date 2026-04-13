import 'dart:convert';
import 'dart:io';

import '../dtos/login_request_dto.dart';
import '../dtos/login_response_dto.dart';
import '../dtos/signup_request_dto.dart';

class AuthService {
  const AuthService();

  static final Uri _apiBaseUri = Uri.parse('http://127.0.0.1:6002');
  static final Uri _loginUri = _apiBaseUri.resolve('/v1/user/login');
  static final Uri _refreshUri = _apiBaseUri.resolve('/v1/user/refresh');
  static final Uri _signUpUri = _apiBaseUri.resolve('/v1/user/create');
  static final Uri _logoutUri = _apiBaseUri.resolve('/v1/user/logout');
  static final Uri _themePreferenceUri = _apiBaseUri.resolve(
    '/v1/user/preferences/theme',
  );

  Future<LoginResponseDto> login(LoginRequestDto input) async {
    final client = HttpClient();

    try {
      final request = await client.postUrl(_loginUri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(input.toJson()));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(
          message:
              _extractApiErrorMessage(responseBody) ??
              'Usuario ou senha incorretos.',
          isInvalidCredentials: true,
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const AuthException(message: 'Resposta de login invalida.');
      }

      final output = LoginResponseDto.fromJson(decoded);
      if (output.userName.isEmpty ||
          output.jwt.isEmpty ||
          output.refreshToken.isEmpty) {
        throw const AuthException(
          message: 'A API nao retornou nome do usuario e tokens validos.',
        );
      }

      return output;
    } on SocketException {
      throw const AuthException(
        message: 'Usuario ou senha incorretos.',
        isInvalidCredentials: true,
      );
    } on FormatException {
      throw const AuthException(
        message: 'Usuario ou senha incorretos.',
        isInvalidCredentials: true,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<LoginResponseDto> refresh(String refreshToken) async {
    final sanitized = refreshToken.trim();
    if (sanitized.isEmpty) {
      throw const AuthException(
        message: 'Sessao expirada. Faca login novamente.',
        isUnauthorized: true,
      );
    }

    final client = HttpClient();

    try {
      final request = await client.postUrl(_refreshUri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'refreshToken': sanitized}));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == HttpStatus.unauthorized) {
          throw const AuthException(
            message: 'Sessao expirada. Faca login novamente.',
            isUnauthorized: true,
          );
        }

        throw AuthException(
          message:
              _extractApiErrorMessage(responseBody) ??
              'Nao foi possivel renovar a sessao.',
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const AuthException(message: 'Resposta de refresh invalida.');
      }

      final output = LoginResponseDto.fromJson(decoded);
      if (output.jwt.isEmpty || output.refreshToken.isEmpty) {
        throw const AuthException(
          message: 'A API nao retornou tokens validos para renovar a sessao.',
        );
      }

      return output;
    } on SocketException {
      throw const AuthException(
        message: 'Nao foi possivel conectar ao servico para renovar a sessao.',
      );
    } on FormatException {
      throw const AuthException(
        message: 'Resposta invalida do servico para renovar a sessao.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> signUp(SignUpRequestDto input) async {
    final client = HttpClient();

    try {
      final request = await client.postUrl(_signUpUri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(input.toJson()));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok) {
        throw AuthException(
          message:
              _extractApiErrorMessage(responseBody) ??
              'Nao foi possivel concluir o cadastro.',
        );
      }
    } on SocketException {
      throw const AuthException(
        message: 'Nao foi possivel conectar ao servico de cadastro.',
      );
    } on FormatException {
      throw const AuthException(
        message: 'Resposta invalida do servico de cadastro.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> logout(String? jwt) async {
    if (jwt == null || jwt.isEmpty) {
      return;
    }

    final client = HttpClient();

    try {
      final request = await client.postUrl(_logoutUri);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, _asBearer(jwt));

      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(
          message: 'Falha ao finalizar a sessao.',
          isUnauthorized: response.statusCode == HttpStatus.unauthorized,
        );
      }
    } on SocketException {
      throw const AuthException(message: 'Falha ao finalizar a sessao.');
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> updateThemePreference({
    required String jwt,
    required bool darkMode,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.putUrl(_themePreferenceUri);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, _asBearer(jwt));
      request.write(jsonEncode({'darkMode': darkMode}));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == HttpStatus.unauthorized) {
          throw const AuthException(
            message: 'Sessao expirada. Faca login novamente.',
            isUnauthorized: true,
          );
        }

        throw AuthException(
          message:
              _extractApiErrorMessage(responseBody) ??
              'Nao foi possivel atualizar o tema.',
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const AuthException(
          message: 'Resposta invalida ao atualizar o tema.',
        );
      }

      return decoded['darkMode'] == true || decoded['DarkMode'] == true;
    } on SocketException {
      throw const AuthException(
        message: 'Nao foi possivel conectar ao servico para atualizar o tema.',
      );
    } on FormatException {
      throw const AuthException(
        message: 'Resposta invalida ao atualizar o tema.',
      );
    } finally {
      client.close(force: true);
    }
  }

  String? _extractApiErrorMessage(String responseBody) {
    final trimmed = responseBody.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];
        if (errors is Map<String, dynamic>) {
          for (final value in errors.values) {
            if (value is List && value.isNotEmpty) {
              final firstMessage = value.first;
              if (firstMessage is String && firstMessage.trim().isNotEmpty) {
                return firstMessage.trim();
              }
            }
          }
        }

        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }

        final title = decoded['title'];
        if (title is String && title.trim().isNotEmpty) {
          return title.trim();
        }
      }
    } on FormatException {
      return trimmed;
    }

    return trimmed;
  }

  String _asBearer(String token) {
    final trimmed = token.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed;
    }

    return 'Bearer $trimmed';
  }
}

class AuthException implements Exception {
  const AuthException({
    required this.message,
    this.isInvalidCredentials = false,
    this.isUnauthorized = false,
  });

  final String message;
  final bool isInvalidCredentials;
  final bool isUnauthorized;

  @override
  String toString() => message;
}
