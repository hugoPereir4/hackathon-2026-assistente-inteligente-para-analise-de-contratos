import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../models/empresa.dart';
import '../../models/paginated.dart';
import '../../models/usuario.dart';
import '../empresa_service.dart';

/// Perfil da empresa pela API Django (a Company é o próprio usuário).
class ApiEmpresaService implements EmpresaService {
  /// TODO(backend): este endpoint ainda não existe. Precisa ser público,
  /// porque o cadastro consulta o CNPJ antes de existir login.
  static const String rotaConsultaCnpj = 'cnpj/';

  final ApiClient _api;

  ApiEmpresaService(this._api);

  @override
  Future<Empresa> buscarPerfil() async {
    final json = await _api.get('users/') as Map<String, dynamic>;
    final pagina = Paginated.fromJson(json, Empresa.fromJson);
    if (pagina.results.isEmpty) {
      throw const ApiException('Não foi possível carregar o perfil da empresa.');
    }
    return pagina.results.first;
  }

  @override
  Future<Empresa> consultarCnpj(String cnpj) async {
    final json = await _api.get('$rotaConsultaCnpj$cnpj/', auth: false);
    return Empresa.fromJson({'cnpj': cnpj, ...json as Map<String, dynamic>});
  }

  @override
  Future<Usuario> salvarPerfil(Usuario usuario, Empresa empresa) async {
    final json = await _api.patch(
      'users/${usuario.id}/',
      body: {...empresa.toPerfilJson(), 'confirmed': true},
    );
    return Usuario.fromJson(json as Map<String, dynamic>);
  }
}
