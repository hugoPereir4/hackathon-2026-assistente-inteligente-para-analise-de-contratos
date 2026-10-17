import '../models/empresa.dart';
import '../models/usuario.dart';

/// Contrato do perfil da empresa ("Cofre do Perfil").
abstract class EmpresaService {
  /// Perfil salvo da empresa logada.
  Future<Empresa> buscarPerfil();

  /// Dados públicos do CNPJ para adiantar o preenchimento.
  Future<Empresa> consultarCnpj(String cnpj);

  /// Salva o perfil e marca os dados como confirmados.
  Future<Usuario> salvarPerfil(Usuario usuario, Empresa empresa);
}
