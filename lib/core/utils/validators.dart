import 'cnpj.dart';

/// Validações de formulário. Retornam a mensagem de erro ou `null` se ok.
abstract final class Validators {
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

  /// Campo único de login: se tiver letra ou "@" é tratado como e-mail,
  /// senão como CNPJ.
  static String? emailOuCnpj(String value) {
    if (value.trim().isEmpty) return 'Informe seu e-mail ou CNPJ.';
    if (pareceEmail(value)) {
      return email(value) == null ? null : 'E-mail inválido.';
    }
    return Cnpj.isValid(value) ? null : 'CNPJ inválido.';
  }

  static bool pareceEmail(String value) => RegExp(r'[a-zA-Z@]').hasMatch(value);

  static String? senha(String value) {
    if (value.isEmpty) return 'Informe a senha.';
    if (value.length < 6) return 'A senha deve ter ao menos 6 caracteres.';
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
