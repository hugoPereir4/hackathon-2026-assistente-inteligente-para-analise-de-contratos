import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'adaptive_widget.dart';

/// Estilos compartilhados dos campos no visual Cupertino, para que
/// texto, select e data tenham exatamente a mesma aparência.
abstract final class CupertinoFieldStyle {
  static BoxDecoration box({required bool hasError}) => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: hasError ? AppColors.danger : AppColors.border),
      );

  static Widget label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      );

  static Widget error(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, top: 6),
        child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.danger)),
      );
}

/// "Casca" de campo que não é digitável (select, data): tem a mesma cara
/// de um [AdaptiveTextField], mas abre um seletor ao ser tocado.
class AdaptiveFieldShell extends AdaptiveWidget {
  final String label;
  final String? value;
  final String? placeholder;
  final String? errorText;
  final IconData? suffixIcon;
  final VoidCallback? onTap;

  const AdaptiveFieldShell({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.placeholder,
    this.errorText,
    this.suffixIcon,
  });

  bool get _isEmpty => value == null || value!.isEmpty;

  @override
  Widget buildMaterial(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InputDecorator(
        isEmpty: _isEmpty,
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          errorText: errorText,
          suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
        ),
        child: Text(value ?? '', style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget buildCupertino(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoFieldStyle.label(label),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: CupertinoFieldStyle.box(hasError: errorText != null),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isEmpty ? (placeholder ?? '') : value!,
                    style: TextStyle(
                      fontSize: 17,
                      color: _isEmpty ? CupertinoColors.placeholderText : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (suffixIcon != null)
                  Icon(suffixIcon, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
        if (errorText != null) CupertinoFieldStyle.error(errorText!),
      ],
    );
  }
}
