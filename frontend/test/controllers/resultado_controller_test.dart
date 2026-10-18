import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_frontend/controllers/resultado_controller.dart';
import 'package:hackathon_frontend/models/analise_detalhe.dart';
import 'package:hackathon_frontend/models/analise_resumo.dart';
import 'package:hackathon_frontend/services/mock/mock_analises.dart';
import 'package:hackathon_frontend/services/mock/mock_database.dart';
import 'package:hackathon_frontend/services/mock/mock_documento_service.dart';

/// Fluxo das perguntas pendentes de ponta a ponta, com os services mock.
void main() {
  late ResultadoController controller;

  setUp(() async {
    final db = MockDatabase.instance;
    final empresa = db.criarCompany(email: 'teste@empresa.com', cnpj: '11222333000181', senha: 'x');
    db.logadoId = empresa['id'] as int;
    // score < 75: a análise de exemplo tem a pergunta da ISO 27001 (req-3 desconhecido).
    final documento = {
      'id': db.novoId(),
      'filename': 'contrato.pdf',
      'status': 'ready',
      'created_at': '2026-10-17T12:00:00Z',
      'analysis_json': MockAnalises.gerar(docType: 'contract', score: 50),
    };
    db.documentosPorEmpresa[db.logadoId]!.add(documento);

    controller = ResultadoController(
      MockDocumentoService(db),
      AnaliseResumo.fromJson(documento),
    );
    await controller.carregar();
  });

  tearDown(() => controller.dispose());

  PerguntaPendente pergunta() => controller.detalhe!.perguntasRespondiveis.single;

  test('sem resposta não envia', () async {
    expect(await controller.gerarPrevia(), isFalse);
    expect(controller.errorMessage, 'Responda pelo menos uma pergunta.');
    expect(controller.lote, isNull);
  });

  test('responder → prévia → confirmar atualiza o resultado', () async {
    expect(pergunta().id, 'pergunta-1');
    controller.respostaDe(pergunta()).text = 'Sim, temos desde 2022.';

    expect(await controller.gerarPrevia(), isTrue);
    final proposta = controller.lote!.propostas.single;
    expect(proposta.valorPropostoFormatado, 'Sim');
    expect(controller.aprovada(proposta.id), isTrue); // já vem marcada

    final confirmacao = await controller.confirmar();
    expect(confirmacao, isNotNull);
    expect(confirmacao!.reanaliseFalhou, isFalse);
    expect(controller.lote, isNull);
    expect(controller.detalhe!.perguntas, isEmpty);
    final iso = controller.detalhe!.requisitos.firstWhere((r) => r.id == 'req-3');
    expect(iso.status, StatusRequisito.atendido);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('resposta vaga não pode ser aprovada', () async {
    controller.respostaDe(pergunta()).text = 'Estamos vendo isso.';
    await controller.gerarPrevia();
    final proposta = controller.lote!.propostas.single;
    expect(proposta.suficiente, isFalse);
    expect(controller.aprovada(proposta.id), isFalse);

    controller.alternarAprovacao(proposta);
    expect(controller.aprovada(proposta.id), isFalse);
    expect(await controller.confirmar(), isNull);
    expect(controller.errorMessage, 'Aprove pelo menos uma resposta.');

    controller.editarRespostas();
    expect(controller.lote, isNull);
  });
}
