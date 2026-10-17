import 'dart:math';

import '../../core/network/api_exception.dart';
import '../../models/analise_detalhe.dart';
import '../../models/analise_resumo.dart';
import '../../models/arquivo_selecionado.dart';
import '../documento_service.dart';
import 'mock_analises.dart';
import 'mock_database.dart';

/// Documentos fake, com o mesmo fluxo da API: o upload deixa o documento
/// "uploaded" e [analisar] passa por "processing" até "ready".
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

  Map<String, dynamic> _documento(String id) => _documentos.firstWhere(
        (d) => d['id'].toString() == id,
        orElse: () => throw const ApiException('Recurso não encontrado.', statusCode: 404),
      );

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

    final documento = <String, dynamic>{
      'id': _db.novoId(),
      'doc_type': tipo?.codigo,
      'filename': arquivo.nome,
      'status': 'uploaded',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'score': null,
      'outcome': null,
    };
    _documentos.add(documento);
    return AnaliseResumo.fromJson(documento);
  }

  @override
  Future<AnaliseResumo> analisar(String id) async {
    final documento = _documento(id);
    if (documento['status'] != 'uploaded') {
      throw const ApiException(
        'O documento já foi analisado, está em processamento ou não existe.',
        statusCode: 409,
      );
    }
    documento['status'] = 'processing';
    await Future<void>.delayed(_tempoDeAnalise);

    final score = 40 + _random.nextInt(60);
    final docType = documento['doc_type'] as String? ??
        ((documento['filename'] as String).toLowerCase().contains('edital') ? 'tender' : 'contract');
    final analise = MockAnalises.gerar(docType: docType, score: score);
    documento
      ..['status'] = 'ready'
      ..['doc_type'] = docType
      ..['score'] = score
      ..['outcome'] = analise['outcome']
      ..['analysis_json'] = analise;
    return AnaliseResumo.fromJson(documento);
  }

  @override
  Future<AnaliseResumo> buscar(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return AnaliseResumo.fromJson(_documento(id));
  }

  @override
  Future<AnaliseDetalhe> buscarDetalhe(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return AnaliseDetalhe.fromJson(_documento(id));
  }
}
