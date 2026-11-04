import 'package:chessground/chessground.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/motion/tabuleiro_animado.dart';

/// H-ANI-10: o tabuleiro de [boardKey] está dentro do [TabuleiroAnimado] e
/// desliza a peça no tempo do kit (300 ms; nada com movimento reduzido).
void expectTabuleiroAnimado(WidgetTester tester, Key boardKey) {
  final board = find.byKey(boardKey);
  expect(
    find.ancestor(of: board, matching: find.byType(TabuleiroAnimado)),
    findsOneWidget,
  );
  expect(
    tester.widget<Chessboard>(board).settings.animationDuration,
    TabuleiroAnimado.duracaoDoLance(tester.element(board)),
  );
}
