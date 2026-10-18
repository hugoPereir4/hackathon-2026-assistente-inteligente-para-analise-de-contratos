import 'package:flutter/widgets.dart';

import '../../../../controllers/resultado_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../models/analise_detalhe.dart';
import '../../../../models/lote_respostas.dart';
import '../../../components/components.dart';

/// Perguntas da IA quando faltam dados no perfil ("Faltam dados no perfil"
/// no fluxograma). O usuário responde, revisa como a IA entendeu e confirma;
/// o backend grava os fatos e reanalisa o documento.
class PerguntasPendentesCard extends StatelessWidget {
  final AnaliseDetalhe detalhe;
  final ResultadoController controller;
  final VoidCallback onEnviar;
  final VoidCallback onConfirmar;

  const PerguntasPendentesCard({
    super.key,
    required this.detalhe,
    required this.controller,
    required this.onEnviar,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final lote = controller.lote;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(AppIcons.question, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lote == null ? 'A IA precisa de mais informações' : 'Confira como a IA entendeu',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppText.caption(
            lote == null
                ? 'Com essas respostas no perfil, o score fica mais preciso.'
                : 'Marque o que estiver certo. Só o que for marcado é salvo no perfil da empresa.',
          ),
          const SizedBox(height: 16),
          if (lote == null) ..._perguntas() else ..._propostas(lote),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- 1. responder

  List<Widget> _perguntas() {
    final respondiveis = detalhe.perguntasRespondiveis;
    final outras = detalhe.perguntas.where((p) => !respondiveis.contains(p)).toList();
    return [
      for (final p in respondiveis) ...[
        _TextoPergunta(p.pergunta),
        const SizedBox(height: 8),
        AdaptiveTextField(
          controller: controller.respostaDe(p),
          label: p.fatoRotulo ?? 'Resposta',
          placeholder: p.dicaResposta,
          enabled: !controller.ocupado,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
      ],
      if (outras.isNotEmpty) ...[
        if (respondiveis.isNotEmpty)
          const AppText.caption('Estas dependem dos dados cadastrais ou do papel da empresa:'),
        const SizedBox(height: 8),
        BulletList(itens: [for (final p in outras) p.pergunta]),
        const SizedBox(height: 16),
      ],
      if (respondiveis.isNotEmpty)
        AdaptiveButton(
          label: 'Enviar respostas',
          isLoading: controller.acao == AcaoResultado.previa,
          onPressed: controller.ocupado ? null : onEnviar,
        ),
    ];
  }

  // ------------------------------------------------------------ 2. revisar

  List<Widget> _propostas(LoteRespostas lote) {
    return [
      for (final p in lote.propostas) ...[
        _PropostaTile(
          proposta: p,
          aprovada: controller.aprovada(p.id),
          onTap: controller.ocupado ? null : () => controller.alternarAprovacao(p),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 6),
      AdaptiveButton(
        label: 'Salvar e reanalisar',
        isLoading: controller.acao == AcaoResultado.confirmacao,
        onPressed: controller.ocupado ? null : onConfirmar,
      ),
      const SizedBox(height: 10),
      AdaptiveButton.secondary(
        label: 'Editar respostas',
        onPressed: controller.ocupado ? null : controller.editarRespostas,
      ),
      if (controller.acao == AcaoResultado.confirmacao) ...[
        const SizedBox(height: 10),
        const AppText.caption(
          'A IA está reanalisando o documento. Isso pode levar até um minuto.',
          textAlign: TextAlign.center,
        ),
      ],
    ];
  }
}

class _TextoPergunta extends StatelessWidget {
  final String texto;

  const _TextoPergunta(this.texto);

  @override
  Widget build(BuildContext context) => Text(
        texto,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: AppColors.textPrimary,
        ),
      );
}

/// Uma proposta da IA, marcável. Respostas vagas aparecem bloqueadas
/// com a pergunta de esclarecimento.
class _PropostaTile extends StatelessWidget {
  final PropostaResposta proposta;
  final bool aprovada;
  final VoidCallback? onTap;

  const _PropostaTile({required this.proposta, required this.aprovada, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = proposta;
    final cor = !p.suficiente
        ? AppColors.warning
        : aprovada
            ? AppColors.success
            : AppColors.border;
    return GestureDetector(
      onTap: p.suficiente ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cor, width: aprovada ? 1.5 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              !p.suficiente
                  ? AppIcons.helpCircle
                  : aprovada
                      ? AppIcons.checkCircle
                      : AppIcons.emptyCircle,
              color: p.suficiente && !aprovada ? AppColors.textSecondary : cor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TextoPergunta(p.rotulo),
                  const SizedBox(height: 6),
                  AppText.caption('Sua resposta: "${p.textoOriginal}"'),
                  const SizedBox(height: 4),
                  if (p.suficiente)
                    Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'Será salvo: '),
                        TextSpan(
                          text: p.valorPropostoFormatado,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ]),
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    )
                  else
                    Text(
                      p.esclarecimento ?? 'A resposta não ficou clara. Edite e envie de novo.',
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                  if (p.exigeAutorizacaoSubstituicao && p.valorAnteriorFormatado != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Substitui o valor confirmado anterior: ${p.valorAnteriorFormatado}',
                      style: const TextStyle(fontSize: 13, color: AppColors.danger),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
