import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/analise_detalhe.dart';
import '../../../components/components.dart';
import '../../../shared/match_style.dart';
import 'evidencia_view.dart';

/// Requisitos do documento e se o perfil da empresa os atende,
/// com a justificativa da IA.
class RequisitosList extends StatelessWidget {
  final List<Requisito> requisitos;

  const RequisitosList({super.key, required this.requisitos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, r) in requisitos.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    MatchStyle.iconeDoRequisito(r.status),
                    size: 20,
                    color: MatchStyle.corDoRequisito(r.status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            r.descricao,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.35,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (r.obrigatorio)
                            const AppBadge(label: 'Obrigatório', color: AppColors.textSecondary),
                        ],
                      ),
                      if (r.justificativa != null) ...[
                        const SizedBox(height: 4),
                        AppText.caption(r.justificativa!),
                      ],
                      EvidenciaView(evidencia: r.evidencia),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
