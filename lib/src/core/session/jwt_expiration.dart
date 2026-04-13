import 'dart:convert';

class JwtExpiration {
  const JwtExpiration._();

  static bool isExpiredOrInvalid(
    String token, {
    Duration clockSkew = const Duration(seconds: 30),
  }) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return true;
    }

    final parts = trimmed.split('.');
    if (parts.length != 3) {
      return true;
    }

    final payloadJson = _decodeBase64Url(parts[1]);
    if (payloadJson == null) {
      return true;
    }

    try {
      final payload = jsonDecode(payloadJson);
      if (payload is! Map<String, dynamic>) {
        return true;
      }

      final exp = payload['exp'];
      final expiryInSeconds = _parseExp(exp);
      if (expiryInSeconds == null) {
        return true;
      }

      final expiryAt = DateTime.fromMillisecondsSinceEpoch(
        expiryInSeconds * 1000,
        isUtc: true,
      );
      final now = DateTime.now().toUtc().add(clockSkew);
      return !now.isBefore(expiryAt);
    } on FormatException {
      return true;
    }
  }

  static int? _parseExp(Object? exp) {
    if (exp is int) {
      return exp;
    }

    if (exp is num) {
      return exp.toInt();
    }

    if (exp is String) {
      return int.tryParse(exp);
    }

    return null;
  }

  static String? _decodeBase64Url(String value) {
    final normalized = base64Url.normalize(value);

    try {
      final bytes = base64Url.decode(normalized);
      return utf8.decode(bytes);
    } on FormatException {
      return null;
    }
  }
}
