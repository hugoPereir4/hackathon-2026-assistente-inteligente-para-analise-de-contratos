import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_frontend/models/analise_detalhe.dart';
import 'package:hackathon_frontend/models/analise_resumo.dart';
import 'package:hackathon_frontend/views/screens/resultado/widgets/resultado_header.dart';

void main() {
  testWidgets('mostra a contagem de requisitos parcialmente atendidos', (tester) async {
    final analysis = AnaliseResumo(
      id: '1',
      nomeArquivo: 'contrato.pdf',
      enviadoEm: DateTime(2026, 10, 18),
      status: StatusAnalise.concluida,
      matchScore: 50,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ResultadoHeader(
          analise: analysis,
          aderencia: const Aderencia(
            score: 50,
            cobertura: 100,
            total: 1,
            avaliados: 1,
            parcialmenteAtendidos: 1,
          ),
        ),
      ),
    ));

    expect(find.text('1 parcialmente atendido'), findsOneWidget);
  });
}
