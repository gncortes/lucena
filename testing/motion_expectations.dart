import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/movimento_reduzido.dart';
import 'package:lucena/ui/core/motion/tabuleiro_animado.dart';
import 'package:lucena/ui/core/motion/tabuleiro_hero.dart';

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

/// H-ANI-11/12: o retorno do lance está sobre o tabuleiro de [boardKey], com a
/// casa pintada e o selo ([Icons.check] no acerto, [Icons.close] no erro) na
/// peça.
void expectRetornoDoLance(
  WidgetTester tester,
  Key boardKey, {
  required bool acerto,
}) {
  expect(
    find.ancestor(
      of: find.byKey(boardKey),
      matching: find.byKey(MotionKeys.tabuleiroDoRetorno),
    ),
    findsOneWidget,
  );
  expect(find.byKey(MotionKeys.corDaCasa), findsOneWidget);
  Finder selo(IconData icone) => find.descendant(
    of: find.byKey(MotionKeys.seloNaPeca),
    matching: find.byIcon(icone),
  );
  expect(selo(acerto ? Icons.check : Icons.close), findsOneWidget);
  expect(selo(acerto ? Icons.close : Icons.check), findsNothing);
}

/// Sem retorno do lance na tela.
void expectSemRetornoDoLance() {
  expect(find.byKey(MotionKeys.tabuleiroDoRetorno), findsNothing);
}

/// H-ANI-02: o tabuleiro de [boardKey] está no [TabuleiroHero] de [id]; sem
/// movimento reduzido, o `Hero` tem a marca `tabuleiro-<id>`.
void expectTabuleiroHero(WidgetTester tester, Key boardKey, String id) {
  final hero = find.ancestor(
    of: find.byKey(boardKey),
    matching: find.byType(TabuleiroHero),
  );
  expect(hero, findsOneWidget);
  expect(tester.widget<TabuleiroHero>(hero).id, id);
  final reduzido = MovimentoReduzido.of(tester.element(find.byKey(boardKey)));
  expect(
    find.ancestor(
      of: find.byKey(boardKey),
      matching: find.byWidgetPredicate(
        (w) => w is Hero && w.tag == TabuleiroHero.tag(id),
      ),
    ),
    reduzido ? findsNothing : findsOneWidget,
  );
}
