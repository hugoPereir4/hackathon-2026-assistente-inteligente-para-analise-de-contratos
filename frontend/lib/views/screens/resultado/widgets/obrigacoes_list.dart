import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/analise_detalhe.dart';
import '../../../components/components.dart';
import 'evidencia_view.dart';

/// Obrigações com a parte responsável. As da empresa do usuário aparecem
/// primeiro e com o selo "Sua empresa".
class ObrigacoesList extends StatelessWidget {
  final List<Obrigacao> obrigacoes;

  /// Parte do contrato que é a empresa do usuário (ex.: CONTRATADA).
  final String? parteDaEmpresa;

  /// Resolve o `prazo_id` de uma obrigação para o prazo correspondente.
  final Prazo? Function(String? id) prazoPorId;

  const ObrigacoesList({
    super.key,
    required this.obrigacoes,
    required this.prazoPorId,
    this.parteDaEmpresa,
  });

  bool _ehDaEmpresa(Obrigacao o) => parteDaEmpresa != null && o.parteResponsavel == parteDaEmpresa;

  @override
  Widget build(BuildContext context) {
    final ordenadas = [
      ...obrigacoes.where(_ehDaEmpresa),
      ...obrigacoes.where((o) => !_ehDaEmpresa(o)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, o) in ordenadas.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
            child: _linha(o),
          ),
      ],
    );
  }

  Widget _linha(Obrigacao o) {
    final daEmpresa = _ehDaEmpresa(o);
    final prazo = prazoPorId(o.prazoId);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 8, right: 12),
          decoration: BoxDecoration(
            color: daEmpresa ? AppColors.primary : AppColors.border,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                o.descricao,
                style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (o.parteResponsavel != null)
                    AppBadge(
                      label: daEmpresa ? 'Sua empresa' : _capitalizar(o.parteResponsavel!),
                      color: daEmpresa ? AppColors.primary : AppColors.textSecondary,
                    ),
                  if (prazo != null)
                    AppText.caption('Prazo: ${prazo.textoRelativo ?? prazo.descricao}'),
                ],
              ),
              EvidenciaView(evidencia: o.evidencia),
            ],
          ),
        ),
      ],
    );
  }

  static String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}
