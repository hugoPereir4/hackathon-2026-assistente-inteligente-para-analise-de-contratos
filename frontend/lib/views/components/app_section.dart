import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';
import 'app_card.dart';

/// Card com título (e ícone/contador opcionais) para agrupar um bloco de conteúdo.
class AppSection extends StatelessWidget {
  final String title;
  final IconData? icon;

  /// Texto curto à direita do título, ex.: "3 de 4 atendidos".
  final String? trailing;
  final Widget child;

  const AppSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
