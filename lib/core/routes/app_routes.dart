import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../views/screens/confirmar_empresa/confirmar_empresa_view.dart';
import '../../views/screens/dashboard/dashboard_view.dart';
import '../../views/screens/login/login_view.dart';
import '../platform/app_platform.dart';

/// Rotas nomeadas do app.
abstract final class AppRoutes {
  static const String login = '/';
  static const String confirmarEmpresa = '/confirmar-empresa';
  static const String dashboard = '/dashboard';
}

/// Gera as rotas com a transição nativa de cada plataforma
/// (CupertinoPageRoute no iOS, MaterialPageRoute no resto).
class AppRouter {
  const AppRouter();

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Na web, um F5 em /dashboard chega aqui sem argumentos: volta para o login.
    final usuario = settings.arguments is Usuario ? settings.arguments as Usuario : null;

    final Widget page = switch (settings.name) {
      AppRoutes.confirmarEmpresa when usuario != null => ConfirmarEmpresaView(usuario: usuario),
      AppRoutes.dashboard when usuario != null => DashboardView(usuario: usuario),
      _ => const LoginView(),
    };

    if (AppPlatform.instance.useCupertino) {
      return CupertinoPageRoute(builder: (_) => page, settings: settings);
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
