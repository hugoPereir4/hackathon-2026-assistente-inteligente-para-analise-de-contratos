import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import 'app_text.dart';

/// Cabeçalho das telas de autenticação internas (ex.: "Nova conta"):
/// botão circular de voltar + título, e um subtítulo opcional.
class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  const AuthHeader({super.key, required this.title, this.subtitle, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _CircleBackButton(onPressed: onBack ?? () => Navigator.of(context).maybePop()),
            const SizedBox(width: 16),
            Expanded(child: AppText.title(title)),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 16),
          AppText.caption(subtitle!),
        ],
      ],
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CircleBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Voltar',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(AppIcons.back, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}
