/// Porte da empresa (coluna `company_size`).
enum PorteEmpresa {
  mei('MEI', 'Microempreendedor Individual (MEI)'),
  me('ME', 'Microempresa (ME)'),
  epp('EPP', 'Empresa de Pequeno Porte (EPP)'),
  demais('DEMAIS', 'Médio ou Grande Porte');

  final String codigo;
  final String descricao;

  const PorteEmpresa(this.codigo, this.descricao);

  /// Aceita o código salvo no backend ("ME") e também os textos que a API
  /// externa de CNPJ devolve ("MICRO EMPRESA", "EMPRESA DE PEQUENO PORTE"...).
  static PorteEmpresa? fromCodigo(String? codigo) {
    if (codigo == null) return null;
    final texto = codigo.trim().toUpperCase();
    for (final p in values) {
      if (p.codigo == texto) return p;
    }
    return _porDescricaoExterna[texto.replaceAll(RegExp(r'[^A-Z0-9]'), '')];
  }

  /// Chaves sem espaços nem pontuação.
  static const _porDescricaoExterna = {
    'MICROEMPREENDEDORINDIVIDUAL': mei,
    'MICROEMPRESA': me,
    '01': me,
    '1': me,
    'EMPRESADEPEQUENOPORTE': epp,
    '03': epp,
    '3': epp,
    'DEMAIS': demais,
    '05': demais,
    '5': demais,
  };
}
