import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/analise_detalhe.dart';
import '../../../components/components.dart';
import '../../../shared/match_style.dart';
import 'evidencia_view.dart';

/// Valores financeiros: descrição e categoria à esquerda, valor formatado
/// à direita (moeda ou percentual; multas em vermelho; "≈" se aproximado).
class ValoresList extends StatelessWidget {
  final List<ValorFinanceiro> valores;

  const ValoresList({super.key, required this.valores});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, v) in valores.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.descricao,
                        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                      ),
                      if (v.categoria != null) ...[
                        const SizedBox(height: 4),
                        AppBadge(
                          label: MatchStyle.rotuloDaCategoria(v.categoria!),
                          color: v.ehPenalidade ? AppColors.danger : AppColors.primaryLight,
                        ),
                      ],
                      EvidenciaView(evidencia: v.evidencia),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _valorFormatado(v),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _corDoValor(v),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _valorFormatado(ValorFinanceiro v) {
    final prefixo = v.aproximado ? '≈ ' : '';
    if (v.montante != null) {
      return '$prefixo${Formatters.moeda(v.montante!, moeda: v.moeda ?? 'BRL')}';
    }
    if (v.percentual != null) return '$prefixo${Formatters.percentual(v.percentual!)}';
    return 'Não informado';
  }

  Color _corDoValor(ValorFinanceiro v) {
    if (v.montante == null && v.percentual == null) return AppColors.textSecondary;
    return v.ehPenalidade ? AppColors.danger : AppColors.textPrimary;
  }
}
