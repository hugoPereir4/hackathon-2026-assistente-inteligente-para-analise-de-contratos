import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/analise_detalhe.dart';

/// Mostra de onde a IA tirou a informação: a cláusula e, ao tocar em
/// "ver trecho", a citação do documento. Fechado por padrão para a tela
/// continuar limpa.
class EvidenciaView extends StatefulWidget {
  final Evidencia? evidencia;

  const EvidenciaView({super.key, required this.evidencia});

  @override
  State<EvidenciaView> createState() => _EvidenciaViewState();
}

class _EvidenciaViewState extends State<EvidenciaView> {
  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.evidencia;
    if (e == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              if (e.clausula != null)
                Text(
                  e.clausula!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              if (e.trecho != null)
                Semantics(
                  button: true,
                  child: GestureDetector(
                    onTap: () => setState(() => _aberto = !_aberto),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _aberto ? 'ocultar trecho' : 'ver trecho',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_aberto && e.trecho != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(left: BorderSide(color: AppColors.border, width: 3)),
              ),
              child: Text(
                '“${e.trecho!}”',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
