import '../models/empresa.dart';
import '../models/usuario.dart';
import '../services/empresa_service.dart';
import 'base_controller.dart';
import 'empresa_form.dart';

/// Controller da tela "Confirmar Dados da Empresa" (primeiro acesso).
/// Consulta o CNPJ na API pública, deixa o usuário revisar e salva no perfil.
class ConfirmarEmpresaController extends BaseController {
  final EmpresaService _empresaService;
  final Usuario usuario;
  final empresaForm = EmpresaForm();

  ConfirmarEmpresaController(this._empresaService, this.usuario);

  Empresa? _empresa;
  Empresa? get empresa => _empresa;

  Future<void> carregar() async {
    await runAsync(() async {
      _empresa = await _empresaService.consultarCnpj(usuario.cnpj);
      empresaForm.preencher(_empresa!);
    });
  }

  Future<bool> confirmar() async {
    if (_empresa == null) return false;
    final atualizada = empresaForm.paraEmpresa(usuario.cnpj);
    return runAsync(() async {
      await _empresaService.salvarPerfil(atualizada);
      _empresa = atualizada;
    });
  }

  @override
  void dispose() {
    empresaForm.dispose();
    super.dispose();
  }
}
