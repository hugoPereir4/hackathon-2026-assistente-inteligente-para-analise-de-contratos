import 'package:flutter/services.dart';

/// Regras de CNPJ: limpeza, formatação e validação dos dígitos verificadores.
abstract final class Cnpj {
  static String digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  static String format(String value) {
    final d = digits(value);
    final buffer = StringBuffer();
    for (var i = 0; i < d.length && i < 14; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('/');
      if (i == 12) buffer.write('-');
      buffer.write(d[i]);
    }
    return buffer.toString();
  }

  static bool isValid(String value) {
    final d = digits(value);
    if (d.length != 14 || RegExp(r'^(\d)\1*$').hasMatch(d)) return false;

    int digito(String base, List<int> pesos) {
      var soma = 0;
      for (var i = 0; i < pesos.length; i++) {
        soma += int.parse(base[i]) * pesos[i];
      }
      final resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    final d1 = digito(d, [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
    final d2 = digito(d, [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
    return d1 == int.parse(d[12]) && d2 == int.parse(d[13]);
  }
}

/// Para o campo "E-mail ou CNPJ": aplica a máscara de CNPJ só enquanto
/// o texto tiver apenas números; ao digitar letra ou "@" vira texto livre.
class EmailOuCnpjInputFormatter extends TextInputFormatter {
  static final RegExp _soCnpj = RegExp(r'^[\d./-]*$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (!_soCnpj.hasMatch(newValue.text)) return newValue;
    return CnpjInputFormatter().formatEditUpdate(oldValue, newValue);
  }
}

/// Máscara 00.000.000/0000-00 aplicada enquanto o usuário digita.
class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final formatted = Cnpj.format(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
