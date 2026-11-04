import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/barra_do_cronometro.dart';

import '../../../../testing/fakes/fake_now.dart';

/// H-ANI-14: o tempo da teoria numa barra que esvazia, pelo relógio.
void main() {
  final inicio = DateTime(2026, 11, 4, 20);
  const fim = Color(0xFFAA5500);

  Widget tela(FakeNow now, {bool reduzir = false, DateTime? pausadoEm}) =>
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduzir),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: BarraDoCronometro(
                  inicio: inicio,
                  duracao: const Duration(seconds: 10),
                  now: now,
                  pausadoEm: pausadoEm,
                  corDoFim: fim,
                ),
              ),
            ),
          ),
        ),
      );

  LinearProgressIndicator barra(WidgetTester tester) =>
      tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(MotionKeys.barraDoCronometro),
          matching: find.byType(LinearProgressIndicator),
        ),
      );

  Future<void> passar(WidgetTester tester, FakeNow now, Duration d) async {
    now.advance(d);
    await tester.pump(d);
  }

  testWidgets('esvazia linear: metade em 5 s, zero em 10 s, cor do fim', (
    tester,
  ) async {
    final now = FakeNow(inicio);
    await tester.pumpWidget(tela(now));
    expect(barra(tester).value, 1);
    await passar(tester, now, const Duration(seconds: 5));
    expect(barra(tester).value, closeTo(.5, .001));
    expect(barra(tester).color, isNot(fim));
    await passar(tester, now, const Duration(seconds: 5));
    expect(barra(tester).value, 0);
    expect(barra(tester).color, fim);
    expect(tester.hasRunningAnimations, isFalse, reason: 'o relógio para');
  });

  testWidgets('3 s em segundo plano tiram 3 s da barra', (tester) async {
    final now = FakeNow(inicio);
    await tester.pumpWidget(tela(now));
    now.advance(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 16));
    expect(barra(tester).value, closeTo(.7, .001));
  });

  testWidgets('pausada: a barra fica no instante da pausa', (tester) async {
    final now = FakeNow(inicio.add(const Duration(seconds: 8)));
    await tester.pumpWidget(
      tela(now, pausadoEm: inicio.add(const Duration(seconds: 2))),
    );
    expect(barra(tester).value, closeTo(.8, .001));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('movimento reduzido: a barra continua esvaziando', (
    tester,
  ) async {
    final now = FakeNow(inicio);
    await tester.pumpWidget(tela(now, reduzir: true));
    await passar(tester, now, const Duration(seconds: 5));
    expect(barra(tester).value, closeTo(.5, .001));
    await passar(tester, now, const Duration(seconds: 5));
  });
}
