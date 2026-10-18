import 'dart:async';

import 'package:cross_file/cross_file.dart';

import '../models/analise_resumo.dart';
import '../models/arquivo_selecionado.dart';
import '../core/network/api_exception.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/documento_service.dart';
import '../services/seletor_arquivo_service.dart';
import 'base_controller.dart';

/// Controller da página inicial: upload de documento + análises recentes
/// (Fase 2 do fluxograma).
class DashboardController extends BaseController {
  // 5 s por documento pendente fica bem abaixo do throttle do backend (50/min).
  static const Duration _intervaloPolling = Duration(seconds: 5);

  /// O backend ainda não processa os documentos (o status fica em
  /// "uploaded"); depois desse tempo o app para de perguntar.
  static const Duration _tempoMaximoPolling = Duration(minutes: 3);

  final DocumentoService _documentoService;
  final SeletorArquivoService _seletorArquivo;
  final AuthService _authService;
  final Usuario usuario;

  DashboardController(
    this._documentoService,
    this._seletorArquivo,
    this._authService,
    this.usuario,
  );

  List<AnaliseResumo> _recentes = [];
  List<AnaliseResumo> get recentes => List.unmodifiable(_recentes);

  bool carregandoRecentes = false;
  bool arrastandoArquivo = false;
  String? arquivoEmEnvio;
  Timer? _polling;
  DateTime? _pollingIniciadoEm;
  bool _atualizando = false;
  String? erroAoCarregar;

  bool get enviando => arquivoEmEnvio != null;

  Future<void> carregarRecentes() async {
    carregandoRecentes = true;
    erroAoCarregar = null;
    notify();
    try {
      _recentes = await _documentoService.listarRecentes();
      _iniciarPollingSeNecessario();
    } on ApiException catch (e) {
      erroAoCarregar = e.message;
    } catch (_) {
      erroAoCarregar = 'Não foi possível carregar as análises recentes.';
    } finally {
      carregandoRecentes = false;
      notify();
    }
  }

  void definirArrastando(bool valor) {
    if (arrastandoArquivo == valor) return;
    arrastandoArquivo = valor;
    notify();
  }

  /// Abre o seletor de arquivos e envia. Retorna o documento criado, ou
  /// `null` se o usuário cancelou ou houve erro (veja [errorMessage]).
  Future<AnaliseResumo?> selecionarArquivo() async {
    if (enviando) return null;
    final ArquivoSelecionado? arquivo;
    try {
      arquivo = await _seletorArquivo.selecionarDocumento();
    } catch (_) {
      setError('Não foi possível abrir o seletor de arquivos.');
      return null;
    }
    if (arquivo == null) return null; // usuário cancelou
    return _enviar(arquivo);
  }

  /// Recebe arquivos soltos na zona de upload (web/desktop). Usa só o primeiro.
  Future<AnaliseResumo?> receberArquivosArrastados(List<XFile> arquivos) async {
    definirArrastando(false);
    if (enviando || arquivos.isEmpty) return null;
    final ArquivoSelecionado arquivo;
    try {
      arquivo = await _seletorArquivo.deXFile(arquivos.first);
    } catch (_) {
      setError('Não foi possível ler o arquivo arrastado.');
      return null;
    }
    return _enviar(arquivo);
  }

  Future<AnaliseResumo?> _enviar(ArquivoSelecionado arquivo) async {
    if (!arquivo.extensaoValida) {
      setError('Formato não suportado. Envie um arquivo PDF.');
      return null;
    }
    if (!arquivo.tamanhoValido) {
      setError('O arquivo precisa ter no máximo ${ArquivoSelecionado.tamanhoMaximoMb} MB.');
      return null;
    }

    arquivoEmEnvio = arquivo.nome;
    AnaliseResumo? enviada;
    await runAsync(() async {
      enviada = await _documentoService.enviar(arquivo);
      _recentes = [enviada!, ..._recentes];
    });
    arquivoEmEnvio = null;
    notify();
    return enviada;
  }

  /// Pede a análise da IA e espera o resultado (até ~1 min).
  /// Retorna a mensagem de erro, ou `null` se deu certo.
  Future<String?> analisar(AnaliseResumo analise) async {
    _substituir(analise.copyWith(status: StatusAnalise.processando));
    try {
      _substituir(await _documentoService.analisar(analise.id));
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 409 || e.statusCode == null) {
        // 409: já está sendo analisado. Sem status: timeout/conexão; o
        // backend pode continuar processando. Nos dois casos, acompanha.
        _iniciarPollingSeNecessario();
        return e.statusCode == null ? e.message : null;
      }
      _substituir(analise.copyWith(status: StatusAnalise.erro));
      return e.message;
    } catch (_) {
      _substituir(analise.copyWith(status: StatusAnalise.erro));
      return 'Não foi possível concluir a análise.';
    }
  }

  void _substituir(AnaliseResumo atualizada) {
    _recentes = [for (final a in _recentes) a.id == atualizada.id ? atualizada : a];
    notify();
  }

  /// Enquanto houver análise "processando", consulta o backend periodicamente.
  void _iniciarPollingSeNecessario() {
    final temPendente = _recentes.any((a) => a.status == StatusAnalise.processando);
    _pollingIniciadoEm = DateTime.now();
    if (!temPendente || _polling != null) return;
    _polling = Timer.periodic(_intervaloPolling, (_) => _atualizarPendentes());
  }

  void _pararPolling() {
    _polling?.cancel();
    _polling = null;
  }

  Future<void> _atualizarPendentes() async {
    if (_atualizando) return; // a rodada anterior ainda não terminou
    final pendentes = _recentes.where((a) => a.status == StatusAnalise.processando).toList();
    final esgotou = DateTime.now().difference(_pollingIniciadoEm!) > _tempoMaximoPolling;
    if (pendentes.isEmpty || esgotou) {
      _pararPolling();
      return;
    }
    _atualizando = true;
    for (final analise in pendentes) {
      try {
        _substituir(await _documentoService.buscar(analise.id));
      } catch (_) {
        // Tenta de novo no próximo ciclo.
      }
    }
    _atualizando = false;
    notify();
  }

  /// Encerra a sessão (no backend, invalida o refresh token).
  Future<void> sair() async {
    _pararPolling();
    await _authService.logout();
  }

  @override
  void dispose() {
    _pararPolling();
    super.dispose();
  }
}
