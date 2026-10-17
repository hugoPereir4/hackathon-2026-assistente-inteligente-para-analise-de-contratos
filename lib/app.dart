import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'core/platform/app_platform.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

/// Raiz do app: monta um CupertinoApp no iOS e um MaterialApp na web e no Android.
class App extends StatelessWidget {
  static const String title = 'Análise de Contratos';
  static const AppRouter _router = AppRouter();

  const App({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.instance.useCupertino) {
      return CupertinoApp(
        title: title,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.cupertino,
        initialRoute: AppRoutes.login,
        onGenerateRoute: _router.onGenerateRoute,
      );
    }

    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.material,
      initialRoute: AppRoutes.login,
      onGenerateRoute: _router.onGenerateRoute,
    );
  }
}
