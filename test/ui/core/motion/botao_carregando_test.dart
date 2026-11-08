import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/motion/botao_carregando.dart';

/// H-ANI-08: o botão troca o rótulo pelo círculo em 120 ms, sem mudar de
/// largura e sem aceitar outro toque.
void main() {
  Widget tela(Widget botao, {bool reduzir = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduzir),
      child: Scaffold(body: Center(child: botao)),
    ),
  );

  testWidgets('carregando: em 120 ms o círculo entrou e o rótulo saiu', (
    tester,
  ) async {
    await tester.pumpWidget(
      tela(BotaoCarregando(label: 'Comprar', busy: false, onPressed: () {})),
    );
    final largura = tester.getSize(find.byType(BotaoCarregando)).width;
    await tester.pumpWidget(
      tela(BotaoCarregando(label: 'Comprar', busy: true, onPressed: () {})),
    );
    await tester.pump(const Duration(milliseconds: 60));
    // No meio da troca, os dois estão lá.
    expect(find.text('Comprar'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 60));
    // Em 120 ms o rótulo está invisível; o quadro seguinte o tira da árvore.
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Comprar'), findsNothing);
    final circulo = find.descendant(
      of: find.byKey(CoreKeys.busySpinner),
      matching: find.byType(CircularProgressIndicator),
    );
    expect(circulo, findsOneWidget);
    expect(
      tester.getSize(find.byKey(CoreKeys.busySpinner)),
      const Size(22, 22),
    );
    expect(tester.widget<CircularProgressIndicator>(circulo).strokeWidth, 3);
    expect(tester.getSize(find.byType(BotaoCarregando)).width, largura);
  });

  testWidgets('o círculo dá uma volta a cada 800 ms, mesmo com movimento '
      'reduzido', (tester) async {
    for (final reduzir in [false, true]) {
      await tester.pumpWidget(
        tela(
          BotaoCarregando(label: 'Comprar', busy: true, onPressed: () {}),
          reduzir: reduzir,
        ),
      );
      double volta() => tester
          .widget<RotationTransition>(
            find.descendant(
              of: find.byKey(CoreKeys.busySpinner),
              matching: find.byType(RotationTransition),
            ),
          )
          .turns
          .value;
      final antes = volta();
      await tester.pump(const Duration(milliseconds: 400));
      expect(volta(), closeTo((antes + .5) % 1, 1e-6));
      await tester.pump(const Duration(milliseconds: 400));
      expect(volta(), closeTo(antes, 1e-6));
    }
  });

  testWidgets('um segundo toque não chama a ação', (tester) async {
    final fim = Completer<void>();
    var toques = 0;
    await tester.pumpWidget(
      tela(
        BotaoCarregando(
          label: 'Comprar',
          onPressed: () {
            toques++;
            return fim.future;
          },
        ),
      ),
    );
    await tester.tap(find.byType(BotaoCarregando));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byType(BotaoCarregando), warnIfMissed: false);
    expect(toques, 1);
    fim.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump();
    expect(find.text('Comprar'), findsOneWidget);
    await tester.tap(find.byType(BotaoCarregando));
    expect(toques, 2);
  });

  testWidgets('movimento reduzido: a troca acontece no primeiro quadro', (
    tester,
  ) async {
    await tester.pumpWidget(
      tela(
        BotaoCarregando(label: 'Comprar', busy: true, onPressed: () {}),
        reduzir: true,
      ),
    );
    expect(find.text('Comprar'), findsNothing);
    expect(find.byKey(CoreKeys.busySpinner), findsOneWidget);
    await tester.pumpWidget(
      tela(
        BotaoCarregando(label: 'Comprar', busy: false, onPressed: () {}),
        reduzir: true,
      ),
    );
    expect(find.text('Comprar'), findsOneWidget);
    expect(find.byKey(CoreKeys.busySpinner), findsNothing);
  });
}
