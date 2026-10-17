import '../../core/network/api_exception.dart';
import '../../models/empresa.dart';
import '../../models/porte_empresa.dart';
import '../../models/usuario.dart';
import '../empresa_service.dart';
import 'mock_database.dart';

class MockEmpresaService implements EmpresaService {
  final MockDatabase _db;

  MockEmpresaService([MockDatabase? db]) : _db = db ?? MockDatabase.instance;

  Map<String, dynamic> get _logada {
    final company = _db.companies[_db.logadoId];
    if (company == null) {
      throw const ApiException('Sua sessão expirou. Entre novamente.', statusCode: 401);
    }
    return company;
  }

  @override
  Future<Empresa> buscarPerfil() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return Empresa.fromJson(_logada);
  }

  @override
  Future<Empresa> consultarCnpj(String cnpj) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return Empresa(
      cnpj: cnpj,
      razaoSocial: 'Empresa Exemplo Tecnologia LTDA',
      cnae: '6201-5/01 - Desenvolvimento de software sob encomenda',
      porte: PorteEmpresa.me,
      dataFundacao: DateTime(2018, 3, 12),
      cidade: 'Teresópolis',
      uf: 'RJ',
    );
  }

  @override
  Future<Usuario> salvarPerfil(Usuario usuario, Empresa empresa) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final company = _logada
      ..addAll(empresa.toPerfilJson())
      ..['confirmed'] = true;
    return Usuario.fromJson(company);
  }
}
