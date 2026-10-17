import '../../services/auth_service.dart';
import '../../services/empresa_service.dart';

/// Ponto único onde as implementações dos services são escolhidas.
/// Quando a API Django estiver pronta, troque os Mock* pelas versões HTTP aqui.
class AppDependencies {
  AppDependencies._();

  static final AppDependencies instance = AppDependencies._();

  final AuthService authService = MockAuthService();
  final EmpresaService empresaService = MockEmpresaService();
}
