import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_frontend/models/analise_detalhe.dart';
import 'package:hackathon_frontend/models/lote_respostas.dart';

/// Formatos tirados de core/modules/documents/docs/answers.md (backend).
Map<String, dynamic> _proposta({
  String id = 'q1',
  Object? valor = true,
  bool suficiente = true,
  Object? anterior,
  bool exige = false,
}) =>
    {
      'id': id,
      'pergunta_id': id,
      'pergunta': 'Sua empresa já possui certificação ISO 9001?',
      'texto_original': 'Sim, temos ISO 9001.',
      'fato_chave': 'iso_9001',
      'fato_rotulo': 'Possui certificação ISO 9001',
      'valor_proposto': valor,
      'tipo_valor': suficiente ? 'booleano' : null,
      'tipos_campos': null,
      'suficiente': suficiente,
      'justificativa': 'O usuário confirmou que já possui a certificação.',
      'esclarecimento': suficiente ? null : 'Vocês já têm o certificado emitido?',
      'valor_anterior': anterior,
      'exige_autorizacao_substituicao': exige,
    };

Map<String, dynamic> _lote(List<Map<String, dynamic>> propostas) => {
      'id': '6f1c1f3e-0000-4000-8000-000000000001',
      'document': 5,
      'analysis_fingerprint': 'abc',
      'original_answers': [],
      'proposals': propostas,
      'status': 'pending',
      'approved_proposals': [],
      'overwrite_authorizations': [],
      'created_at': '2026-10-17T12:00:00Z',
      'confirmed_at': null,
      'reanalysis_status': null,
      'reanalysis_error': '',
    };

void main() {
  test('LoteRespostas lê a prévia', () {
    final lote = LoteRespostas.fromJson(_lote([_proposta()]));
    expect(lote.pendente, isTrue);
    expect(lote.erroReanalise, isNull); // "" vira null
    final p = lote.propostas.single;
    expect(p.rotulo, 'Possui certificação ISO 9001');
    expect(p.valorPropostoFormatado, 'Sim');
    expect(p.suficiente, isTrue);
  });

  test('resposta vaga fica insuficiente, com esclarecimento', () {
    final p = PropostaResposta.fromJson(_proposta(valor: null, suficiente: false));
    expect(p.suficiente, isFalse);
    expect(p.esclarecimento, 'Vocês já têm o certificado emitido?');
    expect(p.valorPropostoFormatado, '—');
  });

  test('valor_anterior vem como {valor, confirmado, origem, rotulo}', () {
    final p = PropostaResposta.fromJson(_proposta(
      valor: false,
      anterior: {'valor': true, 'confirmado': true, 'origem': 'user', 'rotulo': 'ISO'},
      exige: true,
    ));
    expect(p.exigeAutorizacaoSubstituicao, isTrue);
    expect(p.valorAnteriorFormatado, 'Sim');
    expect(p.valorPropostoFormatado, 'Não');
  });

  test('formata datas e objetos', () {
    expect(PropostaResposta.formatarValor('2020-03-15', 'data'), '15/03/2020');
    expect(
      PropostaResposta.formatarValor({'ano': 2025, 'valor': '1200000.00'}, 'objeto'),
      'ano: 2025 • valor: 1200000.00',
    );
  });

  test('ConfirmacaoRespostas traz o documento reanalisado', () {
    final c = ConfirmacaoRespostas.fromJson({
      'respostas_salvas': true,
      'reavaliacao': {'status': 'failed', 'erro': 'Falha do provedor.'},
      'lote': {..._lote([_proposta()]), 'status': 'confirmed'},
      'documento': {
        'id': 5,
        'filename': 'contrato.pdf',
        'status': 'failed',
        'created_at': '2026-10-17T12:00:00Z',
        'analysis_desatualizada': true,
        'analysis_json': {'schema_version': 2, 'resumo': 'Contrato.'},
      },
    });
    expect(c.reanaliseFalhou, isTrue);
    expect(c.erroReanalise, 'Falha do provedor.');
    expect(c.lote.pendente, isFalse);
    expect(c.documento.desatualizada, isTrue);
  });

  group('AnaliseDetalhe v2', () {
    AnaliseDetalhe detalhe(int versao) => AnaliseDetalhe.fromJson({
          'id': 5,
          'status': 'ready',
          'analysis_json': {
            'schema_version': versao,
            'perguntas_pendentes': [
              {
                'id': 'q1',
                'pergunta': 'Possui ISO 9001?',
                'requisito_ids': ['r1'],
                'fato_chave': 'iso_9001',
                'sobre_papel': false,
                'destino': 'company_fact',
                'fato_rotulo': 'Possui certificação ISO 9001',
                'tipo_valor': 'booleano',
              },
              {
                'id': 'q2',
                'pergunta': 'A empresa é a contratante ou a contratada?',
                'requisito_ids': [],
                'fato_chave': null,
                'sobre_papel': true,
                'destino': 'papel',
              },
            ],
          },
        });

    test('só perguntas company_fact podem ser respondidas', () {
      final d = detalhe(2);
      expect(d.versaoAntiga, isFalse);
      expect(d.perguntas, hasLength(2));
      expect(d.perguntasRespondiveis.map((p) => p.id), ['q1']);
      expect(d.perguntasRespondiveis.single.tipoValor, 'booleano');
    });

    test('análise v1 precisa ser reanalisada antes de responder', () {
      final d = detalhe(1);
      expect(d.versaoAntiga, isTrue);
      expect(d.perguntasRespondiveis, isEmpty);
    });
  });
}
