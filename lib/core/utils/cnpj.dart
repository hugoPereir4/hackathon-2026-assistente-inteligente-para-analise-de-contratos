import 'package:flutter/services.dart';

/// Regras de CNPJ, iguais às de `core/modules/company/validators.py`:
/// aceita o formato numérico e o alfanumérico (12 caracteres [0-9A-Z]
/// + 2 dígitos verificadores numéricos).
abstract final class Cnpj {
  static final RegExp _pontuacao = RegExp(r'[.\-/\s]');
  static final RegExp _formato = RegExp(r'^[0-9A-Z]{12}[0-9]{2}$');
  static final RegExp _naoAlfanumerico = RegExp(r'[^0-9A-Z]');
  static const List<int> _pesos = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  /// Sem pontuação e em maiúsculas: o formato salvo no banco.
  static String normalize(String value) => value.replaceAll(_pontuacao, '').toUpperCase();

  static String format(String value) {
    final c = value.toUpperCase().replaceAll(_naoAlfanumerico, '');
    final buffer = StringBuffer();
    for (var i = 0; i < c.length && i < 14; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('/');
      if (i == 12) buffer.write('-');
      buffer.write(c[i]);
    }
    return buffer.toString();
  }

  static bool isValid(String value) {
    final c = normalize(value);
    if (!_formato.hasMatch(c) || c.split('').toSet().length == 1) return false;

    final primeiro = _digito(c.substring(0, 12));
    final segundo = _digito('${c.substring(0, 12)}$primeiro');
    return c.substring(12) == '$primeiro$segundo';
  }

  /// Valor de cada caractere = código ASCII - 48 (vale para dígitos e letras).
  static int _digito(String base) {
    final pesos = _pesos.sublist(_pesos.length - base.length);
    var soma = 0;
    for (var i = 0; i < base.length; i++) {
      soma += (base.codeUnitAt(i) - 48) * pesos[i];
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }
}

/// Para o campo "E-mail ou CNPJ": aplica a máscara de CNPJ só enquanto
/// o texto tiver apenas números; com letras ou "@" vira texto livre
/// (assim dá para digitar e-mail, e o CNPJ alfanumérico também é aceito).
class EmailOuCnpjInputFormatter extends TextInputFormatter {
  static final RegExp _soNumeros = RegExp(r'^[\d./-]*$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (!_soNumeros.hasMatch(newValue.text)) return newValue;
    return CnpjInputFormatter().formatEditUpdate(oldValue, newValue);
  }
}

/// Máscara AA.AAA.AAA/AAAA-00 aplicada enquanto o usuário digita
/// (letras viram maiúsculas).
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
