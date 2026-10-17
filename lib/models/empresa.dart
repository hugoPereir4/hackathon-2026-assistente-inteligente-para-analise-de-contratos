/// Perfil da empresa ("Cofre do Perfil"), preenchido pela API pública de CNPJ.
class Empresa {
  final String cnpj;
  final String razaoSocial;
  final String nomeFantasia;
  final String cnae;
  final String porte;
  final String endereco;
  final DateTime? dataFundacao;

  const Empresa({
    required this.cnpj,
    required this.razaoSocial,
    this.nomeFantasia = '',
    this.cnae = '',
    this.porte = '',
    this.endereco = '',
    this.dataFundacao,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      cnpj: json['cnpj'] as String,
      razaoSocial: json['razao_social'] as String? ?? '',
      nomeFantasia: json['nome_fantasia'] as String? ?? '',
      cnae: json['cnae'] as String? ?? '',
      porte: json['porte'] as String? ?? '',
      endereco: json['endereco'] as String? ?? '',
      dataFundacao: DateTime.tryParse(json['data_fundacao'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'cnpj': cnpj,
        'razao_social': razaoSocial,
        'nome_fantasia': nomeFantasia,
        'cnae': cnae,
        'porte': porte,
        'endereco': endereco,
        'data_fundacao': dataFundacao?.toIso8601String().substring(0, 10),
      };

  Empresa copyWith({
    String? razaoSocial,
    String? nomeFantasia,
    String? cnae,
    String? porte,
    String? endereco,
    DateTime? dataFundacao,
  }) {
    return Empresa(
      cnpj: cnpj,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      nomeFantasia: nomeFantasia ?? this.nomeFantasia,
      cnae: cnae ?? this.cnae,
      porte: porte ?? this.porte,
      endereco: endereco ?? this.endereco,
      dataFundacao: dataFundacao ?? this.dataFundacao,
    );
  }
}
