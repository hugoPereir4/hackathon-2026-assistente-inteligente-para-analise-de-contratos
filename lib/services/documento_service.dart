import 'dart:math';

import '../models/analise_resumo.dart';
import '../models/arquivo_selecionado.dart';

/// Contrato de envio de documentos e consulta das análises.
abstract class DocumentoService {
  Future<List<AnaliseResumo>> listarRecentes();

  /// Envia o arquivo para o backend, que extrai o texto e dispara a IA.
  /// Retorna a análise já criada, normalmente com status "processando".
  Future<AnaliseResumo> enviar(ArquivoSelecionado arquivo);

  /// Consulta o estado atual de uma análise (usado para polling).
  Future<AnaliseResumo> buscar(String id);
}

class MockDocumentoService implements DocumentoService {
  final _random = Random();
  final Map<String, AnaliseResumo> _analises = {
    '1': AnaliseResumo(
      id: '1',
      nomeArquivo: 'Contrato_Prestacao_Servicos_V2.pdf',
      enviadoEm: DateTime.now().subtract(const Duration(days: 2)),
      categoria: 'B2B Comercial',
      status: StatusAnalise.concluida,
      matchScore: 92,
    ),
    '2': AnaliseResumo(
      id: '2',
      nomeArquivo: 'Edital_Pregao_045_2026.pdf',
      enviadoEm: DateTime.now().subtract(const Duration(days: 5)),
      categoria: 'Licitação Pública',
      status: StatusAnalise.concluida,
      matchScore: 48,
    ),
  };
  final Map<String, DateTime> _prontoEm = {};

  @override
  Future<List<AnaliseResumo>> listarRecentes() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final lista = _analises.values.toList()
      ..sort((a, b) => b.enviadoEm.compareTo(a.enviadoEm));
    return lista;
  }

  @override
  Future<AnaliseResumo> enviar(ArquivoSelecionado arquivo) async {
    await arquivo.lerBytes(); // simula a leitura/upload do conteúdo
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final analise = AnaliseResumo(
      id: id,
      nomeArquivo: arquivo.nome,
      enviadoEm: DateTime.now(),
      status: StatusAnalise.processando,
    );
    _analises[id] = analise;
    _prontoEm[id] = DateTime.now().add(const Duration(seconds: 4));
    return analise;
  }

  @override
  Future<AnaliseResumo> buscar(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final atual = _analises[id]!;
    final pronto = _prontoEm[id];
    if (atual.status == StatusAnalise.processando &&
        pronto != null &&
        DateTime.now().isAfter(pronto)) {
      _analises[id] = atual.copyWith(
        status: StatusAnalise.concluida,
        matchScore: 40 + _random.nextInt(60),
        categoria: atual.nomeArquivo.toLowerCase().contains('edital')
            ? 'Licitação Pública'
            : 'B2B Comercial',
      );
    }
    return _analises[id]!;
  }
}
