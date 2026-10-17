import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../models/analise_detalhe.dart';
import '../../../components/components.dart';

/// Perguntas da IA quando faltam dados no perfil ("Faltam dados no perfil"
/// no fluxograma). Por enquanto só exibe; responder fica para a próxima etapa.
class PerguntasPendentesCard extends StatelessWidget {
  final List<PerguntaPendente> perguntas;

  const PerguntasPendentesCard({super.key, required this.perguntas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.question, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'A IA precisa de mais informações',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const AppText.caption('Com essas respostas no perfil, o score fica mais preciso.'),
          const SizedBox(height: 12),
          BulletList(itens: [for (final p in perguntas) p.pergunta]),
        ],
      ),
    );
  }
}
