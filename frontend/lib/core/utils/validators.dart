import 'cnpj.dart';

/// Validações de formulário. Retornam a mensagem de erro ou `null` se ok.
abstract final class Validators {
  /// Mínimo do MinimumLengthValidator padrão do Django.
  static const int senhaTamanhoMinimo = 8;

  static String? cnpj(String value) {
    if (value.trim().isEmpty) return 'Informe o CNPJ.';
    if (!Cnpj.isValid(value)) return 'CNPJ inválido.';
    return null;
  }

  static String? email(String value) {
    if (value.trim().isEmpty) return 'Informe o e-mail.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'E-mail inválido.';
    }
    return null;
  }

  /// Campo único de login: com "@" é e-mail, sem "@" é CNPJ
  /// (mesma regra do EmailOrCnpjBackend no Django).
  static String? emailOuCnpj(String value) {
    if (value.trim().isEmpty) return 'Informe seu e-mail ou CNPJ.';
    if (pareceEmail(value)) {
      return email(value) == null ? null : 'E-mail inválido.';
    }
    return Cnpj.isValid(value) ? null : 'CNPJ inválido.';
  }

  static bool pareceEmail(String value) => value.contains('@');

  /// Senha no login: só exige que tenha sido preenchida.
  static String? senha(String value) {
    if (value.isEmpty) return 'Informe a senha.';
    return null;
  }

  /// Senha no cadastro: espelha os validadores padrão do Django que dá para
  /// checar no app (tamanho e "só números"). Os de senha comum e parecida
  /// com o e-mail são checados no backend e voltam como erro do campo.
  static String? novaSenha(String value) {
    if (value.isEmpty) return 'Informe a senha.';
    if (value.length < senhaTamanhoMinimo) {
      return 'A senha deve ter ao menos $senhaTamanhoMinimo caracteres.';
    }
    if (RegExp(r'^\d+$').hasMatch(value)) return 'A senha não pode ter só números.';
    return null;
  }

  static String? confirmarSenha(String value, String senha) {
    if (value.isEmpty) return 'Confirme a senha.';
    if (value != senha) return 'As senhas não coincidem.';
    return null;
  }

  static String? obrigatorio(String value, String campo) {
    return value.trim().isEmpty ? 'Informe $campo.' : null;
  }
}
