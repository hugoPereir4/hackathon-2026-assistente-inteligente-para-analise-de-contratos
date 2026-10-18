import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/analise_detalhe.dart';
import '../../../components/components.dart';
import 'evidencia_view.dart';

/// Prazos do documento: os de data fixa com um "calendário" e quanto falta
/// (vermelho se venceu, amarelo se faltar até 7 dias); os relativos
/// ("em até 30 dias após a assinatura") com um ícone de relógio.
class PrazosList extends StatelessWidget {
  static const int _diasDeAlerta = 7;

  final List<Prazo> prazos;

  const PrazosList({super.key, required this.prazos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, prazo) in prazos.indexed) ...[
          if (i > 0) const _Divisor(),
          _linha(prazo),
        ],
      ],
    );
  }

  Widget _linha(Prazo prazo) {
    final data = prazo.data;
    final subtitulo = data != null ? Formatters.data(data) : prazo.textoRelativo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Calendario(data: data),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prazo.descricao,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  AppText.caption(subtitulo),
                ],
                EvidenciaView(evidencia: prazo.evidencia),
              ],
            ),
          ),
          if (data != null) ...[
            const SizedBox(width: 8),
            AppBadge(label: Formatters.prazoRelativo(data), color: _corDoPrazo(data)),
          ],
        ],
      ),
    );
  }

  Color _corDoPrazo(DateTime data) {
    final hoje = DateTime.now();
    final dias = DateTime(data.year, data.month, data.day)
        .difference(DateTime(hoje.year, hoje.month, hoje.day))
        .inDays;
    if (dias < 0) return AppColors.danger;
    if (dias <= _diasDeAlerta) return AppColors.warning;
    return AppColors.primaryLight;
  }
}

class _Calendario extends StatelessWidget {
  final DateTime? data;

  const _Calendario({required this.data});

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: d == null
          ? Icon(AppIcons.clock, size: 22, color: AppColors.primaryLight)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  d.day.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  Formatters.mesAbreviado(d).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
    );
  }
}

class _Divisor extends StatelessWidget {
  const _Divisor();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: AppColors.border.withValues(alpha: 0.6),
    );
  }
}
