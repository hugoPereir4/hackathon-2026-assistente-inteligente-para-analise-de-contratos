import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/analise_detalhe.dart';
import '../../../../models/analise_resumo.dart';
import '../../../components/components.dart';
import '../../../shared/match_style.dart';

/// Topo do painel: arquivo analisado e, abaixo, o medidor de compatibilidade
/// com o selo do resultado, o veredito e os números da aderência.
///
/// Lado a lado quando há espaço (tablet/desktop); empilhado e centralizado
/// no celular.
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
          final centralizado = !ladoALado;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Arquivo(analise: analise, papel: papel, centralizado: centralizado),
              const SizedBox(height: 16),
              Container(height: 1, color: AppColors.border.withValues(alpha: 0.6)),
              const SizedBox(height: 20),
              if (ladoALado)
                Row(
                  children: [
                    gauge,
                    const SizedBox(width: 28),
                    Expanded(child: _Compatibilidade(analise: analise, aderencia: aderencia)),
                  ],
                )
              else ...[
                Center(child: gauge),
                const SizedBox(height: 20),
                _Compatibilidade(analise: analise, aderencia: aderencia, centralizado: true),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Nome do arquivo + "Contrato • Fornecedora (CONTRATADA) • Enviado em 12/10/2026".
class _Arquivo extends StatelessWidget {
  final AnaliseResumo analise;
  final PapelEmpresa? papel;
  final bool centralizado;

  const _Arquivo({required this.analise, required this.papel, required this.centralizado});

  @override
  Widget build(BuildContext context) {
    final alinhamento = centralizado ? TextAlign.center : TextAlign.start;
    final detalhes = [
      if (analise.categoria != null) analise.categoria!,
      if (papel?.parteNoContrato != null) '${papel!.rotulo} (${papel!.parteNoContrato})',
      'Enviado em ${Formatters.data(analise.enviadoEm)}',
    ].join(' • ');

    return Column(
      crossAxisAlignment: centralizado ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          analise.nomeArquivo,
          textAlign: alinhamento,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        AppText.caption(detalhes, textAlign: alinhamento),
      ],
    );
  }
}

/// Selo do resultado, veredito e "3 atendidos · 2 não atendidos".
class _Compatibilidade extends StatelessWidget {
  final AnaliseResumo analise;
  final Aderencia? aderencia;
  final bool centralizado;

  const _Compatibilidade({required this.analise, this.aderencia, this.centralizado = false});

  @override
  Widget build(BuildContext context) {
    final resultado = analise.resultado;
    final a = aderencia;
    return Column(
      crossAxisAlignment: centralizado ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const Text(
          'COMPATIBILIDADE COM O PERFIL',
          style: TextStyle(
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
          textAlign: centralizado ? TextAlign.center : TextAlign.start,
          style: const TextStyle(fontSize: 16, height: 1.4, color: AppColors.textPrimary),
        ),
        if (a != null && a.total > 0) ...[
          const SizedBox(height: 14),
          Wrap(
            alignment: centralizado ? WrapAlignment.center : WrapAlignment.start,
            spacing: 8,
            runSpacing: 6,
            children: [
              AppBadge(
                label: '${a.atendidos} ${a.atendidos == 1 ? 'atendido' : 'atendidos'}',
                color: AppColors.success,
              ),
              if (a.parcialmenteAtendidos > 0)
                AppBadge(
                  label: '${a.parcialmenteAtendidos} parcialmente '
                      '${a.parcialmenteAtendidos == 1 ? 'atendido' : 'atendidos'}',
                  color: AppColors.warning,
                ),
              if (a.naoAtendidos > 0)
                AppBadge(
                  label: '${a.naoAtendidos} não ${a.naoAtendidos == 1 ? 'atendido' : 'atendidos'}',
                  color: AppColors.danger,
                ),
              if (a.desconhecidos > 0)
                AppBadge(label: '${a.desconhecidos} sem informação', color: AppColors.textSecondary),
            ],
          ),
        ],
      ],
    );
  }
}
