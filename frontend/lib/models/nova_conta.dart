import 'empresa.dart';

/// Dados do cadastro. A senha vai em texto e o backend gera o
/// `password_hash`. `id`, `created_at` e `confirmed` são do backend.
class NovaConta {
  final String email;
  final String senha;
  final Empresa empresa;

  const NovaConta({required this.email, required this.senha, required this.empresa});

  /// Corpo de POST /auth/register/: acesso + dados da empresa vindos da
  /// consulta de CNPJ (campos vazios ficam de fora).
  ///
  /// `confirmed` ainda não é aceito pelo RegisterSerializer (o backend ignora);
  /// vai junto para valer assim que for, sem mudar o app.
  Map<String, dynamic> toRegisterJson() => {
        'email': email,
        'password': senha,
        ...empresa.toJson()..removeWhere((_, valor) => valor == null),
        'confirmed': true,
      };
}
