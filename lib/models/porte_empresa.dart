/// Porte da empresa (coluna `company_size`).
enum PorteEmpresa {
  mei('MEI', 'Microempreendedor Individual (MEI)'),
  me('ME', 'Microempresa (ME)'),
  epp('EPP', 'Empresa de Pequeno Porte (EPP)'),
  demais('DEMAIS', 'Médio ou Grande Porte');

  final String codigo;
  final String descricao;

  const PorteEmpresa(this.codigo, this.descricao);

  static PorteEmpresa? fromCodigo(String? codigo) {
    for (final p in values) {
      if (p.codigo == codigo) return p;
    }
    return null;
  }
}
