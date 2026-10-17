import '../models/analise_detalhe.dart';
import '../models/analise_resumo.dart';
import '../models/arquivo_selecionado.dart';

/// Contrato de envio de documentos e consulta das análises.
abstract class DocumentoService {
  /// Documentos da empresa logada, do mais recente para o mais antigo.
  Future<List<AnaliseResumo>> listarRecentes();

  /// Envia o PDF. Retorna o documento criado (status inicial "uploaded").
  Future<AnaliseResumo> enviar(ArquivoSelecionado arquivo, {TipoDocumento? tipo});

  /// Estado atual de um documento (usado no polling).
  Future<AnaliseResumo> buscar(String id);

  /// Resultado completo da IA (score, resumo, riscos, prazos...).
  Future<AnaliseDetalhe> buscarDetalhe(String id);
}
