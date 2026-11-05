import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/core/widgets/rating_chart.dart';

/// H-ANI-19 no gráfico do rating (PropV1HistGraf*): a linha se desenha na
/// entrada e trocar o período redesenha em 300 ms.
void main() {
  Widget tela(Object periodo, List<double> ratings, {bool reduzir = false}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduzir),
          child: EntradasVistasEscopo(
            vistas: EntradasVistas(),
            child: EntradaDaTela(
              id: 'historico',
              child: Scaffold(
                body: RatingChart(ratings: ratings, periodo: periodo),
              ),
            ),
          ),
        ),
      );

  double progresso(WidgetTester tester) {
    final pintor = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<RatingChartPainter>()
        .single;
    return pintor.tempo.progresso;
  }

  testWidgets('a linha se desenha em 900 ms na primeira entrada', (
    tester,
  ) async {
    await tester.pumpWidget(tela('mes', [1000, 1040, 1020, 1100]));
    expect(progresso(tester), 0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(progresso(tester), closeTo(.5, .02));
    await tester.pump(const Duration(milliseconds: 450));
    expect(progresso(tester), 1);
  });

  testWidgets('trocar o período redesenha em 300 ms', (tester) async {
    await tester.pumpWidget(tela('mes', [1000, 1040, 1020, 1100]));
    await tester.pumpAndSettle();
    await tester.pumpWidget(tela('ano', [900, 1000, 1040, 1020, 1100]));
    await tester.pump();
    expect(progresso(tester), lessThan(.2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(progresso(tester), 1);
  });

  testWidgets('movimento reduzido: o gráfico vem inteiro', (tester) async {
    await tester.pumpWidget(
      tela('mes', [1000, 1040, 1020, 1100], reduzir: true),
    );
    expect(progresso(tester), 1);
  });
}
