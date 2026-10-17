import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_frontend/core/network/api_exception.dart';

void main() {
  test('lê {"detail": ...}', () {
    final e = ApiException.fromResponse(401, '{"detail": "Usuário e/ou senha incorreto(s)"}');
    expect(e.message, 'Usuário e/ou senha incorreto(s)');
    expect(e.naoAutorizado, isTrue);
  });

  test('lê erros por campo do serializer', () {
    final e = ApiException.fromResponse(
      400,
      '{"email": ["Já existe uma conta com este email."], "cnpj": ["CNPJ inválido."]}',
    );
    expect(e.message, 'Já existe uma conta com este email.');
    expect(e.erroDoCampo('cnpj'), 'CNPJ inválido.');
  });

  test('corpo vazio ou não-JSON usa a mensagem padrão do status', () {
    expect(ApiException.fromResponse(500, '<html>').message, contains('Erro no servidor'));
    expect(ApiException.fromResponse(429, '').message, contains('Muitas tentativas'));
  });
}
