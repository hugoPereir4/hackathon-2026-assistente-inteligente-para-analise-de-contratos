import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../models/analise_detalhe.dart';
import '../../../components/components.dart';
import '../../../shared/match_style.dart';
import 'evidencia_view.dart';

/// Riscos e penalidades, dos mais graves para os mais leves, com o
/// impacto e a recomendação da IA.
class RiscosList extends StatelessWidget {
  final List<Risco> riscos;

  const RiscosList({super.key, required this.riscos});

  @override
  Widget build(BuildContext context) {
    final ordenados = [...riscos]..sort((a, b) => a.severidade.index.compareTo(b.severidade.index));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, risco) in ordenados.indexed) ...[
          if (i > 0) const SizedBox(height: 12),
          _RiscoTile(risco: risco),
        ],
      ],
    );
  }
}

class _RiscoTile extends StatelessWidget {
  final Risco risco;

  const _RiscoTile({required this.risco});

  @override
  Widget build(BuildContext context) {
    final cor = MatchStyle.corDaSeveridade(risco.severidade);
    // Borda só à esquerda não aceita borderRadius; o arredondado vem do clip.
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.06),
          border: Border(left: BorderSide(color: cor, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    risco.descricao,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppBadge(label: MatchStyle.rotuloDaSeveridade(risco.severidade), color: cor),
              ],
            ),
            if (risco.impacto != null) ...[
              const SizedBox(height: 6),
              Text(
                risco.impacto!,
                style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textPrimary),
              ),
            ],
            if (risco.recomendacao != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(AppIcons.question, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      risco.recomendacao!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            EvidenciaView(evidencia: risco.evidencia),
          ],
        ),
      ),
    );
  }
}
