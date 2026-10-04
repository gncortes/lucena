import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/free_board/widgets/move_list.dart';
import 'package:patrol/patrol.dart';

import '../../testing/board_gestures.dart';

/// Tela do tabuleiro livre. As casas são tocadas pela posição no tabuleiro.
class FreeBoardRobot {
  const FreeBoardRobot(this.$);

  final PatrolIntegrationTester $;

  /// A partir da tela inicial, pelo botão.
  Future<void> open() async {
    await $(HomeKeys.freeBoardButton).scrollTo().tap();
    await expectVisible();
  }

  /// A partir da tela inicial, já numa posição preparada (FEN).
  Future<void> openAt(String fen) async {
    final context = $.tester.element(find.byKey(HomeKeys.screen));
    GoRouter.of(context).go(Routes.freeBoardAt(fen));
    await $.pumpAndSettle();
    await expectVisible();
  }

  Future<void> expectVisible() async {
    await $(FreeBoardKeys.screen).waitUntilVisible();
    await $(FreeBoardKeys.board).waitUntilVisible();
  }

  /// Toca na casa de origem e depois na de destino (`e2`, `e4`).
  Future<void> move(String from, String to) async {
    await $.tester.tapAt(squareCenter(_board, from));
    await $.pump();
    await $.tester.tapAt(squareCenter(_board, to));
    await $.pumpAndSettle();
  }

  /// Arrasta a peça da casa de origem até a de destino e solta.
  Future<void> drag(String from, String to) async {
    final start = squareCenter(_board, from);
    await $.tester.dragFrom(start, squareCenter(_board, to) - start);
    await $.pumpAndSettle();
  }

  /// Escolhe a peça no seletor de promoção aberto na casa [square].
  Future<void> promoteTo(String square, Role role) async {
    await $.tester.tapAt(promotionChoiceCenter(_board, square, role));
    await $.pumpAndSettle();
  }

  Future<void> newGame() async {
    await $(FreeBoardKeys.newGameButton).tap();
    await $.pumpAndSettle();
  }

  /// A posição que o tabuleiro está mostrando.
  void expectFen(String fen) {
    final board = $.tester.widget<Chessboard>(find.byKey(FreeBoardKeys.board));
    expect(board.controller.fen, fen);
  }

  /// A lista de lances, em notação algébrica, com cada lance visível na tela.
  Future<void> expectMoves(List<String> moves) async {
    if (moves.isEmpty) {
      await $(FreeBoardKeys.noMoves).waitUntilVisible();
      return;
    }
    await $(FreeBoardKeys.move(moves.length - 1)).waitUntilVisible();
    expect($.tester.widget<MoveList>(find.byType(MoveList)).moves, moves);
    expect(find.byKey(FreeBoardKeys.move(moves.length)), findsNothing);
  }

  void expectTurn(String text) {
    expect($.tester.widget<Text>(find.byKey(FreeBoardKeys.turn)).data, text);
  }

  Future<void> expectEnd({
    required String reason,
    required String result,
  }) async {
    await $(FreeBoardKeys.endPanel).waitUntilVisible();
    expect(_text(FreeBoardKeys.endReason), reason);
    expect(_text(FreeBoardKeys.endResult), result);
  }

  String? _text(Key key) => $.tester.widget<Text>(find.byKey(key)).data;

  Rect get _board => $.tester.getRect(find.byKey(FreeBoardKeys.board));
}
