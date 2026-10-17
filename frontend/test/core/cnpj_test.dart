import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_frontend/core/utils/cnpj.dart';
import 'package:hackathon_frontend/core/utils/validators.dart';

void main() {
  group('Cnpj (mesmas regras do backend)', () {
    test('aceita CNPJ numérico com e sem máscara', () {
      expect(Cnpj.isValid('11222333000181'), isTrue);
      expect(Cnpj.isValid('11.222.333/0001-81'), isTrue);
    });

    test('aceita CNPJ alfanumérico (exemplo da Receita)', () {
      expect(Cnpj.isValid('12ABC34501DE35'), isTrue);
      expect(Cnpj.isValid('12.abc.345/01de-35'), isTrue);
    });

    test('rejeita dígito verificador errado, repetidos e tamanho errado', () {
      expect(Cnpj.isValid('11222333000182'), isFalse);
      expect(Cnpj.isValid('12ABC34501DE36'), isFalse);
      expect(Cnpj.isValid('11111111111111'), isFalse);
      expect(Cnpj.isValid('1122233300018'), isFalse);
    });

    test('normaliza e formata', () {
      expect(Cnpj.normalize('12.abc.345/01de-35'), '12ABC34501DE35');
      expect(Cnpj.format('12abc34501de35'), '12.ABC.345/01DE-35');
    });
  });

  group('Validators', () {
    test('login: com "@" é e-mail, sem "@" é CNPJ', () {
      expect(Validators.emailOuCnpj('ana@empresa.com'), isNull);
      expect(Validators.emailOuCnpj('12ABC34501DE35'), isNull);
      expect(Validators.emailOuCnpj('ana.empresa.com'), 'CNPJ inválido.');
    });

    test('nova senha segue os validadores do Django', () {
      expect(Validators.novaSenha('abc12'), isNotNull);
      expect(Validators.novaSenha('12345678'), isNotNull);
      expect(Validators.novaSenha('senhaForte1'), isNull);
    });
  });
}
