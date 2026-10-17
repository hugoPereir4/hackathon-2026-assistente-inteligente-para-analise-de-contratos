import 'package:flutter/widgets.dart';

import '../../../controllers/cadastro_controller.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/cnpj.dart';
import '../../components/components.dart';
import '../../shared/empresa_form_fields.dart';

/// Tela "Nova conta": dados de acesso (obrigatórios) + dados da empresa (opcionais).
class CadastroView extends StatefulWidget {
  const CadastroView({super.key});

  @override
  State<CadastroView> createState() => _CadastroViewState();
}

class _CadastroViewState extends State<CadastroView> {
  late final CadastroController _controller = CadastroController(
    AppDependencies.instance.authService,
    AppDependencies.instance.empresaService,
  );

  static const _gap = SizedBox(height: 16);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    final usuario = await _controller.criarConta();
    if (!mounted) return;

    if (usuario == null) {
      final erro = _controller.errorMessage;
      if (erro != null) {
        await AdaptiveDialog.showMessage(context, title: 'Não foi possível criar a conta', message: erro);
      }
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.dashboard,
      (_) => false,
      arguments: usuario,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      backgroundColor: AppColors.surface,
      body: AuthBackground(
        child: AuthCard(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(title: 'Nova conta', subtitle: 'Informe os dados abaixo:'),
                const SizedBox(height: 20),
                const _SectionTitle('Dados de acesso'),
                const SizedBox(height: 12),
                ..._camposDeAcesso(),
                const SizedBox(height: 28),
                const _SectionTitle('Dados da empresa'),
                const SizedBox(height: 4),
                AppText.caption(
                  _controller.dadosPreenchidosPeloCnpj
                      ? 'Preenchemos com os dados públicos do CNPJ. Confira e ajuste se precisar.'
                      : 'Opcional. Preenchidos automaticamente ao informar um CNPJ válido.',
                ),
                const SizedBox(height: 12),
                EmpresaFormFields(form: _controller.empresaForm),
                const SizedBox(height: 32),
                AdaptiveButton(
                  label: 'Criar',
                  isLoading: _controller.isLoading,
                  onPressed: _criar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _camposDeAcesso() {
    return [
      AdaptiveTextField(
        controller: _controller.cnpjController,
        label: 'CNPJ *',
        placeholder: '00.000.000/0000-00',
        keyboardType: TextInputType.number,
        inputFormatters: [CnpjInputFormatter()],
        errorText: _controller.cnpjError,
        suffix: _controller.buscandoCnpj
            ? const AdaptiveLoading(size: 18)
            : _icone(AppIcons.idCard),
      ),
      _gap,
      AdaptiveTextField(
        controller: _controller.emailController,
        label: 'E-mail *',
        placeholder: 'voce@empresa.com.br',
        keyboardType: TextInputType.emailAddress,
        errorText: _controller.emailError,
        suffix: _icone(AppIcons.at),
      ),
      _gap,
      AdaptiveTextField(
        controller: _controller.senhaController,
        label: 'Senha *',
        obscureText: !_controller.senhaVisivel,
        errorText: _controller.senhaError,
        suffix: _botaoVisibilidade(),
      ),
      _gap,
      AdaptiveTextField(
        controller: _controller.confirmarSenhaController,
        label: 'Confirmar senha *',
        obscureText: !_controller.senhaVisivel,
        errorText: _controller.confirmarSenhaError,
      ),
    ];
  }

  Widget _icone(IconData icon) => Icon(icon, color: AppColors.border, size: 22);

  Widget _botaoVisibilidade() => GestureDetector(
        onTap: _controller.alternarVisibilidadeSenha,
        child: Icon(
          _controller.senhaVisivel ? AppIcons.hidden : AppIcons.visible,
          color: AppColors.textSecondary,
          size: 20,
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}
