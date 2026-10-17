/// Formatação de valores para exibição.
abstract final class Formatters {
  /// dd/MM/aaaa
  static String data(DateTime? data) {
    if (data == null) return '';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(data.day)}/${dois(data.month)}/${data.year}';
  }

  static const List<String> _meses = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  /// "out", "nov"...
  static String mesAbreviado(DateTime data) => _meses[data.month - 1];

  /// dd/MM/aaaa às HH:mm
  static String dataHora(DateTime data) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${Formatters.data(data)} às ${dois(data.hour)}:${dois(data.minute)}';
  }

  /// 2 -> "2%", 2.5 -> "2,5%".
  static String percentual(double valor) {
    final texto = valor == valor.roundToDouble()
        ? valor.toInt().toString()
        : valor.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceAll('.', ',');
    return '$texto%';
  }

  /// R$ 1.234,56 (sem depender do pacote intl).
  static String moeda(double valor, {String moeda = 'BRL'}) {
    final simbolo = switch (moeda) { 'BRL' => r'R$', 'USD' => r'US$', 'EUR' => '€', _ => moeda };
    final negativo = valor < 0;
    final centavos = (valor.abs() * 100).round();
    final inteiro = (centavos ~/ 100).toString();
    final decimais = (centavos % 100).toString().padLeft(2, '0');

    final milhar = StringBuffer();
    for (var i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) milhar.write('.');
      milhar.write(inteiro[i]);
    }
    return '${negativo ? '-' : ''}$simbolo $milhar,$decimais';
  }

  /// Distância até um prazo, contando dias de calendário:
  /// "hoje", "amanhã", "em 9 dias", "venceu ontem", "venceu há 3 dias".
  static String prazoRelativo(DateTime data, {DateTime? agora}) {
    final hoje = agora ?? DateTime.now();
    final dias = DateTime(data.year, data.month, data.day)
        .difference(DateTime(hoje.year, hoje.month, hoje.day))
        .inDays;
    if (dias == 0) return 'hoje';
    if (dias == 1) return 'amanhã';
    if (dias == -1) return 'venceu ontem';
    if (dias < 0) return 'venceu há ${-dias} dias';
    return 'em $dias dias';
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
