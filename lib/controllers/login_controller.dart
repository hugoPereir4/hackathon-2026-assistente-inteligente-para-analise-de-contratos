import 'package:flutter/widgets.dart';

import '../core/utils/cnpj.dart';
import '../core/utils/validators.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import 'base_controller.dart';

/// Controller da tela de Login (Fase 1 do fluxograma).
class LoginController extends BaseController {
  final AuthService _authService;

  LoginController(this._authService);

  final identificadorController = TextEditingController();
  final senhaController = TextEditingController();

  String? identificadorError;
  String? senhaError;
  bool senhaVisivel = false;

  Usuario? _usuario;
  Usuario? get usuario => _usuario;

  void alternarVisibilidadeSenha() {
    senhaVisivel = !senhaVisivel;
    notify();
  }

  bool _validar() {
    identificadorError = Validators.emailOuCnpj(identificadorController.text);
    senhaError = Validators.senha(senhaController.text);
    notify();
    return identificadorError == null && senhaError == null;
  }

  /// E-mail vai como digitado (sem espaços); CNPJ vai só com os dígitos.
  String get _identificadorNormalizado {
    final texto = identificadorController.text.trim();
    return Validators.pareceEmail(texto) ? texto.toLowerCase() : Cnpj.digits(texto);
  }

  /// Retorna o usuário autenticado ou `null` se houve erro de validação/login.
  Future<Usuario?> entrar() async {
    if (!_validar()) return null;

    final ok = await runAsync(() async {
      _usuario = await _authService.login(
        identificador: _identificadorNormalizado,
        senha: senhaController.text,
      );
    });
    return ok ? _usuario : null;
  }

  @override
  void dispose() {
    identificadorController.dispose();
    senhaController.dispose();
    super.dispose();
  }
}
