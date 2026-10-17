import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/analise_resumo.dart';
import '../../../components/components.dart';

/// Linha da lista "Análises recentes": ícone do arquivo, nome, data,
/// categoria e o badge com o resultado do Match.
class AnaliseRecenteTile extends AdaptiveWidget {
  final AnaliseResumo analise;
  final VoidCallback? onTap;

  static const double _larguraCompacta = 480;

  const AnaliseRecenteTile({super.key, required this.analise, this.onTap});

  VoidCallback? get _onTap => analise.concluida ? onTap : null;

  @override
  Widget buildMaterial(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        onTap: _onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: _conteudo(),
      ),
    );
  }

  @override
  Widget buildCupertino(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: _conteudo(),
    );
  }

  Widget _conteudo() {
    final detalhes = [
      'Adicionado ${Formatters.tempoRelativo(analise.enviadoEm)}',
      if (analise.categoria != null) analise.categoria!,
    ].join(' • ');

    return LayoutBuilder(
      builder: (context, constraints) {
        // Em telas estreitas o badge desce para baixo do texto,
        // para não espremer o nome do arquivo.
        final compacto = constraints.maxWidth < _larguraCompacta;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(AppIcons.document, color: _corDoArquivo, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analise.nomeArquivo,
                      maxLines: compacto ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AppText.caption(detalhes),
                    if (compacto) ...[const SizedBox(height: 8), _badge()],
                  ],
                ),
              ),
              if (!compacto) ...[const SizedBox(width: 12), _badge()],
              if (analise.concluida) ...[
                const SizedBox(width: 6),
                Icon(AppIcons.chevronRight, color: AppColors.textSecondary, size: 20),
              ],
            ],
          ),
        );
      },
    );
  }

  /// PDF em vermelho, DOCX em azul, como os ícones usuais desses formatos.
  Color get _corDoArquivo => analise.nomeArquivo.toLowerCase().endsWith('.docx')
      ? const Color(0xFF2B5CD9)
      : AppColors.danger;

  Widget _badge() {
    switch (analise.status) {
      case StatusAnalise.processando:
        return const AppBadge(
          label: 'Analisando',
          color: AppColors.primaryLight,
          leading: AdaptiveLoading(size: 12, color: AppColors.primary),
        );
      case StatusAnalise.erro:
        return const AppBadge(label: 'Falhou', color: AppColors.danger);
      case StatusAnalise.concluida:
        final score = analise.matchScore ?? 0;
        return AppBadge(label: '$score% Match', color: corDoScore(score));
    }
  }

  /// Verde = boa aderência, amarelo = atenção, vermelho = alto risco.
  static Color corDoScore(int score) {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.danger;
  }
}
