class LoginResponseDto {
  const LoginResponseDto({
    required this.userName,
    required this.jwt,
  });

  final String userName;
  final String jwt;

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      userName: (json['name'] ?? json['nome'] ?? json['userName'] ?? '')
          .toString(),
      jwt: (json['jwt'] ?? json['token'] ?? '').toString(),
    );
  }
}
