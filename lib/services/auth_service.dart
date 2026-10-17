import '../models/nova_conta.dart';
import '../models/usuario.dart';

/// Contrato de autenticação. A view/controller dependem só desta
/// abstração, então trocar o mock pela API Django não muda as telas.
abstract class AuthService {
  /// [identificador] é o e-mail ou o CNPJ (só dígitos) do usuário.
  Future<Usuario> login({required String identificador, required String senha});

  /// Cria a conta. E-mail e CNPJ são únicos no banco.
  Future<Usuario> cadastrar(NovaConta conta);
}

/// Implementação fake para desenvolver o frontend sem o backend.
class MockAuthService implements AuthService {
  static const String _cnpjMock = '11222333000181';

  final Map<String, NovaConta> _contasPorEmail = {};
  final Map<String, NovaConta> _contasPorCnpj = {};
  final Set<String> _jaAcessaram = {};

  @override
  Future<Usuario> login({required String identificador, required String senha}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final conta = _contasPorEmail[identificador] ?? _contasPorCnpj[identificador];
    if (conta != null) {
      if (conta.senha != senha) throw const AuthException('E-mail/CNPJ ou senha inválidos.');
      return _usuario(conta.email, conta.empresa.cnpj, primeiroAcesso: false);
    }

    // Identificador desconhecido: aceita para facilitar os testes de tela;
    // o primeiro login de cada um é tratado como "primeiro acesso".
    if (senha.length < 6) throw const AuthException('E-mail/CNPJ ou senha inválidos.');
    final isEmail = identificador.contains('@');
    return _usuario(
      isEmail ? identificador : 'contato@empresa.com.br',
      isEmail ? _cnpjMock : identificador,
      primeiroAcesso: _jaAcessaram.add(identificador),
    );
  }

  @override
  Future<Usuario> cadastrar(NovaConta conta) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    if (_contasPorEmail.containsKey(conta.email)) {
      throw const AuthException('Já existe uma conta com este e-mail.');
    }
    if (_contasPorCnpj.containsKey(conta.empresa.cnpj)) {
      throw const AuthException('Já existe uma conta com este CNPJ.');
    }
    _contasPorEmail[conta.email] = conta;
    _contasPorCnpj[conta.empresa.cnpj] = conta;
    // Os dados da empresa já foram revisados no cadastro, então não é primeiro acesso.
    return _usuario(conta.email, conta.empresa.cnpj, primeiroAcesso: false);
  }

  Usuario _usuario(String email, String cnpj, {required bool primeiroAcesso}) =>
      Usuario(email: email, cnpj: cnpj, token: 'mock-token', primeiroAcesso: primeiroAcesso);
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}
