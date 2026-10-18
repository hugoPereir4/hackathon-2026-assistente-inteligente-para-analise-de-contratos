import '../../core/network/api_exception.dart';
import '../../models/nova_conta.dart';
import '../../models/usuario.dart';
import '../auth_service.dart';
import 'mock_database.dart';

/// Autenticação fake com as mesmas regras e mensagens da API Django.
class MockAuthService implements AuthService {
  static const _cnpjDeTeste = '11222333000181';
  static const _credenciaisInvalidas =
      ApiException('Usuário e/ou senha incorreto(s)', statusCode: 401);

  final MockDatabase _db;

  MockAuthService([MockDatabase? db]) : _db = db ?? MockDatabase.instance;

  @override
  Future<Usuario> login({required String identificador, required String senha}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    var company = _db.companyPorLogin(identificador);
    if (company == null) {
      // Facilita os testes de tela: um login desconhecido cria a conta na hora,
      // ainda não confirmada (cai no fluxo de primeiro acesso).
      if (senha.isEmpty) throw _credenciaisInvalidas;
      final isEmail = identificador.contains('@');
      company = _db.criarCompany(
        email: isEmail ? identificador : 'contato@empresa.com.br',
        cnpj: isEmail ? _cnpjDeTeste : identificador,
        senha: senha,
      );
    } else if (_db.senhas[company['id']] != senha) {
      throw _credenciaisInvalidas;
    }

    _db.logadoId = company['id'] as int;
    return Usuario.fromJson(company);
  }

  @override
  Future<Usuario> cadastrar(NovaConta conta) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    final erros = <String, List<String>>{};
    if (_db.companyPorLogin(conta.email) != null) {
      erros['email'] = ['Já existe uma conta com este email.'];
    }
    if (_db.companyPorLogin(conta.empresa.cnpj) != null) {
      erros['cnpj'] = ['Já existe uma conta com este CNPJ.'];
    }
    if (erros.isNotEmpty) {
      throw ApiException(erros.values.first.first, statusCode: 400, fieldErrors: erros);
    }

    final company = _db.criarCompany(
      email: conta.email,
      cnpj: conta.empresa.cnpj,
      senha: conta.senha,
      legalName: conta.empresa.razaoSocial,
    );
    // Igual à versão da API: register com o perfil + PATCH do confirmed.
    company
      ..addAll(conta.empresa.toPerfilJson())
      ..['confirmed'] = true;
    _db.logadoId = company['id'] as int;
    return Usuario.fromJson(company);
  }

  @override
  Future<void> logout() async {
    _db.logadoId = null;
  }
}
