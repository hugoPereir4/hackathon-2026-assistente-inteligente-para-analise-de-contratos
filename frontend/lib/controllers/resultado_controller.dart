import '../models/analise_detalhe.dart';
import '../models/analise_resumo.dart';
import '../services/documento_service.dart';
import 'base_controller.dart';

/// Controller do Painel de Resultados (Fase 3 do fluxograma).
class ResultadoController extends BaseController {
  final DocumentoService _documentoService;

  /// O que já se sabe pela lista (nome, data); mostrado enquanto o detalhe carrega.
  final AnaliseResumo analiseInicial;

  ResultadoController(this._documentoService, this.analiseInicial);

  AnaliseDetalhe? _detalhe;
  AnaliseDetalhe? get detalhe => _detalhe;

  AnaliseResumo get resumo => _detalhe?.resumo ?? analiseInicial;

  Future<void> carregar() async {
    await runAsync(() async {
      _detalhe = await _documentoService.buscarDetalhe(analiseInicial.id);
    });
  }
}
