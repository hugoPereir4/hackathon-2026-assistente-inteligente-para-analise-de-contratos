import '../../services/api/api_auth_service.dart';
import '../../services/api/api_documento_service.dart';
import '../../services/api/api_empresa_service.dart';
import '../../services/auth_service.dart';
import '../../services/documento_service.dart';
import '../../services/empresa_service.dart';
import '../../services/mock/mock_auth_service.dart';
import '../../services/mock/mock_documento_service.dart';
import '../../services/mock/mock_empresa_service.dart';
import '../../services/seletor_arquivo_service.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/token_storage.dart';

/// Ponto único onde as implementações dos services são escolhidas.
///
/// Por padrão usa os mocks; com `--dart-define=USE_API=true` usa a API Django
/// (veja [AppConfig]). Telas e controllers não mudam em nenhum dos casos.
class AppDependencies {
  AppDependencies._() {
    if (AppConfig.useApi) {
      final api = ApiClient(tokenStorage: SharedPrefsTokenStorage());
      authService = ApiAuthService(api);
      empresaService = ApiEmpresaService(api);
      documentoService = ApiDocumentoService(api);
    } else {
      authService = MockAuthService();
      empresaService = MockEmpresaService();
      documentoService = MockDocumentoService();
    }
  }

  static final AppDependencies instance = AppDependencies._();

  late final AuthService authService;
  late final EmpresaService empresaService;
  late final DocumentoService documentoService;
  final SeletorArquivoService seletorArquivoService = FilePickerSeletorArquivoService();
}
