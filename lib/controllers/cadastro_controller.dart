import 'package:flutter/widgets.dart';

import '../core/utils/cnpj.dart';
import '../core/utils/validators.dart';
import '../models/nova_conta.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/empresa_service.dart';
import 'base_controller.dart';
import 'empresa_form.dart';

/// Controller da tela "Nova conta".
///
/// Obrigatórios (NOT NULL): CNPJ, e-mail e senha.
/// Opcionais: dados da empresa, preenchidos sozinhos quando o CNPJ é válido.
class CadastroController extends BaseController {
  final AuthService _authService;
  final EmpresaService _empresaService;

  CadastroController(this._authService, this._empresaService) {
    cnpjController.addListener(_aoMudarCnpj);
  }

  final cnpjController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();
  final empresaForm = EmpresaForm();

  String? cnpjError;
  String? emailError;
  String? senhaError;
  String? confirmarSenhaError;
  bool senhaVisivel = false;

  bool buscandoCnpj = false;
  bool dadosPreenchidosPeloCnpj = false;
  String? _ultimoCnpjConsultado;

  void alternarVisibilidadeSenha() {
    senhaVisivel = !senhaVisivel;
    notify();
  }

  void _aoMudarCnpj() {
    final digitos = Cnpj.digits(cnpjController.text);
    if (digitos.length == 14 && Cnpj.isValid(digitos) && digitos != _ultimoCnpjConsultado) {
      _consultarCnpj(digitos);
    }
  }

  /// Consulta a API pública de CNPJ para adiantar os campos opcionais.
  /// Se falhar, o usuário simplesmente preenche à mão.
  Future<void> _consultarCnpj(String cnpj) async {
    _ultimoCnpjConsultado = cnpj;
    cnpjError = null;
    buscandoCnpj = true;
    notify();
    try {
      final empresa = await _empresaService.consultarCnpj(cnpj);
      if (_ultimoCnpjConsultado != cnpj) return; // usuário trocou o CNPJ no meio
      empresaForm.preencher(empresa);
      dadosPreenchidosPeloCnpj = true;
    } catch (_) {
      dadosPreenchidosPeloCnpj = false;
    } finally {
      buscandoCnpj = false;
      notify();
    }
  }

  bool _validar() {
    cnpjError = Validators.cnpj(cnpjController.text);
    emailError = Validators.email(emailController.text);
    senhaError = Validators.senha(senhaController.text);
    confirmarSenhaError =
        Validators.confirmarSenha(confirmarSenhaController.text, senhaController.text);
    notify();
    return [cnpjError, emailError, senhaError, confirmarSenhaError].every((e) => e == null);
  }

  /// Retorna o usuário criado ou `null` se houve erro de validação/cadastro.
  Future<Usuario?> criarConta() async {
    if (!_validar()) return null;

    Usuario? usuario;
    final conta = NovaConta(
      email: emailController.text.trim().toLowerCase(),
      senha: senhaController.text,
      empresa: empresaForm.paraEmpresa(Cnpj.digits(cnpjController.text)),
    );
    final ok = await runAsync(() async {
      usuario = await _authService.cadastrar(conta);
    });
    return ok ? usuario : null;
  }

  @override
  void dispose() {
    cnpjController.removeListener(_aoMudarCnpj);
    cnpjController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    empresaForm.dispose();
    super.dispose();
  }
}
