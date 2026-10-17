import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/analise_detalhe.dart';
import '../../../../models/analise_resumo.dart';
import '../../../components/components.dart';
import '../../../shared/match_style.dart';

/// Topo do painel: medidor de compatibilidade, selo do resultado,
/// veredito, números da aderência, papel da empresa e dados do arquivo.
class ResultadoHeader extends StatelessWidget {
  static const double _larguraLado = 520;

  final AnaliseResumo analise;
  final Aderencia? aderencia;
  final PapelEmpresa? papel;

  const ResultadoHeader({super.key, required this.analise, this.aderencia, this.papel});

  @override
  Widget build(BuildContext context) {
    final score = analise.matchScore;
    final gauge = ScoreGauge(score: score, color: MatchStyle.corDoScore(score));

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ladoALado = constraints.maxWidth >= _larguraLado;
          final info = _info(centralizado: !ladoALado);
          if (ladoALado) {
            return Row(children: [gauge, const SizedBox(width: 28), Expanded(child: info)]);
          }
          return Column(children: [gauge, const SizedBox(height: 20), info]);
        },
      ),
    );
  }

  Widget _info({required bool centralizado}) {
    final alinhamento = centralizado ? TextAlign.center : TextAlign.start;
    final eixo = centralizado ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final resultado = analise.resultado;
    final detalhes = [
      if (analise.categoria != null) analise.categoria!,
      'Enviado em ${Formatters.data(analise.enviadoEm)}',
    ].join(' • ');

    return Column(
      crossAxisAlignment: eixo,
      children: [
        Text(
          'COMPATIBILIDADE COM O PERFIL',
          textAlign: alinhamento,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppColors.textSecondary,
          ),
        ),
        if (resultado != null) ...[
          const SizedBox(height: 10),
          AppBadge(
            label: MatchStyle.rotuloDoResultado(resultado),
            color: MatchStyle.corDoResultado(resultado),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          MatchStyle.veredito(resultado: resultado, score: analise.matchScore),
          textAlign: alinhamento,
          style: const TextStyle(fontSize: 16, height: 1.4, color: AppColors.textPrimary),
        ),
        if (aderencia != null && aderencia!.total > 0) ...[
          const SizedBox(height: 14),
          _Numeros(aderencia: aderencia!, centralizado: centralizado),
        ],
        const SizedBox(height: 16),
        if (papel?.parteNoContrato != null) ...[
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Sua empresa: '),
                TextSpan(
                  text: '${papel!.rotulo} (${papel!.parteNoContrato})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            textAlign: alinhamento,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          analise.nomeArquivo,
          textAlign: alinhamento,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        AppText.caption(detalhes, textAlign: alinhamento),
      ],
    );
  }
}

/// "2 atendidos · 1 não atendido · 1 sem informação" + cobertura.
class _Numeros extends StatelessWidget {
  final Aderencia aderencia;
  final bool centralizado;

  const _Numeros({required this.aderencia, required this.centralizado});

  @override
  Widget build(BuildContext context) {
    final a = aderencia;
    return Column(
      crossAxisAlignment: centralizado ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: centralizado ? WrapAlignment.center : WrapAlignment.start,
          spacing: 8,
          runSpacing: 6,
          children: [
            AppBadge(label: '${a.atendidos} atendidos', color: AppColors.success),
            if (a.naoAtendidos > 0)
              AppBadge(
                label: '${a.naoAtendidos} não ${a.naoAtendidos == 1 ? 'atendido' : 'atendidos'}',
                color: AppColors.danger,
              ),
            if (a.desconhecidos > 0)
              AppBadge(label: '${a.desconhecidos} sem informação', color: AppColors.textSecondary),
          ],
        ),
        if (a.cobertura != null) ...[
          const SizedBox(height: 6),
          AppText.caption(
            'A IA conseguiu avaliar ${a.avaliados} de ${a.total} requisitos '
            '(cobertura de ${a.cobertura}%).',
            textAlign: centralizado ? TextAlign.center : TextAlign.start,
          ),
        ],
      ],
    );
  }
}
