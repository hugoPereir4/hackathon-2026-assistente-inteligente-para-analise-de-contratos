enum StatusAnalise { processando, concluida, erro }

/// Item da lista "Análises recentes": um documento enviado e o resultado
/// resumido do Motor de Match (documento x perfil da empresa).
class AnaliseResumo {
  final String id;
  final String nomeArquivo;
  final DateTime enviadoEm;
  final String? categoria;
  final StatusAnalise status;

  /// Aderência ao perfil da empresa, de 0 a 100. Só existe quando concluída.
  final int? matchScore;

  const AnaliseResumo({
    required this.id,
    required this.nomeArquivo,
    required this.enviadoEm,
    required this.status,
    this.categoria,
    this.matchScore,
  });

  bool get concluida => status == StatusAnalise.concluida;

  factory AnaliseResumo.fromJson(Map<String, dynamic> json) {
    return AnaliseResumo(
      id: json['id'].toString(),
      nomeArquivo: json['file_name'] as String,
      enviadoEm: DateTime.parse(json['created_at'] as String),
      categoria: json['category'] as String?,
      status: StatusAnalise.values.byName(json['status'] as String? ?? 'processando'),
      matchScore: json['match_score'] as int?,
    );
  }

  AnaliseResumo copyWith({StatusAnalise? status, int? matchScore, String? categoria}) {
    return AnaliseResumo(
      id: id,
      nomeArquivo: nomeArquivo,
      enviadoEm: enviadoEm,
      status: status ?? this.status,
      categoria: categoria ?? this.categoria,
      matchScore: matchScore ?? this.matchScore,
    );
  }
}
