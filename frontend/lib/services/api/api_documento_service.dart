import '../../core/network/api_client.dart';
import '../../models/analise_detalhe.dart';
import '../../models/analise_resumo.dart';
import '../../models/arquivo_selecionado.dart';
import '../../models/paginated.dart';
import '../documento_service.dart';

/// Documentos pela API Django.
///
///   GET  /documents/        -> página (10 por página, mais recentes primeiro)
///   POST /documents/        -> multipart: file (PDF até 10 MB) + doc_type opcional
///   GET  /documents/{id}/
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
  Future<AnaliseResumo> buscar(String id) async {
    final json = await _api.get('documents/$id/');
    return AnaliseResumo.fromJson(json as Map<String, dynamic>);
  }

  /// TODO(backend): o DocumentSerializer ainda não devolve `score`,
  /// `outcome` e `analysis_json`; enquanto isso a tela mostra "sem resultado".
  @override
  Future<AnaliseDetalhe> buscarDetalhe(String id) async {
    final json = await _api.get('documents/$id/');
    return AnaliseDetalhe.fromJson(json as Map<String, dynamic>);
  }
}
