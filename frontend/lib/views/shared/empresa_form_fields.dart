import 'package:flutter/widgets.dart';

import '../../controllers/empresa_form.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';
import '../../models/porte_empresa.dart';
import '../components/components.dart';

/// Campos da empresa: razão social, CNAE, porte, fundação, cidade e UF.
/// Usado no cadastro e na confirmação dos dados da empresa.
class EmpresaFormFields extends StatelessWidget {
  final EmpresaForm form;

  const EmpresaFormFields({super.key, required this.form});

  static const _gap = SizedBox(height: 16);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: form,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdaptiveTextField(
            controller: form.razaoSocialController,
            label: 'Razão social',
            suffix: _icone(AppIcons.business),
          ),
          _gap,
          AdaptiveTextField(
            controller: form.cnaeController,
            label: 'CNAE principal',
            maxLines: 2,
          ),
          _gap,
          AdaptiveSelect<PorteEmpresa>(
            label: 'Porte da empresa',
            placeholder: 'Selecione',
            options: PorteEmpresa.values,
            value: form.porte,
            itemLabel: (p) => p.descricao,
            onChanged: (p) => form.porte = p,
          ),
          _gap,
          AdaptiveDateField(
            label: 'Data de fundação',
            value: form.dataFundacao,
            onChanged: (d) => form.dataFundacao = d,
          ),
          _gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AdaptiveTextField(
                  controller: form.cidadeController,
                  label: 'Cidade',
                  suffix: _icone(AppIcons.location),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AdaptiveSelect<String>(
                  label: 'UF',
                  placeholder: 'UF',
                  options: Ufs.todas,
                  value: form.uf,
                  itemLabel: (uf) => uf,
                  onChanged: (uf) => form.uf = uf,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _icone(IconData icon) => Icon(icon, color: AppColors.border, size: 22);
}
