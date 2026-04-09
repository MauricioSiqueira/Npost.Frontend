import 'dart:convert';
import 'dart:io';

import '../dtos/login_request_dto.dart';
import '../dtos/login_response_dto.dart';

class AuthService {
  const AuthService();

  static final Uri _loginUri = Uri.parse('http://127.0.0.1:6001/v1/login');

  Future<LoginResponseDto> login(LoginRequestDto input) async {
    final client = HttpClient();

    try {
      final request = await client.postUrl(_loginUri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(input.toJson()));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const AuthException(
          message: 'Usuario ou senha incorretos.',
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
