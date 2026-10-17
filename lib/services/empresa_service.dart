import '../models/empresa.dart';
import '../models/porte_empresa.dart';

/// Contrato para buscar e salvar o perfil da empresa.
abstract class EmpresaService {
  /// Consulta a API pública de CNPJ (via backend).
  Future<Empresa> consultarCnpj(String cnpj);

  /// Salva o perfil confirmado no "Cofre do Perfil da Empresa".
  Future<void> salvarPerfil(Empresa empresa);
}

class MockEmpresaService implements EmpresaService {
  Empresa? _perfilSalvo;

  Empresa? get perfilSalvo => _perfilSalvo;

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
  Future<void> salvarPerfil(Empresa empresa) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _perfilSalvo = empresa;
  }
}
