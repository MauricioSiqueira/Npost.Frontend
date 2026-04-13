class LoginResponseDto {
  const LoginResponseDto({
    required this.userName,
    required this.email,
    required this.darkMode,
    required this.jwt,
    required this.refreshToken,
  });

  final String userName;
  final String email;
  final bool darkMode;
  final String jwt;
  final String refreshToken;

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    final rawToken = (json['jwt'] ?? json['token'] ?? '').toString();
    final rawRefreshToken =
        (json['refreshToken'] ?? json['refresh_token'] ?? '').toString();

    return LoginResponseDto(
      userName: (json['name'] ?? json['nome'] ?? json['userName'] ?? '')
          .toString(),
      email: (json['email'] ?? json['mail'] ?? json['userEmail'] ?? '')
          .toString(),
      darkMode: json['darkMode'] == true || json['DarkMode'] == true,
      jwt: _normalizeToken(rawToken),
      refreshToken: rawRefreshToken.trim(),
    );
  }

  static String _normalizeToken(String token) {
    final trimmed = token.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed.substring(7).trim();
    }

    return trimmed;
  }
}
