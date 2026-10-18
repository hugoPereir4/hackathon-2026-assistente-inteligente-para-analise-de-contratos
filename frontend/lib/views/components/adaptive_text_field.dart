import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import 'adaptive_field_shell.dart';
import 'adaptive_widget.dart';

/// Campo de texto com label e mensagem de erro.
/// A validação fica no controller; o campo só exibe o [errorText].
class AdaptiveTextField extends AdaptiveWidget {
  final TextEditingController controller;
  final String label;
  final String? placeholder;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter> inputFormatters;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AdaptiveTextField({
    super.key,
    required this.controller,
    required this.label,
    this.placeholder,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters = const [],
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget buildMaterial(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        errorText: errorText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffix,
      ),
    );
  }

  @override
  Widget buildCupertino(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoFieldStyle.label(label),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          obscureText: obscureText,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          prefix: prefixIcon == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
                ),
          suffix: suffix == null
              ? null
              : Padding(padding: const EdgeInsets.only(right: 12), child: suffix),
          decoration: CupertinoFieldStyle.box(hasError: hasError),
        ),
        if (hasError) CupertinoFieldStyle.error(errorText!),
      ],
    );
  }
}
