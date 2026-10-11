import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/theme/app_motion.dart';
import 'package:lucena/ui/core/widgets/game_entrance.dart';

void main() {
  const open = Key('open');
  const parts = {
    GameEntrancePart.top: Key('top'),
    GameEntrancePart.bottom: Key('bottom'),
    GameEntrancePart.clock: Key('clock'),
    GameEntrancePart.speech: Key('speech'),
  };

  Widget game() => Column(
    children: [
      for (final MapEntry(key: part, value: key) in parts.entries)
        GameEntrance(
          part: part,
          child: SizedBox(key: key, height: 40, width: 100),
        ),
    ],
  );

  /// Uma tela que abre a partida com a duração e a curva da página da
  /// partida.
  Widget app({bool reduceMotion = false}) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: Builder(
      builder: (context) => TextButton(
        key: open,
        onPressed: () => Navigator.of(context).push(
          PageRouteBuilder<void>(
            transitionDuration: AppMotion.of(context).screen,
            pageBuilder: (_, _, _) => game(),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        child: const SizedBox.square(dimension: 40),
      ),
    ),
  );

  T above<T extends Widget>(WidgetTester tester, Key key) => tester.widget<T>(
    find.ancestor(of: find.byKey(key), matching: find.byType(T)).first,
  );

  double opacity(WidgetTester tester, Key key) =>
      above<Opacity>(tester, key).opacity;

  Offset shift(WidgetTester tester, Key key) =>
      above<FractionalTranslation>(tester, key).translation;

  /// A escala na horizontal (a do relógio é igual nos dois eixos).
  double scale(WidgetTester tester, Key key) =>
      above<Transform>(tester, key).transform.storage[0];

  void expectInPlace(WidgetTester tester) {
    for (final key in parts.values) {
      expect(opacity(tester, key), 1);
    }
    expect(shift(tester, parts[GameEntrancePart.top]!), Offset.zero);
    expect(shift(tester, parts[GameEntrancePart.bottom]!), Offset.zero);
    expect(shift(tester, parts[GameEntrancePart.speech]!), Offset.zero);
    expect(scale(tester, parts[GameEntrancePart.clock]!), 1);
  }

  testWidgets('no meio da entrada, as barras vêm de fora e o relógio cresce', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byKey(open));
    await tester.pump();
    await tester.pump(AppMotion.screen * 0.4);

    // A de cima vem do alto; a de baixo, de baixo; ambas ainda claras.
    final top = parts[GameEntrancePart.top]!;
    final bottom = parts[GameEntrancePart.bottom]!;
    expect(shift(tester, top).dy, lessThan(0));
    expect(shift(tester, bottom).dy, greaterThan(0));
    expect(opacity(tester, top), inExclusiveRange(0, 1));
    expect(opacity(tester, bottom), lessThan(opacity(tester, top)));
    // O relógio e o balão só chegam depois.
    final clock = parts[GameEntrancePart.clock]!;
    expect(opacity(tester, clock), 0);
    expect(scale(tester, clock), closeTo(GameEntrance.clockFrom, 0.001));
    expect(opacity(tester, parts[GameEntrancePart.speech]!), 0);

    await tester.pumpAndSettle();
    expectInPlace(tester);
  });

  testWidgets('aberta sem transição, fica tudo no lugar', (tester) async {
    await tester.pumpWidget(MaterialApp(home: game()));
    expectInPlace(tester);
  });

  testWidgets('com "remover animações", fica tudo no lugar', (tester) async {
    await tester.pumpWidget(app(reduceMotion: true));
    await tester.tap(find.byKey(open));
    await tester.pump();
    expectInPlace(tester);
  });

  testWidgets('na saída, as barras não refazem o caminho', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byKey(open));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(AppMotion.screen * 0.5);
    expectInPlace(tester);
  });
}
