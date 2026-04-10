import 'dart:convert';
import 'dart:io';

import '../dtos/login_request_dto.dart';
import '../dtos/login_response_dto.dart';
import '../dtos/signup_request_dto.dart';

class AuthService {
  const AuthService();

  static final Uri _apiBaseUri = Uri.parse('http://127.0.0.1:6002');
  static final Uri _loginUri = _apiBaseUri.resolve('/v1/user/login');
  static final Uri _signUpUri = _apiBaseUri.resolve('/v1/user/create');

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
      if (output.userName.isEmpty || output.jwt.isEmpty) {
        throw const AuthException(
          message: 'A API nao retornou nome do usuario e JWT validos.',
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
}

class AuthException implements Exception {
  const AuthException({
    required this.message,
    this.isInvalidCredentials = false,
  });

  final String message;
  final bool isInvalidCredentials;

  @override
  String toString() => message;
}
