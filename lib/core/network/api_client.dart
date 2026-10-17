import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../models/auth_tokens.dart';
import '../config/app_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Cliente HTTP da API Django.
///
/// - Monta a URL com `API_URL` + `/api/v1/`.
/// - Envia `Authorization: Bearer <access>` nas rotas autenticadas.
/// - Ao receber 401, renova o access com o refresh uma vez e repete a requisição.
/// - Converte respostas de erro em [ApiException].
class ApiClient {
  final http.Client _http;
  final TokenStorage _tokenStorage;
  final String _baseUrl;

  AuthTokens? _tokens;
  bool _tokensCarregados = false;
  Future<bool>? _refreshEmAndamento;

  ApiClient({
    required TokenStorage tokenStorage,
    http.Client? httpClient,
    String baseUrl = AppConfig.apiUrl,
  })  : _tokenStorage = tokenStorage, // ignore: prefer_initializing_formals
        _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  // ---------------------------------------------------------------- sessão

  Future<AuthTokens?> get tokens async {
    if (!_tokensCarregados) {
      _tokens = await _tokenStorage.ler();
      _tokensCarregados = true;
    }
    return _tokens;
  }

  Future<void> salvarTokens(AuthTokens tokens) async {
    _tokens = tokens;
    _tokensCarregados = true;
    await _tokenStorage.salvar(tokens);
  }

  Future<void> limparTokens() async {
    _tokens = null;
    _tokensCarregados = true;
    await _tokenStorage.limpar();
  }

  // ---------------------------------------------------------------- verbos

  Future<dynamic> get(String path, {Map<String, String>? query, bool auth = true}) {
    return _enviar(() => http.Request('GET', _uri(path, query)), auth: auth);
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) {
    return _enviar(() => _comJson('POST', path, body), auth: auth);
  }

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) {
    return _enviar(() => _comJson('PATCH', path, body), auth: auth);
  }

  Future<dynamic> delete(String path, {bool auth = true}) {
    return _enviar(() => http.Request('DELETE', _uri(path)), auth: auth);
  }

  /// Envia `multipart/form-data` (upload de arquivos).
  Future<dynamic> postMultipart(
    String path, {
    required String campoArquivo,
    required String nomeArquivo,
    required Uint8List bytes,
    Map<String, String> campos = const {},
  }) {
    return _enviar(() {
      final request = http.MultipartRequest('POST', _uri(path))
        ..fields.addAll(campos)
        ..files.add(http.MultipartFile.fromBytes(campoArquivo, bytes, filename: nomeArquivo));
      return request;
    });
  }

  // ---------------------------------------------------------------- interno

  Uri _uri(String path, [Map<String, String>? query]) {
    final limpo = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$_baseUrl${AppConfig.apiPrefix}$limpo')
        .replace(queryParameters: query == null || query.isEmpty ? null : query);
  }

  http.Request _comJson(String metodo, String path, Object? body) {
    final request = http.Request(metodo, _uri(path))
      ..headers['Content-Type'] = 'application/json; charset=utf-8';
    if (body != null) request.body = jsonEncode(body);
    return request;
  }

  /// [criarRequest] é chamado de novo na repetição após o refresh,
  /// porque um `BaseRequest` do pacote http só pode ser enviado uma vez.
  Future<dynamic> _enviar(http.BaseRequest Function() criarRequest, {bool auth = true}) async {
    var resposta = await _executar(criarRequest(), auth: auth);

    if (resposta.statusCode == 401 && auth && await _renovarAccess()) {
      resposta = await _executar(criarRequest(), auth: auth);
    }

    final corpo = utf8.decode(resposta.bodyBytes);
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return corpo.isEmpty ? null : jsonDecode(corpo);
    }
    if (resposta.statusCode == 401 && auth) await limparTokens();
    throw ApiException.fromResponse(resposta.statusCode, corpo);
  }

  Future<http.Response> _executar(http.BaseRequest request, {required bool auth}) async {
    request.headers['Accept'] = 'application/json';
    request.headers['Accept-Language'] = 'pt-BR';
    if (auth) {
      final access = (await tokens)?.access;
      if (access != null) request.headers['Authorization'] = 'Bearer $access';
    }
    try {
      final streamed = await _http.send(request).timeout(AppConfig.requestTimeout);
      return await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException('O servidor demorou para responder. Tente novamente.');
    } on http.ClientException {
      throw const ApiException.semConexao();
    }
  }

  /// Renova o access token. Várias requisições com 401 ao mesmo tempo
  /// compartilham a mesma renovação.
  Future<bool> _renovarAccess() {
    return _refreshEmAndamento ??= _fazerRefresh().whenComplete(() => _refreshEmAndamento = null);
  }

  Future<bool> _fazerRefresh() async {
    final atuais = await tokens;
    if (atuais == null) return false;
    try {
      final resposta = await _executar(
        _comJson('POST', 'auth/refresh/', {'refresh': atuais.refresh}),
        auth: false,
      );
      if (resposta.statusCode != 200) return false;
      final json = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
      // Se ROTATE_REFRESH_TOKENS estiver ligado no backend, vem um refresh novo.
      await salvarTokens(atuais.copyWith(
        access: json['access'] as String,
        refresh: json['refresh'] as String?,
      ));
      return true;
    } on ApiException {
      return false;
    }
  }
}
