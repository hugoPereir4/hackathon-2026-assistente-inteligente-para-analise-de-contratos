import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/analise_resumo.dart';
import '../../models/usuario.dart';
import '../../views/screens/cadastro/cadastro_view.dart';
import '../../views/screens/dashboard/dashboard_view.dart';
import '../../views/screens/login/login_view.dart';
import '../../views/screens/resultado/resultado_view.dart';
import '../platform/app_platform.dart';

/// Rotas nomeadas do app.
abstract final class AppRoutes {
  static const String login = '/';
  static const String cadastro = '/cadastro';
  static const String dashboard = '/dashboard';
  static const String resultado = '/resultado';
}

/// Gera as rotas com a transição nativa de cada plataforma
/// (CupertinoPageRoute no iOS, MaterialPageRoute no resto).
class AppRouter {
  const AppRouter();

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Na web, um F5 em /dashboard chega aqui sem argumentos: volta para o login.
    final args = settings.arguments;
    final usuario = args is Usuario ? args : null;
    final analise = args is AnaliseResumo ? args : null;

    final Widget page = switch (settings.name) {
      AppRoutes.cadastro => const CadastroView(),
      AppRoutes.dashboard when usuario != null => DashboardView(usuario: usuario),
      AppRoutes.resultado when analise != null => ResultadoView(analise: analise),
      _ => const LoginView(),
    };

    if (AppPlatform.instance.useCupertino) {
      return CupertinoPageRoute(builder: (_) => page, settings: settings);
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
