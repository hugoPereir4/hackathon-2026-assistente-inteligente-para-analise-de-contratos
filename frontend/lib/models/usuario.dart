/// Conta autenticada. No backend a própria `Company` é o usuário
/// (GET /api/v1/users/ devolve só a empresa logada).
class Usuario {
  final int id;
  final String email;
  final String cnpj;
  final String? razaoSocial;

  /// `confirmed` no banco: o usuário já revisou os dados vindos da API de CNPJ.
  final bool confirmado;

  const Usuario({
    required this.id,
    required this.email,
    required this.cnpj,
    required this.confirmado,
    this.razaoSocial,
  });

  String get nomeExibicao => razaoSocial ?? email;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      email: json['email'] as String,
      cnpj: json['cnpj'] as String,
      razaoSocial: json['legal_name'] as String?,
      confirmado: json['confirmed'] as bool? ?? false,
    );
  }

  Usuario copyWith({bool? confirmado, String? razaoSocial}) {
    return Usuario(
      id: id,
      email: email,
      cnpj: cnpj,
      confirmado: confirmado ?? this.confirmado,
      razaoSocial: razaoSocial ?? this.razaoSocial,
    );
  }
}
