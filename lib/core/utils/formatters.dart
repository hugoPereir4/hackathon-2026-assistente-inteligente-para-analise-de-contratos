/// Formatação de valores para exibição.
abstract final class Formatters {
  /// dd/MM/aaaa
  static String data(DateTime? data) {
    if (data == null) return '';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(data.day)}/${dois(data.month)}/${data.year}';
  }

  /// "agora mesmo", "há 5 min", "há 3 h", "ontem", "há 2 dias" ou a data.
  static String tempoRelativo(DateTime data, {DateTime? agora}) {
    final diff = (agora ?? DateTime.now()).difference(data);
    if (diff.inMinutes < 1) return 'agora mesmo';
    if (diff.inHours < 1) return 'há ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'há ${diff.inHours} h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 30) return 'há ${diff.inDays} dias';
    return Formatters.data(data);
  }
}

/// Siglas das 27 unidades federativas (coluna `address_state`, 2 caracteres).
abstract final class Ufs {
  static const List<String> todas = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA',
    'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];
}
