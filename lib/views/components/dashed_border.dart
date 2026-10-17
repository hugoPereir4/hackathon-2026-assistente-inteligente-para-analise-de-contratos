import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';

/// Envolve o [child] com uma borda tracejada arredondada (ex.: zona de upload).
class DashedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dash;
  final double gap;

  const DashedBorder({
    super.key,
    required this.child,
    this.color = AppColors.border,
    this.strokeWidth = 1.5,
    this.radius = 16,
    this.dash = 6,
    this.gap = 4,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        radius: radius,
        dash: dash,
        gap: gap,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dash;
  final double gap;

  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dash,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final PathMetric metric in (Path()..addRRect(rect)).computeMetrics()) {
      var distancia = 0.0;
      while (distancia < metric.length) {
        canvas.drawPath(metric.extractPath(distancia, distancia + dash), paint);
        distancia += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth || old.radius != radius;
}
