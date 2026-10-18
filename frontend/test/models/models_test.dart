import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_frontend/models/analise_resumo.dart';
import 'package:hackathon_frontend/models/empresa.dart';
import 'package:hackathon_frontend/models/nova_conta.dart';
import 'package:hackathon_frontend/models/paginated.dart';
import 'package:hackathon_frontend/models/porte_empresa.dart';
import 'package:hackathon_frontend/models/usuario.dart';

void main() {
  test('Usuario lê o CompanyDetailSerializer', () {
    final u = Usuario.fromJson({
      'id': 7,
      'cnpj': '11222333000181',
      'email': 'ana@empresa.com',
      'legal_name': null,
      'confirmed': false,
      'created_at': '2026-10-17T12:00:00Z',
    });
    expect(u.id, 7);
    expect(u.confirmado, isFalse);
  });

  test('Empresa lê a consulta de CNPJ (GET /companies/{cnpj}/)', () {
    final e = Empresa.fromJson({
      'cnpj': '68756612000142',
      'legal_name': '68.756.612 JOSE JUNIOR WAROL SOARES',
      'cnae_primary': '4721-1/02',
      'company_size': 'MICRO EMPRESA',
      'founded_on': '2026-08-24',
      'address_city': 'SUMIDOURO',
      'address_state': 'RJ',
    });
    expect(e.razaoSocial, '68.756.612 JOSE JUNIOR WAROL SOARES');
    expect(e.cnae, '4721-1/02');
    expect(e.porte, PorteEmpresa.me);
    expect(e.dataFundacao, DateTime(2026, 8, 24));
    expect(e.cidade, 'SUMIDOURO');
    expect(e.uf, 'RJ');
  });

  test('PorteEmpresa aceita código do banco e texto da API externa', () {
    expect(PorteEmpresa.fromCodigo('EPP'), PorteEmpresa.epp);
    expect(PorteEmpresa.fromCodigo('Empresa de Pequeno Porte'), PorteEmpresa.epp);
    expect(PorteEmpresa.fromCodigo('DEMAIS'), PorteEmpresa.demais);
    expect(PorteEmpresa.fromCodigo('qualquer coisa'), isNull);
    expect(PorteEmpresa.fromCodigo(null), isNull);
  });

  test('NovaConta envia ao register a empresa junto, sem campos vazios', () {
    const conta = NovaConta(
      email: 'ana@empresa.com',
      senha: 'senhaForte1',
      empresa: Empresa(cnpj: '11222333000181', razaoSocial: 'ACME', cidade: 'Rio'),
    );
    expect(conta.toRegisterJson(), {
      'email': 'ana@empresa.com',
      'password': 'senhaForte1',
      'cnpj': '11222333000181',
      'legal_name': 'ACME',
      'address_city': 'Rio',
      'confirmed': true,
    });
  });

  test('Empresa.toPerfilJson usa as colunas do banco e não manda o CNPJ', () {
    final json = Empresa(
      cnpj: '11222333000181',
      porte: PorteEmpresa.epp,
      dataFundacao: DateTime(2018, 3, 12),
      uf: 'RJ',
    ).toPerfilJson();
    expect(json.containsKey('cnpj'), isFalse);
    expect(json['company_size'], 'EPP');
    expect(json['founded_on'], '2018-03-12');
    expect(json['address_state'], 'RJ');
  });

  test('AnaliseResumo lê a página do DocumentSerializer', () {
    final pagina = Paginated.fromJson({
      'count': 2,
      'next': null,
      'previous': null,
      'results': [
        {
          'id': 3,
          'doc_type': 'tender',
          'filename': 'edital.pdf',
          'status': 'uploaded',
          'created_at': '2026-10-17T12:00:00Z',
        },
        {
          'id': 2,
          'doc_type': null,
          'filename': 'contrato.pdf',
          'status': 'ready',
          'created_at': '2026-10-15T12:00:00Z',
          'score': 92,
          'outcome': 'good_fit',
        },
      ],
    }, AnaliseResumo.fromJson);

    expect(pagina.count, 2);
    final [edital, contrato] = pagina.results;
    expect(edital.id, '3');
    expect(edital.status, StatusAnalise.aguardando);
    expect(edital.categoria, 'Edital');
    expect(contrato.concluida, isTrue);
    expect(contrato.matchScore, 92);
    expect(contrato.resultado, ResultadoMatch.boaAderencia);
    expect(contrato.categoria, isNull);
  });
}
