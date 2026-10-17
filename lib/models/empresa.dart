import 'porte_empresa.dart';

/// Perfil da empresa ("Cofre do Perfil"). Os nomes do JSON seguem as colunas
/// do banco. Só o CNPJ é obrigatório; o resto pode vir da API pública de CNPJ
/// ou ser preenchido depois.
class Empresa {
  final String cnpj; // cnpj varchar(14), só dígitos
  final String? razaoSocial; // legal_name
  final String? cnae; // cnae_primary
  final PorteEmpresa? porte; // company_size
  final DateTime? dataFundacao; // founded_on
  final String? cidade; // address_city
  final String? uf; // address_state varchar(2)

  const Empresa({
    required this.cnpj,
    this.razaoSocial,
    this.cnae,
    this.porte,
    this.dataFundacao,
    this.cidade,
    this.uf,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      cnpj: json['cnpj'] as String,
      razaoSocial: json['legal_name'] as String?,
      cnae: json['cnae_primary'] as String?,
      porte: PorteEmpresa.fromCodigo(json['company_size'] as String?),
      dataFundacao: DateTime.tryParse(json['founded_on'] as String? ?? ''),
      cidade: json['address_city'] as String?,
      uf: json['address_state'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'cnpj': cnpj,
        'legal_name': razaoSocial,
        'cnae_primary': cnae,
        'company_size': porte?.codigo,
        'founded_on': dataFundacao?.toIso8601String().substring(0, 10),
        'address_city': cidade,
        'address_state': uf,
      };
}
