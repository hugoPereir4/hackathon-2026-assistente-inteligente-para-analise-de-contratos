import 'empresa.dart';

/// Dados enviados no cadastro. A senha vai em texto e o backend gera o
/// `password_hash`. `id`, `created_at` e `confirmed` são do backend.
class NovaConta {
  final String email;
  final String senha;
  final Empresa empresa;

  const NovaConta({required this.email, required this.senha, required this.empresa});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': senha,
        ...empresa.toJson(),
      };
}
