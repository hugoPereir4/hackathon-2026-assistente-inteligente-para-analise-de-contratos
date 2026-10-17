import 'package:flutter/widgets.dart';

import '../models/empresa.dart';
import '../models/porte_empresa.dart';

/// Estado do formulário com os dados (opcionais) da empresa.
///
/// É compartilhado por composição entre o cadastro e a confirmação
/// da empresa, para os dois não duplicarem campos e regras.
class EmpresaForm extends ChangeNotifier {
  final razaoSocialController = TextEditingController();
  final cnaeController = TextEditingController();
  final cidadeController = TextEditingController();

  PorteEmpresa? _porte;
  DateTime? _dataFundacao;
  String? _uf;

  PorteEmpresa? get porte => _porte;
  DateTime? get dataFundacao => _dataFundacao;
  String? get uf => _uf;

  set porte(PorteEmpresa? value) {
    _porte = value;
    notifyListeners();
  }

  set dataFundacao(DateTime? value) {
    _dataFundacao = value;
    notifyListeners();
  }

  set uf(String? value) {
    _uf = value;
    notifyListeners();
  }

  /// Preenche os campos com o que veio da API de CNPJ.
  void preencher(Empresa e) {
    razaoSocialController.text = e.razaoSocial ?? '';
    cnaeController.text = e.cnae ?? '';
    cidadeController.text = e.cidade ?? '';
    _porte = e.porte;
    _dataFundacao = e.dataFundacao;
    _uf = e.uf;
    notifyListeners();
  }

  /// Monta a [Empresa]; textos vazios viram `null` (colunas NULL no banco).
  Empresa paraEmpresa(String cnpj) {
    String? texto(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    return Empresa(
      cnpj: cnpj,
      razaoSocial: texto(razaoSocialController),
      cnae: texto(cnaeController),
      porte: _porte,
      dataFundacao: _dataFundacao,
      cidade: texto(cidadeController),
      uf: _uf,
    );
  }

  @override
  void dispose() {
    razaoSocialController.dispose();
    cnaeController.dispose();
    cidadeController.dispose();
    super.dispose();
  }
}
