import '../../models/empresa.dart';
import '../../models/porte_empresa.dart';
import '../empresa_service.dart';

class MockEmpresaService implements EmpresaService {
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
}
