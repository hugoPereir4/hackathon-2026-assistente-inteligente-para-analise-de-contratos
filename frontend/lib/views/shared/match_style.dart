import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../models/analise_detalhe.dart';
import '../../models/analise_resumo.dart';

/// Cores, textos e ícones do resultado da IA, usados na lista de
/// análises e no Painel de Resultados para os dois falarem a mesma língua.
abstract final class MatchStyle {
  /// Verde = boa aderência, amarelo = atenção, vermelho = alto risco.
  static Color corDoScore(int? score) {
    if (score == null) return AppColors.textSecondary;
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.danger;
  }

  static String rotuloDoResultado(ResultadoMatch resultado) => switch (resultado) {
        ResultadoMatch.boaAderencia => 'Boa aderência',
        ResultadoMatch.altoRisco => 'Alto risco',
        ResultadoMatch.incompativel => 'Incompatível',
        ResultadoMatch.dadosInsuficientes => 'Dados insuficientes',
      };

  static Color corDoResultado(ResultadoMatch resultado) => switch (resultado) {
        ResultadoMatch.boaAderencia => AppColors.success,
        ResultadoMatch.altoRisco => AppColors.warning,
        ResultadoMatch.incompativel => AppColors.danger,
        ResultadoMatch.dadosInsuficientes => AppColors.primaryLight,
      };

  /// Frase do topo do painel. A IA não manda um "veredito" em texto, então
  /// ele sai do `outcome` (ou do score, se o outcome não vier).
  static String veredito({ResultadoMatch? resultado, int? score}) => switch (resultado) {
        ResultadoMatch.boaAderencia => 'O documento combina bem com o perfil da sua empresa.',
        ResultadoMatch.altoRisco => 'A empresa atende ao documento, mas há riscos relevantes.',
        ResultadoMatch.incompativel =>
          'Há requisitos obrigatórios que a empresa não atende hoje.',
        ResultadoMatch.dadosInsuficientes =>
          'Faltam dados no perfil para avaliar todos os requisitos.',
        null => vereditoPadrao(score),
      };

  /// "valor_total" -> "Valor total".
  static String rotuloDaCategoria(String categoria) {
    final texto = categoria.replaceAll('_', ' ').trim();
    return texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);
  }

  /// Texto padrão quando não há outcome.
  static String vereditoPadrao(int? score) {
    if (score == null) return 'A análise ainda não tem score.';
    if (score >= 75) {
      return 'O documento combina bem com o perfil da sua empresa.';
    }
    if (score >= 50) {
      return 'Há pontos que precisam de atenção antes de seguir.';
    }
    return 'O documento tem exigências difíceis de atender com o perfil atual.';
  }

  static String rotuloDaSeveridade(Severidade s) => switch (s) {
        Severidade.alta => 'Alta',
        Severidade.media => 'Média',
        Severidade.baixa => 'Baixa',
      };

  static Color corDaSeveridade(Severidade s) => switch (s) {
        Severidade.alta => AppColors.danger,
        Severidade.media => AppColors.warning,
        Severidade.baixa => AppColors.primaryLight,
      };

  static IconData iconeDoRequisito(StatusRequisito s) => switch (s) {
        StatusRequisito.atendido => AppIcons.checkCircle,
        StatusRequisito.parcialmenteAtendido => AppIcons.warning,
        StatusRequisito.naoAtendido => AppIcons.cancelCircle,
        StatusRequisito.indefinido => AppIcons.helpCircle,
      };

  static Color corDoRequisito(StatusRequisito s) => switch (s) {
        StatusRequisito.atendido => AppColors.success,
        StatusRequisito.parcialmenteAtendido => AppColors.warning,
        StatusRequisito.naoAtendido => AppColors.danger,
        StatusRequisito.indefinido => AppColors.textSecondary,
      };
}
