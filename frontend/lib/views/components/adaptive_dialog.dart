import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/platform/app_platform.dart';

/// Diálogos adaptativos: AlertDialog (Material) ou CupertinoAlertDialog (iOS).
abstract final class AdaptiveDialog {
  static Future<void> showMessage(
    BuildContext context, {
    required String title,
    required String message,
    String okLabel = 'OK',
  }) {
    return _show<void>(
      context,
      title: title,
      message: message,
      actions: [_DialogAction(okLabel, () => Navigator.of(context).pop())],
    );
  }

  static Future<bool> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
  }) async {
    final result = await _show<bool>(
      context,
      title: title,
      message: message,
      actions: [
        _DialogAction(cancelLabel, () => Navigator.of(context).pop(false)),
        _DialogAction(confirmLabel, () => Navigator.of(context).pop(true), isDefault: true),
      ],
    );
    return result ?? false;
  }

  static Future<T?> _show<T>(
    BuildContext context, {
    required String title,
    required String message,
    required List<_DialogAction> actions,
  }) {
    if (AppPlatform.instance.useCupertino) {
      return showCupertinoDialog<T>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: actions
              .map((a) => CupertinoDialogAction(
                    onPressed: a.onPressed,
                    isDefaultAction: a.isDefault,
                    child: Text(a.label),
                  ))
              .toList(),
        ),
      );
    }
    return showDialog<T>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: actions
            .map((a) => TextButton(onPressed: a.onPressed, child: Text(a.label)))
            .toList(),
      ),
    );
  }
}

class _DialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isDefault;

  const _DialogAction(this.label, this.onPressed, {this.isDefault = false});
}
