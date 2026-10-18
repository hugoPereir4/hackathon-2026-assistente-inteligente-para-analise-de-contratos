import 'package:flutter/widgets.dart';

import '../models/analise_detalhe.dart';
import '../models/analise_resumo.dart';
import '../models/lote_respostas.dart';
import '../services/documento_service.dart';
import 'base_controller.dart';

/// O que está em andamento na tela, para o botão certo mostrar o loading.
enum AcaoResultado { nenhuma, previa, confirmacao, reanalise }

/// Controller do Painel de Resultados (Fase 3 do fluxograma).
///
/// Fluxo das perguntas pendentes:
///   1. o usuário responde ([respostaDe]) e pede a [gerarPrevia];
///   2. a IA devolve como entendeu cada resposta ([lote]);
///   3. o usuário aprova as propostas certas e [confirmar] grava no perfil
///      e reanalisa o documento.
class ResultadoController extends BaseController {
  final DocumentoService _documentoService;

  /// O que já se sabe pela lista (nome, data); mostrado enquanto o detalhe carrega.
  final AnaliseResumo analiseInicial;

  ResultadoController(this._documentoService, this.analiseInicial);

  AnaliseDetalhe? _detalhe;
  AnaliseDetalhe? get detalhe => _detalhe;

  AnaliseResumo get resumo => _detalhe?.resumo ?? analiseInicial;

  AcaoResultado _acao = AcaoResultado.nenhuma;
  AcaoResultado get acao => _acao;
  bool get ocupado => _acao != AcaoResultado.nenhuma;

  LoteRespostas? _lote;
  LoteRespostas? get lote => _lote;

  final Set<String> _aprovadas = {};
  bool aprovada(String propostaId) => _aprovadas.contains(propostaId);

  final Map<String, TextEditingController> _respostas = {};

  TextEditingController respostaDe(PerguntaPendente pergunta) =>
      _respostas.putIfAbsent(pergunta.id!, TextEditingController.new);

  Future<void> carregar() async {
    await runAsync(() async {
      _detalhe = await _documentoService.buscarDetalhe(analiseInicial.id);
    });
  }

  /// Envia as respostas preenchidas. Retorna `false` em erro ([errorMessage]).
  Future<bool> gerarPrevia() async {
    final respostas = {
      for (final p in _detalhe?.perguntasRespondiveis ?? const <PerguntaPendente>[])
        if (respostaDe(p).text.trim().isNotEmpty) p.id!: respostaDe(p).text.trim(),
    };
    if (respostas.isEmpty) {
      setError('Responda pelo menos uma pergunta.');
      return false;
    }
    return _executar(AcaoResultado.previa, () async {
      final lote = await _documentoService.previaRespostas(analiseInicial.id, respostas);
      _lote = lote;
      // Já vem marcado o que a IA entendeu com segurança; o usuário pode desmarcar.
      _aprovadas
        ..clear()
        ..addAll(lote.propostas.where((p) => p.suficiente).map((p) => p.id));
    });
  }

  void alternarAprovacao(PropostaResposta proposta) {
    if (!proposta.suficiente) return;
    _aprovadas.contains(proposta.id) ? _aprovadas.remove(proposta.id) : _aprovadas.add(proposta.id);
    notify();
  }

  /// Volta para as respostas, para corrigir o texto e gerar outra prévia.
  void editarRespostas() {
    _lote = null;
    _aprovadas.clear();
    notify();
  }

  /// Grava as propostas aprovadas e reanalisa. Retorna a confirmação
  /// (para a view avisar se a reanálise falhou) ou `null` em erro.
  Future<ConfirmacaoRespostas?> confirmar() async {
    final lote = _lote;
    if (lote == null) return null;
    if (_aprovadas.isEmpty) {
      setError('Aprove pelo menos uma resposta.');
      return null;
    }
    // Ao aprovar um item que troca um fato confirmado, o usuário já viu o
    // aviso com o valor anterior na prévia: a aprovação vale como autorização.
    final autorizadas = lote.propostas
        .where((p) => p.exigeAutorizacaoSubstituicao && _aprovadas.contains(p.id))
        .map((p) => p.id)
        .toList();

    ConfirmacaoRespostas? resultado;
    await _executar(AcaoResultado.confirmacao, () async {
      resultado = await _documentoService.confirmarRespostas(
        analiseInicial.id,
        lote.id,
        aprovadas: _aprovadas.toList(),
        autorizarSubstituicao: autorizadas,
      );
      _detalhe = resultado!.documento;
      _lote = null;
      _aprovadas.clear();
      for (final c in _respostas.values) {
        c.clear();
      }
    });
    return resultado;
  }

  /// Roda a IA de novo com o perfil atual.
  Future<bool> reanalisar() {
    return _executar(AcaoResultado.reanalise, () async {
      _detalhe = await _documentoService.reanalisar(analiseInicial.id);
      _lote = null;
      _aprovadas.clear();
    });
  }

  /// Como [runAsync], mas sem trocar o conteúdo da tela pelo loading geral.
  Future<bool> _executar(AcaoResultado acao, Future<void> Function() action) async {
    if (ocupado) return false;
    _acao = acao;
    try {
      return await runAsync(action);
    } finally {
      _acao = AcaoResultado.nenhuma;
      notify();
    }
  }

  @override
  void dispose() {
    for (final c in _respostas.values) {
      c.dispose();
    }
    super.dispose();
  }
}
