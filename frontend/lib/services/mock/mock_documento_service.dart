import 'dart:math';

import '../../core/network/api_exception.dart';
import '../../models/analise_detalhe.dart';
import '../../models/analise_resumo.dart';
import '../../models/arquivo_selecionado.dart';
import '../../models/lote_respostas.dart';
import '../documento_service.dart';
import 'mock_analises.dart';
import 'mock_database.dart';

/// Documentos fake, com o mesmo fluxo da API: o upload deixa o documento
/// "uploaded" e [analisar] passa por "processing" até "ready".
class MockDocumentoService implements DocumentoService {
  static const Duration _tempoDeAnalise = Duration(seconds: 4);

  final MockDatabase _db;
  final _random = Random();

  MockDocumentoService([MockDatabase? db]) : _db = db ?? MockDatabase.instance;

  List<Map<String, dynamic>> get _documentos {
    final lista = _db.documentosPorEmpresa[_db.logadoId];
    if (lista == null) {
      throw const ApiException('Sua sessão expirou. Entre novamente.', statusCode: 401);
    }
    return lista;
  }

  Map<String, dynamic> _documento(String id) => _documentos.firstWhere(
        (d) => d['id'].toString() == id,
        orElse: () => throw const ApiException('Recurso não encontrado.', statusCode: 404),
      );

  @override
  Future<List<AnaliseResumo>> listarRecentes() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final lista = _documentos.map(AnaliseResumo.fromJson).toList()
      ..sort((a, b) => b.enviadoEm.compareTo(a.enviadoEm));
    return lista;
  }

  @override
  Future<AnaliseResumo> enviar(ArquivoSelecionado arquivo, {TipoDocumento? tipo}) async {
    await arquivo.lerBytes(); // simula a leitura/upload do conteúdo
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final documento = <String, dynamic>{
      'id': _db.novoId(),
      'doc_type': tipo?.codigo,
      'filename': arquivo.nome,
      'status': 'uploaded',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'score': null,
      'outcome': null,
    };
    _documentos.add(documento);
    return AnaliseResumo.fromJson(documento);
  }

  @override
  Future<AnaliseResumo> analisar(String id) async {
    final documento = _documento(id);
    if (documento['status'] != 'uploaded' && documento['status'] != 'failed') {
      throw const ApiException(
        'O documento já foi analisado, está em processamento ou não existe.',
        statusCode: 409,
      );
    }
    documento['status'] = 'processing';
    await Future<void>.delayed(_tempoDeAnalise);

    final score = 40 + _random.nextInt(60);
    final docType = documento['doc_type'] as String? ??
        ((documento['filename'] as String).toLowerCase().contains('edital') ? 'tender' : 'contract');
    final analise = MockAnalises.gerar(docType: docType, score: score);
    documento
      ..['status'] = 'ready'
      ..['doc_type'] = docType
      ..['score'] = score
      ..['outcome'] = analise['outcome']
      ..['analysis_json'] = analise;
    return AnaliseResumo.fromJson(documento);
  }

  @override
  Future<AnaliseResumo> buscar(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return AnaliseResumo.fromJson(_documento(id));
  }

  @override
  Future<AnaliseDetalhe> buscarDetalhe(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return AnaliseDetalhe.fromJson(_documento(id));
  }

  /// Lotes de respostas em aberto, por id.
  final _lotes = <String, Map<String, dynamic>>{};

  Map<String, dynamic> _analise(Map<String, dynamic> documento) {
    final analise = documento['analysis_json'];
    if (documento['status'] != 'ready' || analise is! Map<String, dynamic>) {
      throw const ApiException(
        'O documento precisa ter uma análise concluída para receber respostas.',
        statusCode: 409,
      );
    }
    return analise;
  }

  @override
  Future<LoteRespostas> previaRespostas(String id, Map<String, String> respostas) async {
    final analise = _analise(_documento(id));
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    final perguntas = {
      for (final p in (analise['perguntas_pendentes'] as List).cast<Map<String, dynamic>>())
        p['id']: p,
    };
    final propostas = [
      for (final r in respostas.entries)
        _interpretar(perguntas[r.key] ?? (throw const ApiException(
              'Informe perguntas existentes, sem IDs repetidos.',
              statusCode: 400,
            )), r.value),
    ];
    final lote = <String, dynamic>{
      'id': 'lote-${_db.novoId()}',
      'document': id,
      'status': 'pending',
      'proposals': propostas,
      'reanalysis_status': null,
      'reanalysis_error': '',
    };
    _lotes[lote['id'] as String] = lote;
    return LoteRespostas.fromJson(lote);
  }

  /// Imitação simples da IA: "sim..." → true, "não..." → false.
  Map<String, dynamic> _interpretar(Map<String, dynamic> pergunta, String texto) {
    final t = texto.trim().toLowerCase();
    final booleano = pergunta['tipo_valor'] == 'booleano';
    final Object? valor = !booleano
        ? texto.trim()
        : t.startsWith('sim')
            ? true
            : (t.startsWith('não') || t.startsWith('nao'))
                ? false
                : null;
    final suficiente = valor != null;
    return {
      'id': pergunta['id'],
      'pergunta_id': pergunta['id'],
      'pergunta': pergunta['pergunta'],
      'texto_original': texto,
      'fato_chave': pergunta['fato_chave'],
      'fato_rotulo': pergunta['fato_rotulo'],
      'valor_proposto': valor,
      'tipo_valor': suficiente ? pergunta['tipo_valor'] : null,
      'suficiente': suficiente,
      'justificativa': suficiente
          ? 'Interpretado a partir da resposta do usuário.'
          : 'A resposta não deixa claro se a empresa atende.',
      'esclarecimento': suficiente ? null : 'A empresa possui ou não? Responda com sim ou não.',
      'valor_anterior': null,
      'exige_autorizacao_substituicao': false,
    };
  }

  @override
  Future<ConfirmacaoRespostas> confirmarRespostas(
    String id,
    String loteId, {
    required List<String> aprovadas,
    List<String> autorizarSubstituicao = const [],
  }) async {
    final documento = _documento(id);
    final analise = _analise(documento);
    final lote = _lotes[loteId];
    if (lote == null || lote['document'] != id) {
      throw const ApiException('Lote não encontrado.', statusCode: 404);
    }
    final propostas = {
      for (final p in (lote['proposals'] as List).cast<Map<String, dynamic>>()) p['id']: p,
    };
    if (aprovadas.any((a) => propostas[a]?['suficiente'] != true)) {
      throw const ApiException(
        'Respostas insuficientes precisam de esclarecimento antes da confirmação.',
        statusCode: 400,
      );
    }
    await Future<void>.delayed(_tempoDeAnalise);

    // "Reanálise": requisitos ligados às respostas passam a ter resultado.
    final perguntas = (analise['perguntas_pendentes'] as List).cast<Map<String, dynamic>>();
    final requisitos = (analise['requisitos'] as List).cast<Map<String, dynamic>>();
    for (final aprovada in aprovadas) {
      final pergunta = perguntas.firstWhere((p) => p['id'] == aprovada);
      final atende = propostas[aprovada]!['valor_proposto'] != false;
      for (final r in requisitos.where((r) => (pergunta['requisito_ids'] as List).contains(r['id']))) {
        r['resultado'] = atende ? 'atende' : 'nao_atende';
        r['justificativa'] = 'Respondido pela empresa: ${pergunta['fato_rotulo']}.';
      }
    }
    perguntas.removeWhere((p) => aprovadas.contains(p['id']));
    _recalcular(documento, analise);

    lote
      ..['status'] = 'confirmed'
      ..['approved_proposals'] = aprovadas
      ..['reanalysis_status'] = 'ready';
    return ConfirmacaoRespostas.fromJson({
      'lote': lote,
      'respostas_salvas': true,
      'reavaliacao': {'status': 'ready', 'erro': null},
      'documento': {...documento, 'analysis_desatualizada': false},
    });
  }

  void _recalcular(Map<String, dynamic> documento, Map<String, dynamic> analise) {
    final requisitos = (analise['requisitos'] as List).cast<Map<String, dynamic>>();
    final atendidos = requisitos.where((r) => r['resultado'] == 'atende').length;
    final naoAtendidos = requisitos.where((r) => r['resultado'] == 'nao_atende').length;
    final avaliados = atendidos + naoAtendidos;
    final score = avaliados == 0 ? null : (atendidos * 100 / avaliados).round();
    final outcome = naoAtendidos > 0
        ? 'incompatible'
        : (avaliados < requisitos.length ? 'insufficient_data' : 'good_fit');
    analise
      ..['aderencia'] = {
        'score': score,
        'cobertura': (avaliados * 100 / requisitos.length).round(),
        'total': requisitos.length,
        'avaliados': avaliados,
        'atendidos': atendidos,
        'nao_atendidos': naoAtendidos,
        'desconhecidos': requisitos.length - avaliados,
      }
      ..['outcome'] = outcome
      ..['metadados'] = {
        ...analise['metadados'] as Map<String, dynamic>,
        'analisado_em': DateTime.now().toUtc().toIso8601String(),
      };
    documento
      ..['score'] = score
      ..['outcome'] = outcome;
  }

  @override
  Future<AnaliseDetalhe> reanalisar(String id) async {
    final documento = _documento(id);
    if (documento['analysis_json'] == null) {
      throw const ApiException(
        'O documento ainda não possui análise. Use o endpoint analyze.',
        statusCode: 400,
      );
    }
    await Future<void>.delayed(_tempoDeAnalise);
    final analise = documento['analysis_json'] as Map<String, dynamic>;
    analise['schema_version'] = 2;
    _recalcular(documento, analise);
    documento['status'] = 'ready';
    return AnaliseDetalhe.fromJson(documento);
  }
}
