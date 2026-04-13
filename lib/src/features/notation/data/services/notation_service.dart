import 'dart:convert';
import 'dart:io';

import '../models/notation_details.dart';
import '../models/notation_list_item.dart';

class NotationService {
  const NotationService();

  static final Uri _apiBaseUri = Uri.parse('http://127.0.0.1:6002');
  static final Uri _listUri = _apiBaseUri.resolve('/v1/notation/list');
  static final Uri _searchUri = _apiBaseUri.resolve('/v1/notation/search');

  Future<List<NotationListItem>> getList(Map<String, String> headers) async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(_listUri);
      _applyHeaders(request, headers);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      _throwIfRequestFailed(
        response.statusCode,
        responseBody,
        defaultMessage: 'Nao foi possivel carregar as anotacoes.',
      );

      final decoded = jsonDecode(responseBody);
      if (decoded is! List) {
        throw const NotationException('Resposta invalida ao listar anotacoes.');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(NotationListItem.fromJson)
          .toList();
    } on SocketException {
      throw const NotationException(
        'Nao foi possivel conectar ao servico de anotacoes.',
      );
    } on FormatException {
      throw const NotationException(
        'Resposta invalida do servico de anotacoes.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<List<NotationListItem>> searchByTitle(
    String titleQuery,
    Map<String, String> headers,
  ) async {
    final client = HttpClient();

    try {
      final trimmed = titleQuery.trim();
      final uri = trimmed.isEmpty
          ? _searchUri
          : _searchUri.replace(queryParameters: {'query': trimmed});
      final request = await client.getUrl(uri);
      _applyHeaders(request, headers);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      _throwIfRequestFailed(
        response.statusCode,
        responseBody,
        defaultMessage: 'Nao foi possivel buscar as anotacoes.',
      );

      final decoded = jsonDecode(responseBody);
      if (decoded is! List) {
        throw const NotationException('Resposta invalida ao buscar anotacoes.');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(NotationListItem.fromJson)
          .toList();
    } on SocketException {
      throw const NotationException(
        'Nao foi possivel conectar ao servico de anotacoes.',
      );
    } on FormatException {
      throw const NotationException(
        'Resposta invalida do servico de anotacoes.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<NotationDetails> getById(
    String notationId,
    Map<String, String> headers,
  ) async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(
        _apiBaseUri.resolve('/v1/notation/$notationId'),
      );
      _applyHeaders(request, headers);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      _throwIfRequestFailed(
        response.statusCode,
        responseBody,
        defaultMessage: 'Nao foi possivel carregar a anotacao.',
      );

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const NotationException(
          'Resposta invalida ao carregar anotacao.',
        );
      }

      return NotationDetails.fromJson(decoded);
    } on SocketException {
      throw const NotationException(
        'Nao foi possivel conectar ao servico de anotacoes.',
      );
    } on FormatException {
      throw const NotationException(
        'Resposta invalida do servico de anotacoes.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<NotationDetails> createNotation({
    required String title,
    required String content,
    required Map<String, String> headers,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.postUrl(_apiBaseUri.resolve('/v1/notation'));
      request.headers.contentType = ContentType.json;
      _applyHeaders(request, headers);
      request.write(jsonEncode({'title': title, 'content': content}));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      _throwIfRequestFailed(
        response.statusCode,
        responseBody,
        defaultMessage: 'Nao foi possivel criar a anotacao.',
      );

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const NotationException('Resposta invalida ao criar anotacao.');
      }

      return NotationDetails.fromJson(decoded);
    } on SocketException {
      throw const NotationException(
        'Nao foi possivel conectar ao servico de anotacoes.',
      );
    } on FormatException {
      throw const NotationException(
        'Resposta invalida do servico de anotacoes.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<NotationDetails> updateNotation({
    required String notationId,
    required String title,
    required String content,
    required Map<String, String> headers,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.putUrl(
        _apiBaseUri.resolve('/v1/notation/$notationId'),
      );
      request.headers.contentType = ContentType.json;
      _applyHeaders(request, headers);
      request.write(jsonEncode({'title': title, 'content': content}));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      _throwIfRequestFailed(
        response.statusCode,
        responseBody,
        defaultMessage: 'Nao foi possivel salvar a anotacao.',
      );

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const NotationException('Resposta invalida ao salvar anotacao.');
      }

      return NotationDetails.fromJson(decoded);
    } on SocketException {
      throw const NotationException(
        'Nao foi possivel conectar ao servico de anotacoes.',
      );
    } on FormatException {
      throw const NotationException(
        'Resposta invalida do servico de anotacoes.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> deleteNotation(
    String notationId,
    Map<String, String> headers,
  ) async {
    final client = HttpClient();

    try {
      final request = await client.deleteUrl(
        _apiBaseUri.resolve('/v1/notation/$notationId'),
      );
      _applyHeaders(request, headers);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      _throwIfRequestFailed(
        response.statusCode,
        responseBody,
        defaultMessage: 'Nao foi possivel excluir a anotacao.',
      );
    } on SocketException {
      throw const NotationException(
        'Nao foi possivel conectar ao servico de anotacoes.',
      );
    } finally {
      client.close(force: true);
    }
  }

  void _applyHeaders(HttpClientRequest request, Map<String, String> headers) {
    headers.forEach(request.headers.set);
  }

  void _throwIfRequestFailed(
    int statusCode,
    String responseBody, {
    required String defaultMessage,
  }) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }

    if (statusCode == HttpStatus.unauthorized) {
      throw const NotationException(
        'Sessao expirada. Faca login novamente.',
        isUnauthorized: true,
      );
    }

    throw NotationException(
      _extractApiErrorMessage(responseBody) ?? defaultMessage,
    );
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

        final msg = decoded['msg'];
        if (msg is String && msg.trim().isNotEmpty) {
          return msg.trim();
        }
      }
    } on FormatException {
      return trimmed;
    }

    return trimmed;
  }
}

class NotationException implements Exception {
  const NotationException(this.message, {this.isUnauthorized = false});

  final String message;
  final bool isUnauthorized;

  @override
  String toString() => message;
}
