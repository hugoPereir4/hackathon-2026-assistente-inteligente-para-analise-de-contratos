import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'adaptive_widget.dart';

/// Indicador de carregamento: CircularProgressIndicator ou CupertinoActivityIndicator.
class AdaptiveLoading extends AdaptiveWidget {
  final double size;
  final Color color;

  const AdaptiveLoading({super.key, this.size = 32, this.color = AppColors.primary});

  @override
  Widget buildMaterial(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(strokeWidth: size / 10, color: color),
    );
  }

  @override
  Widget buildCupertino(BuildContext context) {
    return CupertinoActivityIndicator(radius: size / 2, color: color);
  }
}
