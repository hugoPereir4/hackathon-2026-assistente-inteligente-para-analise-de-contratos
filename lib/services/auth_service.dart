import '../models/usuario.dart';

/// Contrato de autenticação. A view/controller dependem só desta
/// abstração, então trocar o mock pela API Django não muda as telas.
abstract class AuthService {
  /// [identificador] é o e-mail ou o CNPJ (só dígitos) do usuário.
  Future<Usuario> login({required String identificador, required String senha});
}

/// Implementação fake para desenvolver o frontend sem o backend.
/// O primeiro login de cada identificador é tratado como "primeiro acesso".
class MockAuthService implements AuthService {
  static const String _cnpjMock = '11222333000181';

  final Set<String> _jaAcessaram = {};

  @override
  Future<Usuario> login({required String identificador, required String senha}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (senha.length < 6) {
      throw const AuthException('E-mail/CNPJ ou senha inválidos.');
    }

    final isEmail = identificador.contains('@');
    return Usuario(
      email: isEmail ? identificador : 'contato@empresa.com.br',
      cnpj: isEmail ? _cnpjMock : identificador,
      token: 'mock-token',
      primeiroAcesso: _jaAcessaram.add(identificador),
    );
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}
