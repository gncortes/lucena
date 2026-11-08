import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/anel_da_meta.dart';

import '../../../../testing/fakes/fake_now.dart';

/// H-ANI-28: o dia de hoje fecha num anel e a sequência sobe.
void main() {
  final hoje = DateTime(2026, 11, 4, 20);

  Widget tela({
    required FakeNow now,
    DateTime? celebradoEm,
    ValueChanged<DateTime>? aoCelebrar,
    bool reduzir = false,
    double feito = 1,
  }) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduzir),
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: AnelDaMeta(
            feito: feito,
            sequencia: 12,
            celebradoEm: celebradoEm,
            now: now,
            aoCelebrar: aoCelebrar ?? (_) {},
          ),
        ),
      ),
    ),
  );

  PintorDoAnel pintor(WidgetTester tester) =>
      tester.widget<CustomPaint>(find.byKey(MotionKeys.anelDaMeta)).painter!
          as PintorDoAnel;

  String contador(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(MotionKeys.contadorDaMeta),
          matching: find.byType(Text),
        ),
      )
      .last
      .data!;

  testWidgets('o anel fecha em 450 ms e o contador termina em 12', (
    tester,
  ) async {
    DateTime? celebrado;
    await tester.pumpWidget(
      tela(now: FakeNow(hoje), aoCelebrar: (d) => celebrado = d),
    );
    expect(celebrado, hoje, reason: 'a tela guarda o dia da celebração');
    expect(contador(tester), '11');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 225));
    expect(pintor(tester).tempo, closeTo(.5, .01));
    await tester.pump(const Duration(milliseconds: 225));
    expect(pintor(tester).tempo, 1);
    expect(find.byKey(MotionKeys.faiscasDaMeta), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 300));
    expect(contador(tester), '12');
    expect(find.byKey(MotionKeys.faiscasDaMeta), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('reabrir no mesmo dia: o anel já está fechado', (tester) async {
    var chamadas = 0;
    await tester.pumpWidget(
      tela(
        now: FakeNow(hoje.add(const Duration(hours: 2))),
        celebradoEm: hoje,
        aoCelebrar: (_) => chamadas++,
      ),
    );
    expect(pintor(tester).tempo, 1);
    expect(contador(tester), '12');
    expect(find.byKey(MotionKeys.faiscasDaMeta), findsNothing);
    expect(chamadas, 0);
  });

  testWidgets('no dia seguinte, celebra de novo', (tester) async {
    await tester.pumpWidget(
      tela(now: FakeNow(hoje.add(const Duration(days: 1))), celebradoEm: hoje),
    );
    expect(pintor(tester).tempo, 0);
    await tester.pumpAndSettle();
  });

  testWidgets('meta ainda não cumprida: o anel parado no que foi feito', (
    tester,
  ) async {
    await tester.pumpWidget(tela(now: FakeNow(hoje), feito: .4));
    expect(pintor(tester).tempo, 1);
    expect(pintor(tester).feito, .4);
    expect(contador(tester), '12');
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('movimento reduzido: anel fechado e 12 no primeiro quadro', (
    tester,
  ) async {
    await tester.pumpWidget(tela(now: FakeNow(hoje), reduzir: true));
    expect(pintor(tester).tempo, 1);
    expect(contador(tester), '12');
    expect(find.byKey(MotionKeys.faiscasDaMeta), findsNothing);
  });
}
