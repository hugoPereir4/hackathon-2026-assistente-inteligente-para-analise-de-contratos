import '../models/empresa.dart';

/// Contrato do perfil da empresa ("Cofre do Perfil").
abstract class EmpresaService {
  /// Dados públicos do CNPJ para adiantar o preenchimento do cadastro.
  Future<Empresa> consultarCnpj(String cnpj);
}
