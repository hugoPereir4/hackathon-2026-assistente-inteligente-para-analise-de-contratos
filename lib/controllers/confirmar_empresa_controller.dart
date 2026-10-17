import 'package:flutter/widgets.dart';

import '../core/utils/validators.dart';
import '../models/empresa.dart';
import '../models/usuario.dart';
import '../services/empresa_service.dart';
import 'base_controller.dart';

/// Controller da tela "Confirmar Dados da Empresa".
/// Consulta o CNPJ na API pública, deixa o usuário revisar e salva no perfil.
class ConfirmarEmpresaController extends BaseController {
  final EmpresaService _empresaService;
  final Usuario usuario;

  ConfirmarEmpresaController(this._empresaService, this.usuario);

  final razaoSocialController = TextEditingController();
  final nomeFantasiaController = TextEditingController();
  final cnaeController = TextEditingController();
  final porteController = TextEditingController();
  final enderecoController = TextEditingController();

  String? razaoSocialError;

  Empresa? _empresa;
  Empresa? get empresa => _empresa;

  Future<void> carregar() async {
    await runAsync(() async {
      _empresa = await _empresaService.consultarCnpj(usuario.cnpj);
      _preencherCampos(_empresa!);
    });
  }

  void _preencherCampos(Empresa e) {
    razaoSocialController.text = e.razaoSocial;
    nomeFantasiaController.text = e.nomeFantasia;
    cnaeController.text = e.cnae;
    porteController.text = e.porte;
    enderecoController.text = e.endereco;
  }

  Future<bool> confirmar() async {
    if (_empresa == null) return false;

    razaoSocialError = Validators.obrigatorio(razaoSocialController.text, 'a razão social');
    notify();
    if (razaoSocialError != null) return false;

    final atualizada = _empresa!.copyWith(
      razaoSocial: razaoSocialController.text.trim(),
      nomeFantasia: nomeFantasiaController.text.trim(),
      cnae: cnaeController.text.trim(),
      porte: porteController.text.trim(),
      endereco: enderecoController.text.trim(),
    );
    return runAsync(() async {
      await _empresaService.salvarPerfil(atualizada);
      _empresa = atualizada;
    });
  }

  @override
  void dispose() {
    razaoSocialController.dispose();
    nomeFantasiaController.dispose();
    cnaeController.dispose();
    porteController.dispose();
    enderecoController.dispose();
    super.dispose();
  }
}
