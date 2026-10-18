import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/platform/app_platform.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

/// Raiz do app: monta um CupertinoApp no iOS e um MaterialApp na web e no Android.
///
/// Sem `initialRoute`: na web a rota inicial vem da URL (ex.: /#/cadastro);
/// no mobile é sempre '/', que o [AppRouter] resolve para o login.
class App extends StatelessWidget {
  static const String title = 'Análise de Contratos';
  static const AppRouter _router = AppRouter();
  static const Locale _locale = Locale('pt', 'BR');
  static const List<LocalizationsDelegate<dynamic>> _localizations = [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  const App({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.instance.useCupertino) {
      return CupertinoApp(
        title: title,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.cupertino,
        locale: _locale,
        supportedLocales: const [_locale],
        localizationsDelegates: _localizations,
        onGenerateRoute: _router.onGenerateRoute,
      );
    }

    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.material,
      locale: _locale,
      supportedLocales: const [_locale],
      localizationsDelegates: _localizations,
      onGenerateRoute: _router.onGenerateRoute,
    );
  }
}
