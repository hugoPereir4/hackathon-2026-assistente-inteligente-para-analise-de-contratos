import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_tokens.dart';
import '../../models/nova_conta.dart';
import '../../models/paginated.dart';
import '../../models/usuario.dart';
import '../auth_service.dart';

/// Autenticação pela API Django (SimpleJWT).
///
///   POST /auth/login/     {login, password}         -> {access, refresh}
///   POST /auth/register/  {email, password, cnpj, legal_name}
///                                                   -> {user, access, refresh}
///   POST /auth/logout/    {refresh}
///   GET  /users/          -> página com a empresa logada
///   PATCH /users/{id}/    -> resto do perfil + confirmed
class ApiAuthService implements AuthService {
  final ApiClient _api;

  ApiAuthService(this._api);

  @override
  Future<Usuario> login({required String identificador, required String senha}) async {
    final json = await _api.post(
      'auth/login/',
      body: {'login': identificador, 'password': senha},
      auth: false,
    );
    await _api.salvarTokens(AuthTokens.fromJson(json as Map<String, dynamic>));
    return _empresaLogada();
  }

  @override
  Future<Usuario> cadastrar(NovaConta conta) async {
    final json = await _api.post('auth/register/', body: conta.toRegisterJson(), auth: false)
        as Map<String, dynamic>;
    await _api.salvarTokens(AuthTokens.fromJson(json));
    final criado = Usuario.fromJson(json['user'] as Map<String, dynamic>);

    // O register não aceita os campos opcionais; eles vão num PATCH.
    // Se o PATCH falhar a conta já existe: devolve sem confirmar, e o
    // usuário completa na tela de confirmação.
    try {
      final atualizado = await _api.patch(
        'users/${criado.id}/',
        body: {...conta.empresa.toPerfilJson(), 'confirmed': true},
      );
      return Usuario.fromJson(atualizado as Map<String, dynamic>);
    } on ApiException {
      return criado;
    }
  }

  @override
  Future<void> logout() async {
    final refresh = (await _api.tokens)?.refresh;
    try {
      if (refresh != null) await _api.post('auth/logout/', body: {'refresh': refresh});
    } on ApiException {
      // O token pode já ter expirado; a sessão local é encerrada de qualquer jeito.
    } finally {
      await _api.limparTokens();
    }
  }

  Future<Usuario> _empresaLogada() async {
    final json = await _api.get('users/') as Map<String, dynamic>;
    final pagina = Paginated.fromJson(json, Usuario.fromJson);
    if (pagina.results.isEmpty) {
      throw const ApiException('Não foi possível carregar os dados da conta.');
    }
    return pagina.results.first;
  }
}
