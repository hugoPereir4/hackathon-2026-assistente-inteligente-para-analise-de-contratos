import '../models/nova_conta.dart';
import '../models/usuario.dart';

/// Contrato de autenticação. Controllers dependem só desta abstração;
/// a implementação (mock ou API) é escolhida em AppDependencies.
///
/// Erros são lançados como `ApiException`.
abstract class AuthService {
  /// [identificador] é o e-mail ou o CNPJ (sem pontuação) da empresa.
  Future<Usuario> login({required String identificador, required String senha});

  /// Cria a conta e já deixa a sessão aberta. E-mail e CNPJ são únicos.
  Future<Usuario> cadastrar(NovaConta conta);

  Future<void> logout();
}
