import 'dart:math';

import '../../core/network/api_exception.dart';
import '../../models/analise_detalhe.dart';
import '../../models/analise_resumo.dart';
import '../../models/arquivo_selecionado.dart';
import '../documento_service.dart';
import 'mock_analises.dart';
import 'mock_database.dart';

/// Documentos fake. Simula o processamento: o status vai de "uploaded"
/// para "ready" alguns segundos depois do envio.
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

    final id = _db.novoId();
    final documento = <String, dynamic>{
      'id': id,
      'doc_type': tipo?.codigo,
      'filename': arquivo.nome,
      'status': 'uploaded',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _documentos.add(documento);
    _db.prontoEm[id] = DateTime.now().add(_tempoDeAnalise);
    return AnaliseResumo.fromJson(documento);
  }

  @override
  Future<AnaliseResumo> buscar(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return AnaliseResumo.fromJson(_atualizado(id));
  }

  @override
  Future<AnaliseDetalhe> buscarDetalhe(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return AnaliseDetalhe.fromJson(_atualizado(id));
  }

  /// Busca o documento e, se o "tempo de análise" já passou, finaliza.
  Map<String, dynamic> _atualizado(String id) {
    final documento = _documentos.firstWhere(
      (d) => d['id'].toString() == id,
      orElse: () => throw const ApiException('Recurso não encontrado.', statusCode: 404),
    );
    final pronto = _db.prontoEm[documento['id']];
    if (documento['status'] != 'ready' && pronto != null && DateTime.now().isAfter(pronto)) {
      final score = 40 + _random.nextInt(60);
      documento
        ..['status'] = 'ready'
        ..['score'] = score
        ..['doc_type'] ??=
            (documento['filename'] as String).toLowerCase().contains('edital') ? 'tender' : 'contract';
      final analise = MockAnalises.gerar(docType: documento['doc_type'] as String, score: score);
      documento
        ..['analysis_json'] = analise
        ..['outcome'] = analise['outcome'];
    }
    return documento;
  }
}
