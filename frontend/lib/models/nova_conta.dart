import 'empresa.dart';

/// Dados do cadastro. A senha vai em texto e o backend gera o
/// `password_hash`. `id`, `created_at` e `confirmed` são do backend.
class NovaConta {
  final String email;
  final String senha;
  final Empresa empresa;

  const NovaConta({required this.email, required this.senha, required this.empresa});

  /// Corpo de POST /auth/register/. O RegisterSerializer só aceita estes
  /// campos; o resto do perfil vai depois num PATCH /users/{id}/.
  Map<String, dynamic> toRegisterJson() => {
        'email': email,
        'password': senha,
        'cnpj': empresa.cnpj,
        'legal_name': empresa.razaoSocial,
      };
}
