import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'adaptive_loading.dart';
import 'adaptive_widget.dart';

enum AdaptiveButtonVariant { primary, secondary }

/// Botão principal do app. Mostra um loading no lugar do texto
/// quando [isLoading] é true e fica desabilitado nesse estado.
class AdaptiveButton extends AdaptiveWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AdaptiveButtonVariant variant;
  final IconData? icon;

  const AdaptiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AdaptiveButtonVariant.primary,
    this.icon,
  });

  const AdaptiveButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : variant = AdaptiveButtonVariant.secondary;

  bool get _isPrimary => variant == AdaptiveButtonVariant.primary;

  VoidCallback? get _callback => isLoading ? null : onPressed;

  Widget _content(Color color) {
    if (isLoading) return AdaptiveLoading(size: 20, color: color);
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
    );
  }

  @override
  Widget buildMaterial(BuildContext context) {
    return _isPrimary
        ? FilledButton(onPressed: _callback, child: _content(Colors.white))
        : OutlinedButton(onPressed: _callback, child: _content(AppColors.primary));
  }

  @override
  Widget buildCupertino(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.buttonRadius);
    if (_isPrimary) {
      return SizedBox(
        width: double.infinity,
        height: AppTheme.buttonHeight,
        child: CupertinoButton.filled(
          onPressed: _callback,
          borderRadius: radius,
          child: _content(CupertinoColors.white),
        ),
      );
    }
    return Container(
      width: double.infinity,
      height: AppTheme.buttonHeight,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AppColors.primary),
      ),
      child: CupertinoButton(
        onPressed: _callback,
        borderRadius: radius,
        child: _content(AppColors.primary),
      ),
    );
  }
}
