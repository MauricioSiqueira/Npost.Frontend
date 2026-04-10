class SignUpRequestDto {
  const SignUpRequestDto({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.birthDate,
    required this.phone,
    required this.password,
    required this.confirmPassword,
  });

  final String firstName;
  final String lastName;
  final String email;
  final DateTime birthDate;
  final String phone;
  final String password;
  final String confirmPassword;

  Map<String, dynamic> toJson() {
    return {
      'nome': firstName,
      'sobrenome': lastName,
      'email': email,
      'dataDeNascimento': birthDate.toIso8601String(),
      'celular': phone,
      'senha': password,
      'confirmacaoSenha': confirmPassword,
    };
  }
}
