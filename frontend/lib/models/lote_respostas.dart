import 'analise_detalhe.dart';

/// Lote de respostas às perguntas pendentes da IA:
/// POST /documents/{id}/answers/preview/ (status "pending") e
/// POST /documents/{id}/answers/{batch_id}/confirm/ (status "confirmed").
///
/// A IA interpreta cada resposta como um fato da empresa; o usuário revisa as
/// [propostas] e aprova as que estiverem certas antes de gravar no perfil.
class LoteRespostas {
  final String id;
  final String status;
  final List<PropostaResposta> propostas;

  /// Estado da reanálise disparada pela confirmação (`ready`, `failed`...).
  final String? statusReanalise;
  final String? erroReanalise;

  const LoteRespostas({
    required this.id,
    required this.status,
    this.propostas = const [],
    this.statusReanalise,
    this.erroReanalise,
  });

  bool get pendente => status == 'pending';

  factory LoteRespostas.fromJson(Map<String, dynamic> json) => LoteRespostas(
        id: '${json['id']}',
        status: json['status'] as String? ?? 'pending',
        propostas: (json['proposals'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(PropostaResposta.fromJson)
            .toList(),
        statusReanalise: json['reanalysis_status'] as String?,
        erroReanalise: _texto(json['reanalysis_error']),
      );
}

/// Como a IA entendeu uma resposta: o fato que será gravado no perfil.
class PropostaResposta {
  final String id;
  final String perguntaId;
  final String pergunta;
  final String textoOriginal;
  final String? fatoChave;
  final String? fatoRotulo;

  /// bool, número, texto, data ("YYYY-MM-DD"), decimal em texto ou objeto plano.
  final Object? valorProposto;
  final String? tipoValor;

  /// `false` quando a resposta foi vaga ("não sei"): não pode ser aprovada.
  final bool suficiente;
  final String? justificativa;

  /// Pergunta da IA para esclarecer uma resposta insuficiente.
  final String? esclarecimento;

  /// Valor que já existia no perfil, se houver.
  final Object? valorAnterior;

  /// O valor proposto substitui um fato já confirmado: precisa de autorização.
  final bool exigeAutorizacaoSubstituicao;

  const PropostaResposta({
    required this.id,
    required this.perguntaId,
    required this.pergunta,
    required this.textoOriginal,
    required this.suficiente,
    this.fatoChave,
    this.fatoRotulo,
    this.valorProposto,
    this.tipoValor,
    this.justificativa,
    this.esclarecimento,
    this.valorAnterior,
    this.exigeAutorizacaoSubstituicao = false,
  });

  String get rotulo => fatoRotulo ?? pergunta;

  String get valorPropostoFormatado => formatarValor(valorProposto, tipoValor);

  String? get valorAnteriorFormatado =>
      valorAnterior == null ? null : formatarValor(valorAnterior, tipoValor);

  factory PropostaResposta.fromJson(Map<String, dynamic> json) {
    final anterior = json['valor_anterior'];
    return PropostaResposta(
      id: '${json['id']}',
      perguntaId: '${json['pergunta_id'] ?? json['id']}',
      pergunta: _texto(json['pergunta']) ?? '',
      textoOriginal: _texto(json['texto_original']) ?? '',
      fatoChave: _texto(json['fato_chave']),
      fatoRotulo: _texto(json['fato_rotulo']),
      valorProposto: json['valor_proposto'],
      tipoValor: _texto(json['tipo_valor']),
      suficiente: json['suficiente'] == true,
      justificativa: _texto(json['justificativa']),
      esclarecimento: _texto(json['esclarecimento']),
      // O backend manda {valor, confirmado, origem, rotulo}.
      valorAnterior: anterior is Map<String, dynamic> ? anterior['valor'] : anterior,
      exigeAutorizacaoSubstituicao: json['exige_autorizacao_substituicao'] == true,
    );
  }

  /// "Sim", "Não", "2020-01-01" → "01/01/2020", objeto → "ano: 2024 • valor: 10".
  static String formatarValor(Object? valor, [String? tipo]) => switch (valor) {
        null => '—',
        true => 'Sim',
        false => 'Não',
        final Map<String, dynamic> m =>
          m.entries.map((e) => '${e.key}: ${formatarValor(e.value)}').join(' • '),
        final String s when tipo == 'data' => _dataBr(s) ?? s,
        _ => '$valor',
      };

  static String? _dataBr(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return null;
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year}';
  }
}

/// Retorno da confirmação: o lote salvo e o documento já reanalisado.
class ConfirmacaoRespostas {
  final LoteRespostas lote;
  final AnaliseDetalhe documento;

  /// `failed` quando os fatos foram salvos mas a reanálise da IA falhou.
  final String? statusReanalise;
  final String? erroReanalise;

  const ConfirmacaoRespostas({
    required this.lote,
    required this.documento,
    this.statusReanalise,
    this.erroReanalise,
  });

  bool get reanaliseFalhou => statusReanalise == 'failed';

  factory ConfirmacaoRespostas.fromJson(Map<String, dynamic> json) {
    final reavaliacao = json['reavaliacao'] is Map<String, dynamic>
        ? json['reavaliacao'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return ConfirmacaoRespostas(
      lote: LoteRespostas.fromJson(json['lote'] as Map<String, dynamic>),
      documento: AnaliseDetalhe.fromJson(json['documento'] as Map<String, dynamic>),
      statusReanalise: reavaliacao['status'] as String?,
      erroReanalise: _texto(reavaliacao['erro']),
    );
  }
}

String? _texto(Object? valor) {
  final texto = valor?.toString().trim();
  return texto == null || texto.isEmpty ? null : texto;
}
