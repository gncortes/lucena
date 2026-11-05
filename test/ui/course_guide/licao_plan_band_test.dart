import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/plan_event.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/course_guide/widgets/licao_plan_band.dart';

import '../../../testing/test_app.dart';

void main() {
  final event = PlanEvent(
    name: 'Torneio da escola',
    start: DateTime(2026, 10, 1),
    date: DateTime(2026, 11, 30),
  );

  group('PlanEvent', () {
    test('conta semanas, dias e semana atual', () {
      final now = DateTime(2026, 11, 4);
      expect(event.totalWeeks, 9);
      expect(event.daysLeft(now), 26);
      expect(event.weekAt(now), 5);
      expect(event.weekFractions(now).where((f) => f >= 1).length, 4);
    });

    test('não passa dos limites', () {
      expect(event.weekAt(DateTime(2026, 9, 1)), 1);
      expect(event.weekAt(DateTime(2027, 1, 1)), 9);
      expect(event.daysLeft(DateTime(2027, 1, 1)), 0);
    });
  });

  group('LicaoPlanBand', () {
    testWidgets('mostra torneio, semana e dias, e abre o plano', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: Scaffold(
            body: LicaoPlanBand(
              event: event,
              now: DateTime(2026, 11, 4),
              onTap: () => taps++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Torneio da escola'), findsOneWidget);
      expect(find.text('Semana 5 de 9 · faltam 26 dias'), findsOneWidget);
      // H-ANI-13: uma barra que enche por semana.
      expect(find.byKey(MotionKeys.barraQueEnche), findsNWidgets(9));
      await tester.tap(find.byKey(CourseGuideKeys.licaoPlanBand));
      expect(taps, 1);
    });

    testWidgets('no dia do evento diz que é hoje', (tester) async {
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: Scaffold(
            body: LicaoPlanBand(
              event: event,
              now: DateTime(2026, 11, 30),
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('é hoje'), findsOneWidget);
    });

    Future<void> faixa(WidgetTester tester, {bool reduzir = false}) =>
        tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(disableAnimations: reduzir),
            child: TestApp(
              locale: const Locale('pt'),
              child: Scaffold(
                body: LicaoPlanBand(
                  event: event,
                  now: DateTime(2026, 11, 4),
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

    int? diasNaTela(WidgetTester tester) {
      final textos = tester
          .widgetList<Text>(find.textContaining('Semana 5 de 9'))
          .map((t) => t.data!);
      if (textos.isEmpty) return null;
      if (textos.single.contains('é hoje')) return 0;
      return int.parse(RegExp(r'(\d+) dias?$').firstMatch(textos.single)![1]!);
    }

    testWidgets('H-ANI-18: os dias que faltam contam até o valor, sem passar '
        'por "é hoje"', (tester) async {
      await faixa(tester);
      final vistos = <int>[];
      for (var i = 0; i < 12; i++) {
        vistos.add(diasNaTela(tester)!);
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(vistos.first, lessThan(26));
      expect(vistos, isNot(contains(0)));
      await tester.pumpAndSettle();
      expect(diasNaTela(tester), 26);
    });

    testWidgets('movimento reduzido: o valor final no primeiro quadro', (
      tester,
    ) async {
      await faixa(tester, reduzir: true);
      expect(diasNaTela(tester), 26);
    });
  });
}
