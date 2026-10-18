import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';

/// Logo em texto do app: "Contrat" + "AI" em destaque.
/// Quando o logo existir, troque o conteúdo deste widget por um Image.asset.
class AppLogo extends StatelessWidget {
  static const String nome = 'Contrat';
  static const String sufixo = 'AI';

  final double fontSize;

  const AppLogo({super.key, this.fontSize = 44});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
      height: 1,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: nome, style: base.copyWith(color: AppColors.primary)),
          TextSpan(text: sufixo, style: base.copyWith(color: AppColors.primaryLight)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
