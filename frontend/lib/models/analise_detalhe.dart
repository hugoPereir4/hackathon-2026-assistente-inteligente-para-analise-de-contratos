import 'analise_resumo.dart';

/// Resultado completo de uma análise: GET /documents/{id}/.
///
/// O `analysis_json` segue o formato devolvido pela IA (schema_version 1 e 2;
/// a v2 acrescenta `destino`, `fato_rotulo` e `tipo_valor` nas perguntas):
///
/// ```text
/// resumo                 texto
/// papel_empresa          {papel, justificativa, evidencia}
/// prazos[]               {id, descricao, data?, prazo_relativo?, evento_referencia?, evidencia}
/// valores[]              {descricao, categoria, moeda?, montante?, percentual?, aproximado, evidencia}
/// obrigacoes[]           {descricao, parte_responsavel, prazo_id?, evidencia}
/// riscos[]               {descricao, severidade, impacto, recomendacao, evidencia}
/// requisitos[]           {id, descricao, obrigatorio, resultado, justificativa, evidencia, referencias_perfil}
/// perguntas_pendentes[]  {id, pergunta, requisito_ids, fato_chave?, destino}
/// score                  nota de 0 a 100 dada pela IA (+ justificativa_score)
/// aderencia              {score, cobertura, total, avaliados, atendidos, nao_atendidos, desconhecidos}
/// outcome                good_fit | high_risk | incompatible | insufficient_data
/// metadados              {analisado_em, modelo, contexto_empresa}
/// evidencia              {trecho, clausula}
/// ```
///
/// Todos os campos são tratados como opcionais: o que não vier (ou vier
/// num formato inesperado) é ignorado, para não derrubar a tela.
class AnaliseDetalhe {
  final AnaliseResumo resumo;
  final String? textoResumo;
  final PapelEmpresa? papel;
  final Aderencia? aderencia;
  final List<Risco> riscos;
  final List<Prazo> prazos;
  final List<ValorFinanceiro> valores;
  final List<Requisito> requisitos;
  final List<Obrigacao> obrigacoes;
  final List<PerguntaPendente> perguntas;
  final DateTime? analisadoEm;
  final String? modelo;
  final int? schemaVersion;

  /// `analysis_desatualizada`: o perfil da empresa mudou depois da análise.
  final bool desatualizada;

  const AnaliseDetalhe({
    required this.resumo,
    this.textoResumo,
    this.papel,
    this.aderencia,
    this.riscos = const [],
    this.prazos = const [],
    this.valores = const [],
    this.requisitos = const [],
    this.obrigacoes = const [],
    this.perguntas = const [],
    this.analisadoEm,
    this.modelo,
    this.schemaVersion,
    this.desatualizada = false,
  });

  int? get score => resumo.matchScore;

  /// Só análises v2 aceitam respostas; as antigas precisam ser reanalisadas.
  bool get versaoAntiga => schemaVersion != null && schemaVersion! < 2;

  /// Perguntas que o usuário pode responder pelo app (fatos da empresa).
  List<PerguntaPendente> get perguntasRespondiveis =>
      versaoAntiga ? const [] : perguntas.where((p) => p.respondivel).toList();
  ResultadoMatch? get resultado => resumo.resultado;

  int get requisitosAtendidos =>
      aderencia?.atendidos ??
      requisitos.where((r) => r.status == StatusRequisito.atendido).length;

  bool get vazio =>
      textoResumo == null &&
      riscos.isEmpty &&
      prazos.isEmpty &&
      valores.isEmpty &&
      requisitos.isEmpty &&
      obrigacoes.isEmpty;

  /// Prazo pelo `id` (as obrigações apontam para eles com `prazo_id`).
  Prazo? prazoPorId(String? id) {
    if (id == null) return null;
    for (final p in prazos) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Recebe o JSON do documento (com `analysis_json` dentro). Também aceita
  /// o `analysis_json` puro, caso a API devolva só ele.
  factory AnaliseDetalhe.fromJson(Map<String, dynamic> json) {
    final analise = json.containsKey('analysis_json') ? _mapa(json['analysis_json']) : json;
    final aderencia = analise['aderencia'] is Map<String, dynamic>
        ? Aderencia.fromJson(analise['aderencia'] as Map<String, dynamic>)
        : null;
    final metadados = _mapa(analise['metadados']);

    final documento = {
      'id': json['id'] ?? '',
      'filename': json['filename'] ?? 'Documento',
      'created_at': json['created_at'] ??
          metadados['analisado_em'] ??
          DateTime.now().toUtc().toIso8601String(),
      'doc_type': json['doc_type'],
      'status': json['status'] ?? 'ready',
      'score': json['score'] ?? aderencia?.score,
      'outcome': json['outcome'] ?? analise['outcome'],
    };

    final prazos = _lista(analise['prazos'], Prazo.fromJson);
    // Prazos com data primeiro (em ordem); os relativos mantêm a ordem da IA.
    final comData = prazos.where((p) => p.data != null).toList()
      ..sort((a, b) => a.data!.compareTo(b.data!));

    return AnaliseDetalhe(
      resumo: AnaliseResumo.fromJson(documento),
      textoResumo: _texto(analise['resumo']),
      papel: analise['papel_empresa'] is Map<String, dynamic>
          ? PapelEmpresa.fromJson(analise['papel_empresa'] as Map<String, dynamic>)
          : null,
      aderencia: aderencia,
      riscos: _lista(analise['riscos'], Risco.fromJson),
      prazos: [...comData, ...prazos.where((p) => p.data == null)],
      valores: _lista(analise['valores'], ValorFinanceiro.fromJson),
      requisitos: _lista(analise['requisitos'], Requisito.fromJson),
      obrigacoes: _lista(analise['obrigacoes'], Obrigacao.fromJson),
      // O papel da empresa não é mais perguntado; análises antigas ainda
      // podem trazer essa pergunta salva, então ela é descartada aqui.
      perguntas: _lista(analise['perguntas_pendentes'], PerguntaPendente.fromJson)
          .where((p) => p.pergunta.isNotEmpty && !p.sobrePapel)
          .toList(),
      analisadoEm: DateTime.tryParse(metadados['analisado_em']?.toString() ?? '')?.toLocal(),
      modelo: _texto(metadados['modelo']),
      schemaVersion: _inteiro(analise['schema_version']),
      desatualizada: json['analysis_desatualizada'] == true,
    );
  }
}

/// Trecho do documento que embasa um item, com a cláusula de origem.
class Evidencia {
  final String? trecho;
  final String? clausula;

  const Evidencia({this.trecho, this.clausula});

  bool get vazia => trecho == null && clausula == null;

  static Evidencia? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final e = Evidencia(trecho: _texto(json['trecho']), clausula: _texto(json['clausula']));
    return e.vazia ? null : e;
  }
}

/// Papel da empresa no documento (ex.: fornecedora = CONTRATADA).
class PapelEmpresa {
  final String papel;
  final String? justificativa;
  final Evidencia? evidencia;

  const PapelEmpresa({required this.papel, this.justificativa, this.evidencia});

  factory PapelEmpresa.fromJson(Map<String, dynamic> json) => PapelEmpresa(
        papel: _texto(json['papel']) ?? 'indefinido',
        justificativa: _texto(json['justificativa']),
        evidencia: Evidencia.fromJson(json['evidencia']),
      );

  /// Nome da parte no contrato que corresponde à empresa do usuário.
  String? get parteNoContrato => switch (papel.toLowerCase()) {
        'fornecedora' || 'fornecedor' || 'contratada' => 'CONTRATADA',
        'contratante' || 'cliente' => 'CONTRATANTE',
        _ => null,
      };

  /// "Fornecedora" (primeira letra maiúscula) para exibição.
  String get rotulo => papel.isEmpty ? papel : papel[0].toUpperCase() + papel.substring(1);
}

/// Números do Motor de Match.
class Aderencia {
  final int? score;
  final int? cobertura;
  final int total;
  final int avaliados;
  final int atendidos;
  final int parcialmenteAtendidos;
  final int naoAtendidos;
  final int desconhecidos;

  const Aderencia({
    this.score,
    this.cobertura,
    this.total = 0,
    this.avaliados = 0,
    this.atendidos = 0,
    this.parcialmenteAtendidos = 0,
    this.naoAtendidos = 0,
    this.desconhecidos = 0,
  });

  factory Aderencia.fromJson(Map<String, dynamic> json) => Aderencia(
        score: _inteiro(json['score']),
        cobertura: _inteiro(json['cobertura']),
        total: _inteiro(json['total']) ?? 0,
        avaliados: _inteiro(json['avaliados']) ?? 0,
        atendidos: _inteiro(json['atendidos']) ?? 0,
        parcialmenteAtendidos: _inteiro(json['parcialmente_atendidos']) ?? 0,
        naoAtendidos: _inteiro(json['nao_atendidos']) ?? 0,
        desconhecidos: _inteiro(json['desconhecidos']) ?? 0,
      );
}

enum Severidade {
  alta,
  media,
  baixa;

  /// Aceita os códigos em português da IA e os equivalentes em inglês.
  static Severidade fromCodigo(String? codigo) => switch (codigo?.toLowerCase()) {
        'alta' || 'high' || 'critica' || 'crítica' => alta,
        'baixa' || 'low' => baixa,
        _ => media,
      };
}

class Risco {
  final String descricao;
  final Severidade severidade;
  final String? impacto;
  final String? recomendacao;
  final Evidencia? evidencia;

  const Risco({
    required this.descricao,
    required this.severidade,
    this.impacto,
    this.recomendacao,
    this.evidencia,
  });

  factory Risco.fromJson(Map<String, dynamic> json) => Risco(
        descricao: _texto(json['descricao']) ?? 'Risco identificado',
        severidade: Severidade.fromCodigo(json['severidade'] as String?),
        impacto: _texto(json['impacto']),
        recomendacao: _texto(json['recomendacao']),
        evidencia: Evidencia.fromJson(json['evidencia']),
      );
}

class Prazo {
  final String? id;
  final String descricao;
  final DateTime? data;

  /// Quando não há data fixa: "em até 30 dias" + evento "assinatura".
  final String? prazoRelativo;
  final String? eventoReferencia;
  final Evidencia? evidencia;

  const Prazo({
    required this.descricao,
    this.id,
    this.data,
    this.prazoRelativo,
    this.eventoReferencia,
    this.evidencia,
  });

  /// "em até 30 dias após a assinatura", "12 meses a partir de assinatura"...
  String? get textoRelativo {
    if (prazoRelativo == null) return null;
    if (eventoReferencia == null) return prazoRelativo;
    return '$prazoRelativo (referência: $eventoReferencia)';
  }

  factory Prazo.fromJson(Map<String, dynamic> json) => Prazo(
        id: _texto(json['id']),
        descricao: _texto(json['descricao']) ?? 'Prazo',
        data: DateTime.tryParse(json['data']?.toString() ?? ''),
        prazoRelativo: _texto(json['prazo_relativo']),
        eventoReferencia: _texto(json['evento_referencia']),
        evidencia: Evidencia.fromJson(json['evidencia']),
      );
}

class ValorFinanceiro {
  final String descricao;

  /// valor_total, pagamento, multa, garantia...
  final String? categoria;
  final String? moeda;
  final double? montante;
  final double? percentual;
  final bool aproximado;
  final Evidencia? evidencia;

  const ValorFinanceiro({
    required this.descricao,
    this.categoria,
    this.moeda,
    this.montante,
    this.percentual,
    this.aproximado = false,
    this.evidencia,
  });

  bool get ehPenalidade => categoria == 'multa' || categoria == 'penalidade';

  factory ValorFinanceiro.fromJson(Map<String, dynamic> json) => ValorFinanceiro(
        descricao: _texto(json['descricao']) ?? 'Valor',
        categoria: _texto(json['categoria']),
        moeda: _texto(json['moeda']),
        montante: _decimal(json['montante']),
        percentual: _decimal(json['percentual']),
        aproximado: json['aproximado'] == true,
        evidencia: Evidencia.fromJson(json['evidencia']),
      );
}

enum StatusRequisito {
  atendido,
  parcialmenteAtendido,
  naoAtendido,
  indefinido;

  static StatusRequisito fromCodigo(String? codigo) => switch (codigo?.toLowerCase()) {
        'atende' || 'met' => atendido,
        'parcialmente_atende' || 'partially_met' => parcialmenteAtendido,
        'nao_atende' || 'não_atende' || 'not_met' => naoAtendido,
        _ => indefinido,
      };
}

class Requisito {
  final String? id;
  final String descricao;
  final bool obrigatorio;
  final StatusRequisito status;
  final String? justificativa;
  final Evidencia? evidencia;

  const Requisito({
    required this.descricao,
    required this.status,
    this.id,
    this.obrigatorio = false,
    this.justificativa,
    this.evidencia,
  });

  factory Requisito.fromJson(Map<String, dynamic> json) => Requisito(
        id: _texto(json['id']),
        descricao: _texto(json['descricao']) ?? 'Requisito',
        obrigatorio: json['obrigatorio'] == true,
        status: StatusRequisito.fromCodigo(json['resultado'] as String?),
        justificativa: _texto(json['justificativa']),
        evidencia: Evidencia.fromJson(json['evidencia']),
      );
}

class Obrigacao {
  final String descricao;

  /// Parte do contrato responsável: CONTRATADA, CONTRATANTE...
  final String? parteResponsavel;
  final String? prazoId;
  final Evidencia? evidencia;

  const Obrigacao({
    required this.descricao,
    this.parteResponsavel,
    this.prazoId,
    this.evidencia,
  });

  factory Obrigacao.fromJson(Map<String, dynamic> json) => Obrigacao(
        descricao: _texto(json['descricao']) ?? 'Obrigação',
        parteResponsavel: _texto(json['parte_responsavel'])?.toUpperCase(),
        prazoId: _texto(json['prazo_id']),
        evidencia: Evidencia.fromJson(json['evidencia']),
      );
}

/// Pergunta ativa da IA quando faltam dados no perfil
/// ("A empresa possui certificação ISO 27001?").
class PerguntaPendente {
  final String? id;
  final String pergunta;
  final List<String> requisitoIds;
  final String? fatoChave;

  /// v2: `company_fact` (fato da empresa) ou `cadastro`.
  final String? destino;
  final String? fatoRotulo;

  /// v2: booleano, inteiro, decimal, texto, data ou objeto.
  final String? tipoValor;

  /// Pergunta sobre o papel da empresa (contratante ou fornecedora), que só
  /// existe em análises antigas. Não é exibida.
  final bool sobrePapel;

  const PerguntaPendente({
    required this.pergunta,
    this.id,
    this.requisitoIds = const [],
    this.fatoChave,
    this.destino,
    this.fatoRotulo,
    this.tipoValor,
    this.sobrePapel = false,
  });

  /// O backend só aceita respostas para perguntas sobre fatos da empresa.
  bool get respondivel => id != null && destino == 'company_fact';

  /// Dica para o campo de resposta, conforme o tipo esperado.
  String get dicaResposta => switch (tipoValor) {
        'booleano' => 'Ex.: Sim, temos.',
        'data' => 'Ex.: 15/03/2020',
        'inteiro' || 'decimal' => 'Informe o número',
        _ => 'Sua resposta',
      };

  factory PerguntaPendente.fromJson(Map<String, dynamic> json) => PerguntaPendente(
        id: _texto(json['id']),
        pergunta: _texto(json['pergunta']) ?? '',
        requisitoIds: (json['requisito_ids'] as List? ?? const []).map((e) => '$e').toList(),
        fatoChave: _texto(json['fato_chave']),
        destino: _texto(json['destino']),
        fatoRotulo: _texto(json['fato_rotulo']),
        tipoValor: _texto(json['tipo_valor']),
        sobrePapel: json['sobre_papel'] == true || json['destino'] == 'papel',
      );
}

// ------------------------------------------------------------- helpers

Map<String, dynamic> _mapa(Object? valor) =>
    valor is Map<String, dynamic> ? valor : const <String, dynamic>{};

String? _texto(Object? valor) {
  final texto = valor?.toString().trim();
  return texto == null || texto.isEmpty ? null : texto;
}

int? _inteiro(Object? valor) => switch (valor) {
      final int n => n,
      final num n => n.round(),
      final String s => int.tryParse(s) ?? double.tryParse(s)?.round(),
      _ => null,
    };

/// A IA manda números como texto ("180000.00", "2").
double? _decimal(Object? valor) => switch (valor) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s.replaceAll(',', '.')),
      _ => null,
    };

/// Ignora itens que não são objetos, para um JSON malformado da IA
/// não derrubar a tela inteira.
List<T> _lista<T>(Object? valor, T Function(Map<String, dynamic>) item) {
  if (valor is! List) return [];
  return valor.whereType<Map<String, dynamic>>().map(item).toList();
}
