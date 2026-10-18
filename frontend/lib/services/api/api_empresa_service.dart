import '../../core/network/api_client.dart';
import '../../models/empresa.dart';
import '../empresa_service.dart';

/// Perfil da empresa pela API Django.
class ApiEmpresaService implements EmpresaService {
  /// GET /companies/{cnpj}/ — o backend consulta uma API externa de CNPJ.
  /// É pública, porque o cadastro consulta o CNPJ antes de existir login.
  /// O endereço base vem de `API_URL` (veja AppConfig).
  static const String rotaConsultaCnpj = 'companies/';

  final ApiClient _api;

  ApiEmpresaService(this._api);

  @override
  Future<Empresa> consultarCnpj(String cnpj) async {
    final json = await _api.get('$rotaConsultaCnpj$cnpj/', auth: false);
    return Empresa.fromJson({'cnpj': cnpj, ...json as Map<String, dynamic>});
  }
}
