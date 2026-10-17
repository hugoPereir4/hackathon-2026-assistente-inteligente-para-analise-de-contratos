import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import 'adaptive_field_shell.dart';
import 'adaptive_widget.dart';

/// Campo de seleção de uma opção.
/// Material: lista em bottom sheet. Cupertino: CupertinoPicker em popup.
class AdaptiveSelect<T> extends AdaptiveWidget {
  final String label;
  final List<T> options;
  final T? value;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final String? placeholder;
  final String? errorText;

  const AdaptiveSelect({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.itemLabel,
    required this.onChanged,
    this.placeholder,
    this.errorText,
  });

  AdaptiveFieldShell _shell(VoidCallback onTap) => AdaptiveFieldShell(
        label: label,
        value: value == null ? null : itemLabel(value as T),
        placeholder: placeholder,
        errorText: errorText,
        suffixIcon: AppIcons.chevronDown,
        onTap: onTap,
      );

  @override
  Widget buildMaterial(BuildContext context) => _shell(() => _abrirMaterial(context));

  @override
  Widget buildCupertino(BuildContext context) => _shell(() => _abrirCupertino(context));

  Future<void> _abrirMaterial(BuildContext context) async {
    final escolhido = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(label, style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final option in options)
              ListTile(
                title: Text(itemLabel(option)),
                trailing: option == value
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
    if (escolhido != null) onChanged(escolhido);
  }

  Future<void> _abrirCupertino(BuildContext context) async {
    var indice = value == null ? 0 : options.indexOf(value as T).clamp(0, options.length - 1);
    final confirmou = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoPopupSurface(
        child: SizedBox(
          height: 280,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancelar'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  CupertinoButton(
                    child: const Text('Concluir'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(initialItem: indice),
                  onSelectedItemChanged: (i) => indice = i,
                  children: [for (final o in options) Center(child: Text(itemLabel(o)))],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmou == true) onChanged(options[indice]);
  }
}
