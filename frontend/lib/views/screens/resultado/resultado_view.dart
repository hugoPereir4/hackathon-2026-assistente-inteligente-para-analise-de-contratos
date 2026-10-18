import 'package:flutter/widgets.dart';

import '../../../controllers/resultado_controller.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/analise_detalhe.dart';
import '../../../models/analise_resumo.dart';
import '../../components/components.dart';
import 'widgets/perguntas_pendentes_card.dart';
import 'widgets/obrigacoes_list.dart';
import 'widgets/prazos_list.dart';
import 'widgets/requisitos_list.dart';
import 'widgets/resultado_header.dart';
import 'widgets/riscos_list.dart';
import 'widgets/valores_list.dart';

/// Painel de Resultados: score de compatibilidade + resposta da IA formatada
/// (Fase 3 do fluxograma).
class ResultadoView extends StatefulWidget {
  final AnaliseResumo analise;

  const ResultadoView({super.key, required this.analise});

  @override
  State<ResultadoView> createState() => _ResultadoViewState();
}

class _ResultadoViewState extends State<ResultadoView> {
  static const _gap = SizedBox(height: 16);

  late final ResultadoController _controller =
      ResultadoController(AppDependencies.instance.documentoService, widget.analise);

  @override
  void initState() {
    super.initState();
    _controller.carregar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Resultado da análise',
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ResultadoHeader(
                    analise: _controller.resumo,
                    aderencia: _controller.detalhe?.aderencia,
                    papel: _controller.detalhe?.papel,
                  ),
                  _gap,
                  ..._conteudo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _conteudo() {
    final detalhe = _controller.detalhe;

    if (detalhe == null) {
      if (_controller.isLoading) {
        return const [
          Padding(padding: EdgeInsets.all(32), child: Center(child: AdaptiveLoading())),
        ];
      }
      return [
        _Aviso(
          mensagem: _controller.errorMessage ?? 'Não foi possível carregar o resultado.',
          acao: AdaptiveButton.secondary(
            label: 'Tentar novamente',
            expanded: false,
            onPressed: _controller.carregar,
          ),
        ),
      ];
    }

    final falhou = detalhe.resumo.status == StatusAnalise.erro;

    // Uma reanálise que falha preserva o resultado anterior: ele continua
    // na tela, com o aviso e o botão para tentar de novo.
    if (falhou && detalhe.vazio) {
      return const [_Aviso(mensagem: 'A análise deste documento falhou. Tente enviá-lo novamente.')];
    }

    if (!falhou && !detalhe.resumo.concluida) {
      return const [
        _Aviso(mensagem: 'A IA ainda está analisando este documento. Volte em instantes.'),
      ];
    }

    if (detalhe.vazio) {
      return const [_Aviso(mensagem: 'O resultado detalhado da IA ainda não está disponível.')];
    }

    return _secoes(detalhe);
  }

  /// Por que vale reanalisar este documento, se for o caso.
  String? _motivoParaReanalisar(AnaliseDetalhe d) {
    if (d.resumo.status == StatusAnalise.erro) {
      return 'A última análise falhou. O resultado abaixo é o anterior.';
    }
    if (d.versaoAntiga) {
      return 'Esta análise é de uma versão anterior. Reanalise para poder responder às perguntas da IA.';
    }
    if (d.desatualizada) {
      return 'Os dados da empresa mudaram depois desta análise.';
    }
    return null;
  }

  Future<void> _mostrarErro(String titulo) async {
    final erro = _controller.errorMessage;
    if (erro == null || !mounted) return;
    await AdaptiveDialog.showMessage(context, title: titulo, message: erro);
    _controller.clearError();
  }

  Future<void> _enviarRespostas() async {
    if (!await _controller.gerarPrevia()) await _mostrarErro('Não foi possível enviar');
  }

  Future<void> _confirmarRespostas() async {
    final confirmacao = await _controller.confirmar();
    if (!mounted) return;
    if (confirmacao == null) return _mostrarErro('Não foi possível salvar');
    await AdaptiveDialog.showMessage(
      context,
      title: confirmacao.reanaliseFalhou ? 'Respostas salvas' : 'Análise atualizada',
      message: confirmacao.reanaliseFalhou
          ? 'Suas respostas foram salvas no perfil, mas a reanálise falhou'
              '${confirmacao.erroReanalise == null ? '' : ': ${confirmacao.erroReanalise}'}. '
              'Tente reanalisar em instantes.'
          : 'Suas respostas foram salvas no perfil e o documento foi reanalisado.',
    );
  }

  Future<void> _reanalisar() async {
    if (!await _controller.reanalisar()) await _mostrarErro('Não foi possível reanalisar');
  }

  List<Widget> _secoes(AnaliseDetalhe d) {
    final motivo = _motivoParaReanalisar(d);
    final secoes = <Widget>[
      if (motivo != null)
        _Aviso(
          mensagem: motivo,
          acao: AdaptiveButton.secondary(
            label: 'Reanalisar',
            icon: AppIcons.refresh,
            expanded: false,
            isLoading: _controller.acao == AcaoResultado.reanalise,
            onPressed: _controller.ocupado ? null : _reanalisar,
          ),
        ),
      if (d.perguntas.isNotEmpty)
        PerguntasPendentesCard(
          detalhe: d,
          controller: _controller,
          onEnviar: _enviarRespostas,
          onConfirmar: _confirmarRespostas,
        ),
      if (d.textoResumo != null)
        AppSection(
          title: 'Resumo',
          icon: AppIcons.summary,
          child: Text(
            d.textoResumo!,
            style: const TextStyle(fontSize: 15, height: 1.55, color: AppColors.textPrimary),
          ),
        ),
      if (d.riscos.isNotEmpty)
        AppSection(
          title: 'Riscos e pontos de atenção',
          icon: AppIcons.warning,
          trailing: '${d.riscos.length}',
          child: RiscosList(riscos: d.riscos),
        ),
      if (d.requisitos.isNotEmpty)
        AppSection(
          title: 'Requisitos',
          icon: AppIcons.checklist,
          trailing: '${d.requisitosAtendidos} de ${d.requisitos.length} atendidos',
          child: RequisitosList(requisitos: d.requisitos),
        ),
      if (d.prazos.isNotEmpty)
        AppSection(
          title: 'Prazos',
          icon: AppIcons.calendar,
          child: PrazosList(prazos: d.prazos),
        ),
      if (d.valores.isNotEmpty)
        AppSection(
          title: 'Valores',
          icon: AppIcons.money,
          child: ValoresList(valores: d.valores),
        ),
      if (d.obrigacoes.isNotEmpty)
        AppSection(
          title: 'Obrigações',
          icon: AppIcons.obligations,
          child: ObrigacoesList(
            obrigacoes: d.obrigacoes,
            parteDaEmpresa: d.papel?.parteNoContrato,
            prazoPorId: d.prazoPorId,
          ),
        ),
      if (d.analisadoEm != null)
        AppText.caption(
          [
            'Analisado em ${Formatters.dataHora(d.analisadoEm!)}',
            if (d.modelo != null) 'modelo ${d.modelo}',
          ].join(' • '),
          textAlign: TextAlign.center,
        ),
    ];
    return [
      for (final (i, secao) in secoes.indexed) ...[if (i > 0) _gap, secao],
    ];
  }
}

/// Mensagem centralizada para estados sem conteúdo (erro, processando...).
class _Aviso extends StatelessWidget {
  final String mensagem;
  final Widget? acao;

  const _Aviso({required this.mensagem, this.acao});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AppText.body(mensagem, textAlign: TextAlign.center),
          if (acao != null) ...[const SizedBox(height: 16), acao!],
        ],
      ),
    );
  }
}
