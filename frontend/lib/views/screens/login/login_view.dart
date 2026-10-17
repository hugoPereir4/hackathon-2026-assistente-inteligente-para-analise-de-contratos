import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../controllers/login_controller.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/cnpj.dart';
import '../../components/components.dart';

/// Tela de Login: e-mail ou CNPJ + senha.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginController _controller =
      LoginController(AppDependencies.instance.authService);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final usuario = await _controller.entrar();
    if (!mounted) return;

    if (usuario == null) {
      final erro = _controller.errorMessage;
      if (erro != null) {
        await AdaptiveDialog.showMessage(context, title: 'Não foi possível entrar', message: erro);
      }
      return;
    }

    final rota = usuario.primeiroAcesso ? AppRoutes.confirmarEmpresa : AppRoutes.dashboard;
    Navigator.of(context).pushReplacementNamed(rota, arguments: usuario);
  }

  void _criarConta() => Navigator.of(context).pushNamed(AppRoutes.cadastro);

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      backgroundColor: AppColors.surface,
      body: AuthBackground(
        child: AuthCard(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppLogo(),
                const SizedBox(height: 64),
                AdaptiveTextField(
                  controller: _controller.identificadorController,
                  label: 'E-mail ou CNPJ',
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: [EmailOuCnpjInputFormatter()],
                  errorText: _controller.identificadorError,
                  suffix: Icon(AppIcons.idCard, color: AppColors.border, size: 22),
                ),
                const SizedBox(height: 18),
                AdaptiveTextField(
                  controller: _controller.senhaController,
                  label: 'Senha',
                  obscureText: !_controller.senhaVisivel,
                  textInputAction: TextInputAction.done,
                  errorText: _controller.senhaError,
                  onSubmitted: (_) => _entrar(),
                  suffix: GestureDetector(
                    onTap: _controller.alternarVisibilidadeSenha,
                    child: Icon(
                      _controller.senhaVisivel ? AppIcons.hidden : AppIcons.visible,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AdaptiveButton(
                  label: 'Entrar',
                  isLoading: _controller.isLoading,
                  onPressed: _entrar,
                ),
                const SizedBox(height: 56),
                AdaptiveButton.secondary(label: 'Crie sua conta', onPressed: _criarConta),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
