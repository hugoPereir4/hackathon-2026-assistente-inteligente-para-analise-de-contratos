import 'mock_analises.dart';

/// "Banco" em memória compartilhado pelos services mock.
///
/// Guarda os dados no mesmo formato JSON que a API Django devolve, para que
/// os mocks passem pelos mesmos `fromJson` que as implementações reais.
class MockDatabase {
  MockDatabase._();

  static final MockDatabase instance = MockDatabase._();

  /// Companies no formato do CompanyDetailSerializer.
  final Map<int, Map<String, dynamic>> companies = {};
  final Map<int, String> senhas = {};

  /// Documents no formato do DocumentSerializer (+ score/outcome, que a
  /// API ainda não expõe, para a tela já ter o que mostrar).
  final Map<int, List<Map<String, dynamic>>> documentosPorEmpresa = {};

  /// Quando cada documento "termina" de ser analisado.
  final Map<int, DateTime> prontoEm = {};

  int? logadoId;
  int _proximoId = 1;

  int novoId() => _proximoId++;

  Map<String, dynamic>? companyPorLogin(String login) {
    for (final c in companies.values) {
      if (c['email'] == login || c['cnpj'] == login) return c;
    }
    return null;
  }

  Map<String, dynamic> criarCompany({
    required String email,
    required String cnpj,
    required String senha,
    String? legalName,
  }) {
    final id = novoId();
    final company = <String, dynamic>{
      'id': id,
      'cnpj': cnpj,
      'email': email,
      'legal_name': legalName,
      'cnae_primary': null,
      'company_size': null,
      'founded_on': null,
      'address_city': null,
      'address_state': null,
      'confirmed': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    companies[id] = company;
    senhas[id] = senha;
    documentosPorEmpresa[id] = _documentosDeExemplo();
    return company;
  }

  List<Map<String, dynamic>> _documentosDeExemplo() {
    String haDias(int dias) =>
        DateTime.now().subtract(Duration(days: dias)).toUtc().toIso8601String();
    return [
      {
        'id': novoId(),
        'doc_type': 'contract',
        'filename': 'Contrato_Prestacao_Servicos_V2.pdf',
        'status': 'ready',
        'created_at': haDias(2),
        'score': 92,
        'outcome': 'good_fit',
        'analysis_json': MockAnalises.gerar(docType: 'contract', score: 92),
      },
      {
        'id': novoId(),
        'doc_type': 'tender',
        'filename': 'Edital_Pregao_045_2026.pdf',
        'status': 'ready',
        'created_at': haDias(5),
        'score': 48,
        'outcome': 'incompatible',
        'analysis_json': MockAnalises.gerar(docType: 'tender', score: 48),
      },
    ];
  }
}
