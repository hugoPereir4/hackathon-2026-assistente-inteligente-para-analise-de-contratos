import 'dart:convert';

/// Erro vindo da API, já com a mensagem pronta para mostrar ao usuário.
///
/// Entende os formatos do Django REST Framework:
///   {"detail": "..."}                       -> erro geral
///   {"email": ["Já existe uma conta..."]}   -> erros por campo
///   {"message": "...", "error": {...}}      -> formato do CustomPermissionClass
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, List<String>> fieldErrors;

  const ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  const ApiException.semConexao()
      : this('Não foi possível conectar ao servidor. Verifique sua internet.');

  bool get naoAutorizado => statusCode == 401;

  /// Primeira mensagem de erro de um campo, ex.: `erroDoCampo('email')`.
  String? erroDoCampo(String campo) {
    final erros = fieldErrors[campo];
    return erros == null || erros.isEmpty ? null : erros.first;
  }

  factory ApiException.fromResponse(int statusCode, String body) {
    final padrao = _mensagemPadrao(statusCode);
    Object? json;
    try {
      json = body.isEmpty ? null : jsonDecode(body);
    } catch (_) {
      return ApiException(padrao, statusCode: statusCode);
    }
    if (json is! Map<String, dynamic>) return ApiException(padrao, statusCode: statusCode);

    final campos = <String, List<String>>{};
    json.forEach((chave, valor) {
      if (chave == 'detail' || chave == 'message') return;
      final msgs = _comoLista(valor);
      if (msgs.isNotEmpty) campos[chave] = msgs;
    });

    final geral = _comoTexto(json['detail']) ?? _comoTexto(json['message']);
    final primeiroDeCampo = campos.values.isEmpty ? null : campos.values.first.first;
    return ApiException(
      geral ?? primeiroDeCampo ?? padrao,
      statusCode: statusCode,
      fieldErrors: campos,
    );
  }

  static List<String> _comoLista(Object? valor) {
    if (valor is String) return [valor];
    if (valor is List) return valor.map((e) => e.toString()).toList();
    return const [];
  }

  static String? _comoTexto(Object? valor) {
    if (valor is String && valor.isNotEmpty) return valor;
    if (valor is List && valor.isNotEmpty) return valor.first.toString();
    return null;
  }

  static String _mensagemPadrao(int statusCode) {
    if (statusCode == 401) return 'Sua sessão expirou. Entre novamente.';
    if (statusCode == 403) return 'Sem permissão para acessar o recurso.';
    if (statusCode == 404) return 'Recurso não encontrado.';
    if (statusCode == 413) return 'O arquivo é grande demais.';
    if (statusCode == 429) return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
    if (statusCode >= 500) return 'Erro no servidor. Tente novamente em instantes.';
    return 'Não foi possível concluir a operação.';
  }

  @override
  String toString() => message;
}
