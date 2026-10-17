import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';

/// Tipografia padronizada do app, independente de Material/Cupertino.
class AppText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  const AppText.title(this.text, {super.key, this.textAlign})
      : style = const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        );

  const AppText.subtitle(this.text, {super.key, this.textAlign})
      : style = const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        );

  const AppText.body(this.text, {super.key, this.textAlign})
      : style = const TextStyle(fontSize: 15, color: AppColors.textPrimary);

  const AppText.caption(this.text, {super.key, this.textAlign})
      : style = const TextStyle(fontSize: 13, color: AppColors.textSecondary);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style, textAlign: textAlign);
  }
}
