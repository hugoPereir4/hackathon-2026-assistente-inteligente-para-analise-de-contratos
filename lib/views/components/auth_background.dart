import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';

/// Fundo das telas de autenticação: branco com anéis decorativos
/// no canto superior esquerdo e no inferior direito.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(top: -140, left: -140, child: _Rings()),
        const Positioned(bottom: -140, right: -140, child: _Rings()),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Rings extends StatelessWidget {
  const _Rings();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [_ring(300), _ring(170)],
      ),
    );
  }

  Widget _ring(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 36),
      ),
    );
  }
}
