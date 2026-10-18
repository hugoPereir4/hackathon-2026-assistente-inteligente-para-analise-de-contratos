import 'package:flutter/widgets.dart';

import '../../../controllers/dashboard_controller.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../models/analise_resumo.dart';
import '../../../models/usuario.dart';
import '../../components/components.dart';
import 'widgets/analise_recente_tile.dart';
import 'widgets/upload_drop_zone.dart';

/// Página inicial: upload de documento + análises recentes (Fase 2 do fluxograma).
class DashboardView extends StatefulWidget {
  final Usuario usuario;

  const DashboardView({super.key, required this.usuario});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final DashboardController _controller = DashboardController(
    AppDependencies.instance.documentoService,
    AppDependencies.instance.seletorArquivoService,
    AppDependencies.instance.authService,
    widget.usuario,
  );

  @override
  void initState() {
    super.initState();
    _controller.carregarRecentes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Upload e, em seguida, a análise da IA (o backend não analisa sozinho).
  Future<void> _tratarResultadoDoEnvio(Future<AnaliseResumo?> envio) async {
    final enviada = await envio;
    if (!mounted) return;
    if (enviada == null) {
      final erro = _controller.errorMessage;
      if (erro == null) return; // usuário cancelou
      _controller.clearError();
      await AdaptiveDialog.showMessage(context, title: 'Não foi possível enviar', message: erro);
      return;
    }
    await _analisar(enviada);
  }

  Future<void> _analisar(AnaliseResumo analise) async {
    final erro = await _controller.analisar(analise);
    if (erro == null || !mounted) return;
    await AdaptiveDialog.showMessage(context, title: 'A análise não foi concluída', message: erro);
  }

  Future<void> _abrirAnalise(AnaliseResumo analise) async {
    switch (analise.status) {
      case StatusAnalise.concluida:
        await Navigator.of(context).pushNamed(AppRoutes.resultado, arguments: analise);
      case StatusAnalise.aguardando:
        final confirmou = await AdaptiveDialog.showConfirm(
          context,
          title: 'Analisar documento',
          message: 'Este documento ainda não foi analisado. Deseja analisar agora?',
          confirmLabel: 'Analisar',
        );
        if (confirmou && mounted) await _analisar(analise);
      case StatusAnalise.erro:
        final repetir = await AdaptiveDialog.showConfirm(
          context,
          title: 'Análise com erro',
          message: 'O documento já foi enviado. Deseja tentar a análise novamente?',
          confirmLabel: 'Tentar novamente',
        );
        if (repetir && mounted) await _analisar(analise);
      case StatusAnalise.processando:
        break;
    }
  }

  Future<void> _sair() async {
    final confirmou = await AdaptiveDialog.showConfirm(
      context,
      title: 'Sair',
      message: 'Deseja encerrar a sessão?',
      confirmLabel: 'Sair',
    );
    if (!confirmou) return;
    await _controller.sair();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Início',
      showBackButton: false,
      actions: [
        GestureDetector(
          onTap: _sair,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(AppIcons.logout, color: const Color(0xFFFFFFFF)),
          ),
        ),
      ],
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppText.title('Análise de Novo Documento'),
                  const SizedBox(height: 6),
                  const AppText.body(
                    'Faça o upload do edital ou contrato. Nossa IA cruzará as exigências '
                    'com o DNA da sua empresa.',
                  ),
                  const SizedBox(height: 28),
                  UploadDropZone(
                    arrastando: _controller.arrastandoArquivo,
                    arquivoEmEnvio: _controller.arquivoEmEnvio,
                    onSelecionar: () => _tratarResultadoDoEnvio(_controller.selecionarArquivo()),
                    onArrastandoChanged: _controller.definirArrastando,
                    onArquivosSoltos: (arquivos) =>
                        _tratarResultadoDoEnvio(_controller.receberArquivosArrastados(arquivos)),
                  ),
                  const SizedBox(height: 40),
                  const _SectionLabel('Análises recentes'),
                  const SizedBox(height: 12),
                  _listaRecentes(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _listaRecentes() {
    if (_controller.carregandoRecentes && _controller.recentes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: AdaptiveLoading()),
      );
    }
    if (_controller.erroAoCarregar != null && _controller.recentes.isEmpty) {
      return AppCard(
        child: Column(
          children: [
            AppText.caption(_controller.erroAoCarregar!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            AdaptiveButton.secondary(
              label: 'Tentar novamente',
              expanded: false,
              onPressed: _controller.carregarRecentes,
            ),
          ],
        ),
      );
    }
    if (_controller.recentes.isEmpty) {
      return const AppCard(
        child: AppText.caption(
          'Nenhum documento analisado ainda. Envie o primeiro acima.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      children: [
        for (final analise in _controller.recentes)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnaliseRecenteTile(
              key: ValueKey(analise.id),
              analise: analise,
              onTap: () => _abrirAnalise(analise),
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: AppColors.textSecondary,
      ),
    );
  }
}
