class AuthSession {
  const AuthSession({
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

  bool get isAuthenticated => jwt.isNotEmpty;

  AuthSession copyWith({
    String? userName,
    String? email,
    bool? darkMode,
    String? jwt,
    String? refreshToken,
  }) {
    return AuthSession(
      userName: userName ?? this.userName,
      email: email ?? this.email,
      darkMode: darkMode ?? this.darkMode,
      jwt: jwt ?? this.jwt,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}
