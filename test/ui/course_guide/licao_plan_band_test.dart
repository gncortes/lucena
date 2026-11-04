import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/plan_event.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
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
      expect(find.text('Torneio da escola'), findsOneWidget);
      expect(find.text('Semana 5 de 9 · faltam 26 dias'), findsOneWidget);
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
  });
}
