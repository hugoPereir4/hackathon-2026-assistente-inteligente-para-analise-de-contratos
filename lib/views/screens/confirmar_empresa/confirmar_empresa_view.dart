import 'package:flutter/widgets.dart';

import '../../../controllers/confirmar_empresa_controller.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/cnpj.dart';
import '../../../models/usuario.dart';
import '../../components/components.dart';
import '../../shared/empresa_form_fields.dart';

/// Tela simples para o usuário revisar os dados vindos da API de CNPJ.
class ConfirmarEmpresaView extends StatefulWidget {
  final Usuario usuario;

  const ConfirmarEmpresaView({super.key, required this.usuario});

  @override
  State<ConfirmarEmpresaView> createState() => _ConfirmarEmpresaViewState();
}

class _ConfirmarEmpresaViewState extends State<ConfirmarEmpresaView> {
  late final ConfirmarEmpresaController _controller =
      ConfirmarEmpresaController(AppDependencies.instance.empresaService, widget.usuario);

  @override
  void initState() {
    super.initState();
    _controller.carregar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final ok = await _controller.confirmar();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (_) => false,
        arguments: widget.usuario,
      );
    } else if (_controller.errorMessage != null) {
      await AdaptiveDialog.showMessage(
        context,
        title: 'Erro ao salvar',
        message: _controller.errorMessage!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Dados da empresa',
      showBackButton: false,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.empresa == null) {
            return _controller.isLoading
                ? const Center(child: AdaptiveLoading())
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing),
                      child: AppText.body(
                        _controller.errorMessage ?? 'Não foi possível consultar o CNPJ.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
          }
          return _buildFormulario();
        },
      ),
    );
  }

  Widget _buildFormulario() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing * 1.5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppText.subtitle('Confira os dados encontrados'),
              const SizedBox(height: 4),
              AppText.caption('CNPJ ${Cnpj.format(widget.usuario.cnpj)}'),
              const SizedBox(height: 20),
              EmpresaFormFields(form: _controller.empresaForm),
              const SizedBox(height: 28),
              AdaptiveButton(
                label: 'Confirmar dados',
                isLoading: _controller.isLoading,
                onPressed: _confirmar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
