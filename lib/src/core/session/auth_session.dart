class AuthSession {
  const AuthSession({
    required this.userName,
    required this.jwt,
  });

  final String userName;
  final String jwt;

  bool get isAuthenticated => jwt.isNotEmpty;
}
