/// Formatação de valores para exibição.
abstract final class Formatters {
  /// dd/MM/aaaa
  static String data(DateTime? data) {
    if (data == null) return '';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(data.day)}/${dois(data.month)}/${data.year}';
  }
}

/// Siglas das 27 unidades federativas (coluna `address_state`, 2 caracteres).
abstract final class Ufs {
  static const List<String> todas = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA',
    'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];
}
