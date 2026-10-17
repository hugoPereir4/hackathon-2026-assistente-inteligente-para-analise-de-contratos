import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';
import 'adaptive_field_shell.dart';
import 'adaptive_widget.dart';

/// Campo de data. Material: showDatePicker. Cupertino: CupertinoDatePicker em popup.
class AdaptiveDateField extends AdaptiveWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? placeholder;
  final String? errorText;

  const AdaptiveDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.placeholder = 'dd/mm/aaaa',
    this.errorText,
  });

  DateTime get _first => firstDate ?? DateTime(1900);
  DateTime get _last => lastDate ?? DateTime.now();
  DateTime get _inicial {
    final base = value ?? _last;
    return base.isAfter(_last) ? _last : (base.isBefore(_first) ? _first : base);
  }

  AdaptiveFieldShell _shell(VoidCallback onTap) => AdaptiveFieldShell(
        label: label,
        value: Formatters.data(value),
        placeholder: placeholder,
        errorText: errorText,
        suffixIcon: AppIcons.calendar,
        onTap: onTap,
      );

  @override
  Widget buildMaterial(BuildContext context) => _shell(() => _abrirMaterial(context));

  @override
  Widget buildCupertino(BuildContext context) => _shell(() => _abrirCupertino(context));

  Future<void> _abrirMaterial(BuildContext context) async {
    final data = await showDatePicker(
      context: context,
      initialDate: _inicial,
      firstDate: _first,
      lastDate: _last,
    );
    if (data != null) onChanged(data);
  }

  Future<void> _abrirCupertino(BuildContext context) async {
    var selecionada = _inicial;
    final confirmou = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoPopupSurface(
        child: SizedBox(
          height: 300,
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
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _inicial,
                  minimumDate: _first,
                  maximumDate: _last,
                  onDateTimeChanged: (d) => selecionada = d,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmou == true) onChanged(selecionada);
  }
}
