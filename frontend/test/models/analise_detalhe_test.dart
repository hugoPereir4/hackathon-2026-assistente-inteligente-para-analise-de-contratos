import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_frontend/models/analise_detalhe.dart';
import 'package:hackathon_frontend/models/analise_resumo.dart';

/// Resposta real da IA enviada pelo time do backend.
Map<String, dynamic> _exemplo() =>
    jsonDecode(File('test/fixtures/analise_exemplo.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> _documento(Object? analysisJson, {Object? score, Object? outcome}) => {
      'id': 5,
      'doc_type': 'contract',
      'filename': 'contrato.pdf',
      'status': 'ready',
      'created_at': '2026-10-17T12:00:00Z',
      'score': score,
      'outcome': outcome,
      'analysis_json': analysisJson,
    };

void main() {
  group('resposta real da IA (fixture)', () {
    late AnaliseDetalhe d;

    setUp(() => d = AnaliseDetalhe.fromJson(_documento(_exemplo())));

    test('score e outcome vêm de aderencia/outcome do analysis_json', () {
      expect(d.score, 67);
      expect(d.resultado, ResultadoMatch.incompativel);
      expect(d.aderencia?.cobertura, 75);
      expect(d.aderencia?.desconhecidos, 1);
      expect(d.requisitosAtendidos, 2);
    });

    test('papel da empresa', () {
      expect(d.papel?.rotulo, 'Fornecedora');
      expect(d.papel?.parteNoContrato, 'CONTRATADA');
      expect(d.papel?.evidencia?.clausula, 'Cláusula 1 - Partes e objeto');
    });

    test('prazos: com data primeiro, relativos com o evento de referência', () {
      expect(d.prazos.first.descricao, 'Assinatura do contrato');
      expect(d.prazos.first.data, DateTime(2026, 10, 20));
      expect(d.prazos[1].data, isNull);
      expect(d.prazos[1].textoRelativo, 'em até 30 dias (referência: assinatura)');
      expect(d.prazoPorId('prazos-4')?.descricao, 'Aprovação ou rejeição de cada entrega');
    });

    test('valores: montante e percentual chegam como texto', () {
      final [total, parcela, multa] = d.valores;
      expect(total.montante, 180000.0);
      expect(total.moeda, r'R$');
      expect(parcela.montante, 30000.0);
      expect(multa.montante, isNull);
      expect(multa.percentual, 2.0);
      expect(multa.ehPenalidade, isTrue);
    });

    test('requisitos, riscos, obrigações e perguntas', () {
      expect(d.requisitos.map((r) => r.status), [
        StatusRequisito.atendido,
        StatusRequisito.naoAtendido,
        StatusRequisito.indefinido,
        StatusRequisito.atendido,
      ]);
      expect(d.requisitos.first.obrigatorio, isTrue);
      expect(d.riscos.single.severidade, Severidade.media);
      expect(d.riscos.single.recomendacao, isNotNull);
      expect(d.obrigacoes.last.parteResponsavel, 'CONTRATANTE');
      expect(d.obrigacoes.last.prazoId, 'prazos-4');
      expect(d.perguntas.single.pergunta, 'A empresa possui certificação ISO 27001?');
      expect(d.perguntas.single.requisitoIds, ['req-3']);
    });

    test('metadados', () {
      expect(d.modelo, 'gemini-3.5-flash-lite');
      expect(d.analisadoEm, isNotNull);
    });
  });

  test('score/outcome das colunas do documento têm prioridade', () {
    final d = AnaliseDetalhe.fromJson(_documento(_exemplo(), score: 90, outcome: 'good_fit'));
    expect(d.score, 90);
    expect(d.resultado, ResultadoMatch.boaAderencia);
  });

  test('lê contagem e status de requisitos parcialmente atendidos', () {
    final analysis = _exemplo();
    final adherence = analysis['aderencia'] as Map<String, dynamic>;
    adherence['parcialmente_atendidos'] = 1;
    (analysis['requisitos'] as List<dynamic>)[0]['resultado'] = 'parcialmente_atende';
    final d = AnaliseDetalhe.fromJson(analysis);
    expect(d.aderencia?.parcialmenteAtendidos, 1);
    expect(d.requisitos.first.status, StatusRequisito.parcialmenteAtendido);
  });

  test('aceita o analysis_json puro, sem o documento em volta', () {
    final d = AnaliseDetalhe.fromJson(_exemplo());
    expect(d.score, 67);
    expect(d.resumo.nomeArquivo, 'Documento');
  });

  test('sem analysis_json (formato atual da API) não quebra e fica vazio', () {
    final d = AnaliseDetalhe.fromJson(_documento(null));
    expect(d.vazio, isTrue);
    expect(d.score, isNull);
  });

  test('itens malformados são ignorados ou recebem padrão', () {
    final d = AnaliseDetalhe.fromJson(_documento({
      'riscos': ['texto solto', {'severidade': 'altíssima'}],
      'requisitos': 'não é lista',
      'aderencia': {'score': '55.4'},
    }));
    expect(d.riscos.single.descricao, 'Risco identificado');
    expect(d.riscos.single.severidade, Severidade.media);
    expect(d.requisitos, isEmpty);
    expect(d.score, 55);
  });
}
