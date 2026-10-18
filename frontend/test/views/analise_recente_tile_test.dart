import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_frontend/models/analise_resumo.dart';
import 'package:hackathon_frontend/views/screens/dashboard/widgets/analise_recente_tile.dart';

void main() {
  testWidgets('score nulo mostra Sem dados no dashboard', (tester) async {
    final analysis = AnaliseResumo(
      id: '1',
      nomeArquivo: 'contrato.pdf',
      enviadoEm: DateTime(2026, 10, 18),
      status: StatusAnalise.concluida,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AnaliseRecenteTile(analise: analysis)),
      ),
    );

    expect(find.text('Sem dados'), findsOneWidget);
    expect(find.text('0% Match'), findsNothing);
  });
}
