/// Estado do documento, a partir do `status` do backend.
enum StatusAnalise {
  /// `uploaded`: enviado, mas a análise ainda não foi pedida
  /// (POST /documents/{id}/analyze/).
  aguardando,

  /// `processing`: a IA está analisando.
  processando,

  /// `ready`
  concluida,

  /// `failed`
  erro;

  static StatusAnalise fromApi(String? status) => switch (status) {
        'ready' => concluida,
        'failed' => erro,
        'processing' => processando,
        _ => aguardando,
      };
}

/// `doc_type` do backend.
enum TipoDocumento {
  contrato('contract', 'Contrato'),
  edital('tender', 'Edital'),
  proposta('proposal', 'Proposta');

  final String codigo;
  final String descricao;

  const TipoDocumento(this.codigo, this.descricao);

  static TipoDocumento? fromCodigo(String? codigo) {
    for (final t in values) {
      if (t.codigo == codigo) return t;
    }
    return null;
  }
}

/// `outcome` do Motor de Match (ainda não exposto pela API).
enum ResultadoMatch {
  boaAderencia('good_fit'),
  altoRisco('high_risk'),
  incompativel('incompatible'),
  dadosInsuficientes('insufficient_data');

  final String codigo;

  const ResultadoMatch(this.codigo);

  static ResultadoMatch? fromCodigo(String? codigo) {
    for (final r in values) {
      if (r.codigo == codigo) return r;
    }
    return null;
  }
}

/// Item da lista "Análises recentes" (model `Document` do backend).
class AnaliseResumo {
  final String id;
  final String nomeArquivo;
  final DateTime enviadoEm;
  final TipoDocumento? tipo;
  final StatusAnalise status;

  /// Aderência ao perfil da empresa, de 0 a 100 (`score`).
  final int? matchScore;
  final ResultadoMatch? resultado;

  const AnaliseResumo({
    required this.id,
    required this.nomeArquivo,
    required this.enviadoEm,
    required this.status,
    this.tipo,
    this.matchScore,
    this.resultado,
  });

  bool get concluida => status == StatusAnalise.concluida;
  bool get aguardando => status == StatusAnalise.aguardando;
  bool get processando => status == StatusAnalise.processando;

  String? get categoria => tipo?.descricao;

  /// `score` e `outcome` são lidos se existirem; hoje o DocumentSerializer
  /// devolve só id, doc_type, filename, status e created_at.
  factory AnaliseResumo.fromJson(Map<String, dynamic> json) {
    return AnaliseResumo(
      id: json['id'].toString(),
      nomeArquivo: json['filename'] as String,
      enviadoEm: DateTime.parse(json['created_at'] as String).toLocal(),
      tipo: TipoDocumento.fromCodigo(json['doc_type'] as String?),
      status: StatusAnalise.fromApi(json['status'] as String?),
      matchScore: json['score'] as int?,
      resultado: ResultadoMatch.fromCodigo(json['outcome'] as String?),
    );
  }

  AnaliseResumo copyWith({StatusAnalise? status, int? matchScore, ResultadoMatch? resultado}) {
    return AnaliseResumo(
      id: id,
      nomeArquivo: nomeArquivo,
      enviadoEm: enviadoEm,
      tipo: tipo,
      status: status ?? this.status,
      matchScore: matchScore ?? this.matchScore,
      resultado: resultado ?? this.resultado,
    );
  }
}
