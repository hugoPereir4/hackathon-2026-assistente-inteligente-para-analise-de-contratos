import 'package:flutter/widgets.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/usuario.dart';
import '../../components/components.dart';

/// Dashboard principal / Área de upload (Fase 2 do fluxograma).
class DashboardView extends StatelessWidget {
  final Usuario usuario;

  const DashboardView({super.key, required this.usuario});

  Future<void> _sair(BuildContext context) async {
    final confirmou = await AdaptiveDialog.showConfirm(
      context,
      title: 'Sair',
      message: 'Deseja encerrar a sessão?',
      confirmLabel: 'Sair',
    );
    if (confirmou && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Início',
      showBackButton: false,
      actions: [
        GestureDetector(
          onTap: () => _sair(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(AppIcons.logout, color: const Color(0xFFFFFFFF)),
          ),
        ),
      ],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing * 1.5),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppText.title('Olá!'),
                const SizedBox(height: 4),
                AppText.caption(usuario.email),
                const SizedBox(height: 24),
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(AppIcons.upload, size: 48, color: AppColors.primary),
                      const SizedBox(height: 12),
                      const AppText.subtitle('Envie um documento'),
                      const SizedBox(height: 4),
                      const AppText.caption(
                        'Contrato, edital ou proposta comercial em PDF ou DOCX',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      AdaptiveButton(
                        label: 'Selecionar arquivo',
                        icon: AppIcons.document,
                        onPressed: () => AdaptiveDialog.showMessage(
                          context,
                          title: 'Em breve',
                          message: 'O upload de documentos será a próxima etapa.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
