import '../models/analise_detalhe.dart';
import '../models/analise_resumo.dart';
import '../models/arquivo_selecionado.dart';
import '../models/lote_respostas.dart';

/// Contrato de envio de documentos e consulta das análises.
abstract class DocumentoService {
  /// Documentos da empresa logada, do mais recente para o mais antigo.
  Future<List<AnaliseResumo>> listarRecentes();

  /// Envia o PDF. Retorna o documento criado (status inicial "uploaded").
  /// O texto é extraído no upload; a análise precisa ser pedida em [analisar].
  Future<AnaliseResumo> enviar(ArquivoSelecionado arquivo, {TipoDocumento? tipo});

  /// Dispara a análise da IA e espera o resultado (pode levar até ~1 min).
  Future<AnaliseResumo> analisar(String id);

  /// Estado atual de um documento (usado no polling).
  Future<AnaliseResumo> buscar(String id);

  /// Resultado completo da IA (score, resumo, riscos, prazos...).
  Future<AnaliseDetalhe> buscarDetalhe(String id);

  /// Envia respostas às perguntas pendentes ([respostas]: pergunta_id → texto).
  /// A IA interpreta e devolve propostas de fatos; nada é gravado ainda.
  Future<LoteRespostas> previaRespostas(String id, Map<String, String> respostas);

  /// Grava as propostas [aprovadas] no perfil e reanalisa o documento.
  /// [autorizarSubstituicao]: propostas que trocam um fato já confirmado.
  Future<ConfirmacaoRespostas> confirmarRespostas(
    String id,
    String loteId, {
    required List<String> aprovadas,
    List<String> autorizarSubstituicao = const [],
  });

  /// Roda a IA de novo com o perfil atual (análise antiga, desatualizada ou que falhou).
  Future<AnaliseDetalhe> reanalisar(String id);
}
