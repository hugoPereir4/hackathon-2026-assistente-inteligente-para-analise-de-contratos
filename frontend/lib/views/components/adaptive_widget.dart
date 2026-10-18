import 'package:flutter/widgets.dart';

import '../../core/platform/app_platform.dart';

/// Classe base de todos os componentes adaptativos.
///
/// Cada componente implementa as duas versões e esta classe decide,
/// com base no [AppPlatform], qual delas renderizar.
abstract class AdaptiveWidget extends StatelessWidget {
  const AdaptiveWidget({super.key});

  Widget buildMaterial(BuildContext context);

  Widget buildCupertino(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return AppPlatform.instance.useCupertino
        ? buildCupertino(context)
        : buildMaterial(context);
  }
}
