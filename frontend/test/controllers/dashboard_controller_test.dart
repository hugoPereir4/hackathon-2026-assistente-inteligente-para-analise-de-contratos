import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_frontend/controllers/dashboard_controller.dart';
import 'package:hackathon_frontend/core/network/api_exception.dart';
import 'package:hackathon_frontend/models/analise_resumo.dart';
import 'package:hackathon_frontend/models/arquivo_selecionado.dart';
import 'package:hackathon_frontend/models/usuario.dart';
import 'package:hackathon_frontend/services/auth_service.dart';
import 'package:hackathon_frontend/services/documento_service.dart';
import 'package:hackathon_frontend/services/seletor_arquivo_service.dart';

class _Documentos implements DocumentoService {
  final listagem = Completer<List<AnaliseResumo>>();
  int envios = 0;
  bool falhar = false;

  @override
  Future<List<AnaliseResumo>> listarRecentes() => listagem.future;

  @override
  Future<AnaliseResumo> enviar(
    ArquivoSelecionado arquivo, {
    TipoDocumento? tipo,
  }) async {
    envios++;
    if (falhar) throw const ApiException('Falha no envio');
    return AnaliseResumo(
      id: '$envios',
      nomeArquivo: arquivo.nome,
      enviadoEm: DateTime(2026),
      status: StatusAnalise.aguardando,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Seletor implements SeletorArquivoService {
  Completer<ArquivoSelecionado?> selecao = Completer();
  Completer<ArquivoSelecionado> arrastado = Completer();
  int selecoes = 0;
  int leituras = 0;

  @override
  Future<ArquivoSelecionado?> selecionarDocumento() {
    selecoes++;
    return selecao.future;
  }

  @override
  Future<ArquivoSelecionado> deXFile(XFile arquivo) {
    leituras++;
    return arrastado.future;
  }
}

class _Auth implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Documentos documentos;
  late _Seletor seletor;
  late DashboardController controller;
  final arquivo = ArquivoSelecionado(
    nome: 'contrato.pdf',
    tamanhoBytes: 8,
    lerBytes: () async => Uint8List.fromList([37, 80, 68, 70, 45]),
  );

  setUp(() {
    documentos = _Documentos();
    seletor = _Seletor();
    controller = DashboardController(
      documentos,
      seletor,
      _Auth(),
      const Usuario(
        id: 1,
        email: 'teste@example.com',
        cnpj: '12345678000195',
        confirmado: true,
      ),
    );
  });
  tearDown(() => controller.dispose());

  test('uma seleção pendente bloqueia outro seletor e o arrastar', () async {
    final primeiro = controller.selecionarArquivo();
    expect(await controller.selecionarArquivo(), isNull);
    expect(
      await controller.receberArquivosArrastados([XFile('contrato.pdf')]),
      isNull,
    );
    expect(seletor.selecoes, 1);
    expect(seletor.leituras, 0);
    seletor.selecao.complete(arquivo);
    expect(await primeiro, isNotNull);
    expect(documentos.envios, 1);
    expect(controller.enviando, isFalse);
  });

  test('ler um arquivo arrastado bloqueia outro envio', () async {
    final primeiro = controller.receberArquivosArrastados([
      XFile('contrato.pdf'),
    ]);
    expect(await controller.selecionarArquivo(), isNull);
    expect(
      await controller.receberArquivosArrastados([XFile('contrato.pdf')]),
      isNull,
    );
    expect(seletor.leituras, 1);
    seletor.arrastado.complete(arquivo);
    expect(await primeiro, isNotNull);
    expect(documentos.envios, 1);
  });

  test(
    'listagem iniciada antes do upload não apaga o novo documento',
    () async {
      final listagem = controller.carregarRecentes();
      seletor.selecao.complete(arquivo);
      final enviado = await controller.selecionarArquivo();
      documentos.listagem.complete([]);
      await listagem;
      expect(controller.recentes.map((a) => a.id), [enviado!.id]);
    },
  );

  test('listagem não duplica documento enviado enquanto carregava', () async {
    final listagem = controller.carregarRecentes();
    seletor.selecao.complete(arquivo);
    final enviado = await controller.selecionarArquivo();
    documentos.listagem.complete([enviado!]);
    await listagem;
    expect(controller.recentes.map((a) => a.id), [enviado.id]);
  });

  test(
    'cancelar ou falhar libera uma nova tentativa e limpa erro antigo',
    () async {
      seletor.selecao.complete(arquivo);
      documentos.falhar = true;
      expect(await controller.selecionarArquivo(), isNull);
      expect(controller.errorMessage, 'Falha no envio');
      expect(controller.enviando, isFalse);

      seletor.selecao = Completer()..complete(null);
      expect(await controller.selecionarArquivo(), isNull);
      expect(controller.errorMessage, isNull);

      documentos.falhar = false;
      seletor.selecao = Completer()..complete(arquivo);
      expect(await controller.selecionarArquivo(), isNotNull);
      expect(controller.enviando, isFalse);
    },
  );
}
