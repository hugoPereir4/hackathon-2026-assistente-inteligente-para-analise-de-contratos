import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_frontend/core/utils/formatters.dart';

void main() {
  test('moeda no padrão brasileiro', () {
    expect(Formatters.moeda(0), r'R$ 0,00');
    expect(Formatters.moeda(6500.5), r'R$ 6.500,50');
    expect(Formatters.moeda(480000), r'R$ 480.000,00');
    expect(Formatters.moeda(1234567.891), r'R$ 1.234.567,89');
    expect(Formatters.moeda(-12.3), r'-R$ 12,30');
    expect(Formatters.moeda(10, moeda: 'USD'), r'US$ 10,00');
  });

  test('moeda aceita o símbolo que a IA manda ("R\$")', () {
    expect(Formatters.moeda(180000, moeda: r'R$'), r'R$ 180.000,00');
  });

  test('percentual', () {
    expect(Formatters.percentual(2), '2%');
    expect(Formatters.percentual(2.5), '2,5%');
    expect(Formatters.percentual(0.75), '0,75%');
  });

  test('prazo relativo por dia de calendário', () {
    final agora = DateTime(2026, 10, 17, 23, 30);
    expect(Formatters.prazoRelativo(DateTime(2026, 10, 17), agora: agora), 'hoje');
    expect(Formatters.prazoRelativo(DateTime(2026, 10, 18), agora: agora), 'amanhã');
    expect(Formatters.prazoRelativo(DateTime(2026, 10, 26), agora: agora), 'em 9 dias');
    expect(Formatters.prazoRelativo(DateTime(2026, 10, 16), agora: agora), 'venceu ontem');
    expect(Formatters.prazoRelativo(DateTime(2026, 10, 14), agora: agora), 'venceu há 3 dias');
  });
}
