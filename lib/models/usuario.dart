/// Usuário autenticado. `primeiroAcesso` decide se o fluxo passa
/// pela consulta de CNPJ + confirmação dos dados da empresa.
class Usuario {
  final String email;
  final String cnpj;
  final String token;
  final bool primeiroAcesso;

  const Usuario({
    required this.email,
    required this.cnpj,
    required this.token,
    required this.primeiroAcesso,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      email: json['email'] as String,
      cnpj: json['cnpj'] as String,
      token: json['token'] as String,
      primeiroAcesso: json['primeiro_acesso'] as bool? ?? false,
    );
  }
}
