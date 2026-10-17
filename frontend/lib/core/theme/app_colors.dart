import 'package:flutter/widgets.dart';

/// Paleta do app. A cor primária vem da identidade do hackathon: RGB(42, 43, 118).
abstract final class AppColors {
  static const Color primary = Color.fromRGBO(42, 43, 118, 1); // #2A2B76
  static const Color primaryLight = Color(0xFF4B4DA8);
  static const Color primaryDark = Color(0xFF1B1C4F);

  static const Color background = Color(0xFFF5F6FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1B2E);
  static const Color textSecondary = Color(0xFF6B6D85);
  static const Color border = Color(0xFFDADCEB);

  // Cores de status usadas no painel de resultados (score / riscos).
  static const Color success = Color(0xFF2E9E6B);
  static const Color warning = Color(0xFFE8B931);
  static const Color danger = Color(0xFFD64545);
}
