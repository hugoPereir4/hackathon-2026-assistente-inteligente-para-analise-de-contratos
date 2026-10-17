import '../models/empresa.dart';
import '../models/usuario.dart';
import '../services/empresa_service.dart';
import 'base_controller.dart';
import 'empresa_form.dart';

/// Controller da tela "Confirmar Dados da Empresa" (primeiro acesso).
///
/// Carrega o perfil salvo e completa os campos vazios com a consulta
/// pública do CNPJ; ao confirmar, salva e marca `confirmed`.
class ConfirmarEmpresaController extends BaseController {
  final EmpresaService _empresaService;
  Usuario _usuario;
  final empresaForm = EmpresaForm();

  ConfirmarEmpresaController(this._empresaService, Usuario usuario) : _usuario = usuario;

  Usuario get usuario => _usuario;

  Empresa? _empresa;
  Empresa? get empresa => _empresa;

  Future<void> carregar() async {
    await runAsync(() async {
      var perfil = await _empresaService.buscarPerfil();
      try {
        perfil = perfil.completarCom(await _empresaService.consultarCnpj(perfil.cnpj));
      } catch (_) {
        // Consulta de CNPJ indisponível: segue só com o que já está salvo.
      }
      _empresa = perfil;
      empresaForm.preencher(perfil);
    });
  }

  Future<bool> confirmar() async {
    if (_empresa == null) return false;
    final atualizada = empresaForm.paraEmpresa(_usuario.cnpj);
    return runAsync(() async {
      _usuario = await _empresaService.salvarPerfil(_usuario, atualizada);
      _empresa = atualizada;
    });
  }

  @override
  void dispose() {
    empresaForm.dispose();
    super.dispose();
  }
}
