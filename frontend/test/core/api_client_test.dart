import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_frontend/core/network/api_client.dart';
import 'package:hackathon_frontend/core/network/api_exception.dart';
import 'package:hackathon_frontend/core/network/token_storage.dart';
import 'package:hackathon_frontend/models/auth_tokens.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemoryTokenStorage implements TokenStorage {
  AuthTokens? tokens;

  _MemoryTokenStorage([this.tokens]);

  @override
  Future<AuthTokens?> ler() async => tokens;

  @override
  Future<void> salvar(AuthTokens t) async => tokens = t;

  @override
  Future<void> limpar() async => tokens = null;
}

http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('monta a URL com /api/v1/ e envia o Bearer', () async {
    late http.Request recebido;
    final api = ApiClient(
      baseUrl: 'http://api.test',
      tokenStorage: _MemoryTokenStorage(const AuthTokens(access: 'A1', refresh: 'R1')),
      httpClient: MockClient((req) async {
        recebido = req;
        return _json({'count': 0, 'results': []}, 200);
      }),
    );

    await api.get('documents/');

    expect(recebido.url.toString(), 'http://api.test/api/v1/documents/');
    expect(recebido.headers['Authorization'], 'Bearer A1');
  });

  test('com 401, renova o access e repete a requisição', () async {
    final storage = _MemoryTokenStorage(const AuthTokens(access: 'velho', refresh: 'R1'));
    final chamadas = <String>[];
    final api = ApiClient(
      baseUrl: 'http://api.test',
      tokenStorage: storage,
      httpClient: MockClient((req) async {
        chamadas.add('${req.url.path} ${req.headers['Authorization'] ?? '-'}');
        if (req.url.path.endsWith('auth/refresh/')) return _json({'access': 'novo'}, 200);
        if (req.headers['Authorization'] == 'Bearer velho') {
          return _json({'detail': 'Token inválido'}, 401);
        }
        return _json({'ok': true}, 200);
      }),
    );

    final resposta = await api.get('users/');

    expect(resposta, {'ok': true});
    expect(storage.tokens?.access, 'novo');
    expect(storage.tokens?.refresh, 'R1');
    expect(chamadas, [
      '/api/v1/users/ Bearer velho',
      '/api/v1/auth/refresh/ -',
      '/api/v1/users/ Bearer novo',
    ]);
  });

  test('se o refresh falhar, limpa a sessão e lança 401', () async {
    final storage = _MemoryTokenStorage(const AuthTokens(access: 'velho', refresh: 'R1'));
    final api = ApiClient(
      baseUrl: 'http://api.test',
      tokenStorage: storage,
      httpClient: MockClient((req) async => _json({'detail': 'expirado'}, 401)),
    );

    await expectLater(
      api.get('users/'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
    expect(storage.tokens, isNull);
  });

  test('upload vai como multipart com o campo "file"', () async {
    late http.Request recebido;
    final api = ApiClient(
      baseUrl: 'http://api.test',
      tokenStorage: _MemoryTokenStorage(const AuthTokens(access: 'A1', refresh: 'R1')),
      httpClient: MockClient((req) async {
        recebido = req;
        return _json({'id': 1}, 201);
      }),
    );

    await api.postMultipart(
      'documents/',
      campoArquivo: 'file',
      nomeArquivo: 'edital.pdf',
      bytes: utf8.encode('%PDF-1.4'),
      campos: {'doc_type': 'tender'},
    );

    expect(recebido.headers['content-type'], startsWith('multipart/form-data'));
    expect(recebido.body, contains('name="file"; filename="edital.pdf"'));
    expect(recebido.body, contains('name="doc_type"'));
  });
}
