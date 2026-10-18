import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';

/// Card central das telas de autenticação.
///
/// Em telas largas (web/tablet) aparece como um card flutuante com sombra;
/// em telas estreitas (celular) o conteúdo ocupa a tela, sem a moldura.
class AuthCard extends StatelessWidget {
  static const double maxWidth = 480;
  static const double _breakpoint = 600;

  final Widget child;
  final EdgeInsetsGeometry padding;

  const AuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(28, 56, 28, 40),
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _breakpoint;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: isWide
              ? Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: child,
                )
              : child,
        ),
      ),
    );
  }
}
