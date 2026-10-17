import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';

/// Medidor circular de 0 a 100 com o número no centro.
/// Anima do zero até o valor quando aparece.
class ScoreGauge extends StatelessWidget {
  final int? score;
  final Color color;
  final double size;
  final double strokeWidth;

  const ScoreGauge({
    super.key,
    required this.score,
    required this.color,
    this.size = 132,
    this.strokeWidth = 12,
  });

  @override
  Widget build(BuildContext context) {
    final alvo = (score ?? 0).clamp(0, 100).toDouble();
    return Semantics(
      label: score == null ? 'Sem score' : 'Compatibilidade de $score por cento',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: alvo),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, valor, _) => SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _GaugePainter(
              progresso: valor / 100,
              color: color,
              strokeWidth: strokeWidth,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score == null ? '–' : valor.round().toString(),
                    style: TextStyle(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'de 100',
                    style: TextStyle(fontSize: size * 0.1, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progresso;
  final Color color;
  final double strokeWidth;

  const _GaugePainter({required this.progresso, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = color.withValues(alpha: 0.14));
    if (progresso > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progresso, false, base..color = color);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progresso != progresso || old.color != color;
}
