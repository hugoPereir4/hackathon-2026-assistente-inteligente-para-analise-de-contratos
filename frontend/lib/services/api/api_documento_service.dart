import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/analise_detalhe.dart';
import '../../models/analise_resumo.dart';
import '../../models/arquivo_selecionado.dart';
import '../../models/lote_respostas.dart';
import '../../models/paginated.dart';
import '../documento_service.dart';

/// Documentos pela API Django.
///
///   GET  /documents/        -> página (10 por página, mais recentes primeiro)
///   POST /documents/              -> multipart: file (PDF até 10 MB) + doc_type opcional
///   POST /documents/{id}/analyze/ -> roda a IA (síncrono) e devolve o detalhe
///   GET  /documents/{id}/         -> detalhe com analysis_json
///   POST /documents/{id}/answers/preview/          -> IA interpreta as respostas (lote)
///   POST /documents/{id}/answers/{lote}/confirm/   -> grava os fatos e reanalisa
///   POST /documents/{id}/reanalyze/                -> reanalisa com o perfil atual
class ApiDocumentoService implements DocumentoService {
  final ApiClient _api;

  ApiDocumentoService(this._api);

  @override
  Future<List<AnaliseResumo>> listarRecentes() async {
    final json = await _api.get('documents/') as Map<String, dynamic>;
    return Paginated.fromJson(json, AnaliseResumo.fromJson).results;
  }

  @override
  Future<AnaliseResumo> enviar(ArquivoSelecionado arquivo, {TipoDocumento? tipo}) async {
    final json = await _api.postMultipart(
      'documents/',
      campoArquivo: 'file',
      nomeArquivo: arquivo.nome,
      bytes: await arquivo.lerBytes(),
      campos: {if (tipo != null) 'doc_type': tipo.codigo},
    );
    return AnaliseResumo.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<AnaliseResumo> analisar(String id) async {
    final json = await _api.post('documents/$id/analyze/', timeout: AppConfig.analysisTimeout);
    return AnaliseResumo.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<AnaliseResumo> buscar(String id) async {
    final json = await _api.get('documents/$id/');
    return AnaliseResumo.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<AnaliseDetalhe> buscarDetalhe(String id) async {
    final json = await _api.get('documents/$id/');
    return AnaliseDetalhe.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<LoteRespostas> previaRespostas(String id, Map<String, String> respostas) async {
    final json = await _api.post(
      'documents/$id/answers/preview/',
      body: {
        'respostas': [
          for (final r in respostas.entries) {'pergunta_id': r.key, 'texto': r.value},
        ],
      },
      timeout: AppConfig.analysisTimeout, // a IA interpreta as respostas
    );
    return LoteRespostas.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<ConfirmacaoRespostas> confirmarRespostas(
    String id,
    String loteId, {
    required List<String> aprovadas,
    List<String> autorizarSubstituicao = const [],
  }) async {
    final json = await _api.post(
      'documents/$id/answers/$loteId/confirm/',
      body: {'propostas_aprovadas': aprovadas, 'autorizar_substituicao': autorizarSubstituicao},
      timeout: AppConfig.analysisTimeout, // grava os fatos e reanalisa na mesma chamada
    );
    return ConfirmacaoRespostas.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<AnaliseDetalhe> reanalisar(String id) async {
    final json = await _api.post('documents/$id/reanalyze/', timeout: AppConfig.analysisTimeout);
    return AnaliseDetalhe.fromJson(json as Map<String, dynamic>);
  }
}
