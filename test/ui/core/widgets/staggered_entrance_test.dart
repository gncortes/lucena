import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/staggered_entrance.dart';

void main() {
  double opacity(WidgetTester tester, int index) => tester
      .widget<FadeTransition>(
        find.descendant(
          of: find.byKey(ValueKey(index)),
          matching: find.byType(FadeTransition),
        ),
      )
      .opacity
      .value;

  Widget list({bool reduceMotion = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Column(
        children: [
          for (final index in [0, 3])
            StaggeredEntrance(
              key: ValueKey(index),
              index: index,
              child: Text('$index'),
            ),
        ],
      ),
    ),
  );

  testWidgets('os itens entram em cascata', (tester) async {
    await tester.pumpWidget(list());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // O primeiro já está entrando; o quarto ainda espera a vez dele.
    expect(opacity(tester, 0), greaterThan(0));
    expect(opacity(tester, 3), 0);

    await tester.pumpAndSettle();
    expect(opacity(tester, 0), 1);
    expect(opacity(tester, 3), 1);
  });

  testWidgets('com "remover animações", tudo entra pronto', (tester) async {
    await tester.pumpWidget(list(reduceMotion: true));

    expect(opacity(tester, 0), 1);
    expect(opacity(tester, 3), 1);
  });
}
