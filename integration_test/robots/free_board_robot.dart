import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';
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

  /// A partir da tela inicial, já numa posição preparada (FEN). Com [side], o
  /// jogador só move as peças desse lado. Com [white] e [black] (tempo de cada
  /// lado, `segundos+incremento`), a partida abre com relógio.
  ///
  /// No treino, [opponent] (`stockfish`), [user] (o lado do jogador), [goal]
  /// (`win`, `draw`) e [position] (id no catálogo).
  Future<void> openAt(
    String fen, {
    Side? side,
    String? white,
    String? black,
    String? opponent,
    Side? user,
    String? goal,
    String? position,
  }) async {
    final context = $.tester.element(find.byKey(HomeKeys.screen));
    GoRouter.of(context).go(
      Routes.freeBoardAt(
        fen,
        side: side?.name,
        view: user?.name,
        white: white,
        black: black,
        opponent: opponent,
        user: user?.name,
        goal: goal,
        position: position,
      ),
    );
    await $.pumpAndSettle();
    await expectVisible();
  }

  Future<void> expectVisible() async {
    await $(FreeBoardKeys.screen).waitUntilVisible();
    await $(FreeBoardKeys.board).waitUntilVisible();
  }

  void expectNotOpen() {
    expect(find.byKey(FreeBoardKeys.screen), findsNothing);
  }

  /// Sai da partida pela seta da barra superior.
  Future<void> leave() async {
    await $(BackButton).tap();
    await $.pumpAndSettle();
  }

  /// Toca na casa de origem e depois na de destino (`e2`, `e4`).
  Future<void> move(String from, String to) async {
    await $.tester.tapAt(_square(from));
    await $.pump();
    await $.tester.tapAt(_square(to));
    await $.pumpAndSettle();
  }

  /// Arrasta a peça da casa de origem até a de destino e solta.
  Future<void> drag(String from, String to) async {
    final start = _square(from);
    await $.tester.dragFrom(start, _square(to) - start);
    await $.pumpAndSettle();
  }

  /// O adversário (que ainda não existe no app) joga um lance, em UCI (`e7e5`).
  Future<void> opponentPlays(String uci) async {
    final context = $.tester.element(find.byKey(FreeBoardKeys.board));
    context.read<FreeBoardCubit>().play(NormalMove.fromUci(uci));
    await $.pumpAndSettle();
  }

  /// Abre o painel do relógio, escolhe o mesmo tempo para os dois lados e
  /// começa a partida.
  Future<void> startClock({
    required int minutes,
    required int increment,
  }) async {
    await $(FreeBoardKeys.clockButton).tap();
    await $(FreeBoardKeys.clockSheet).waitUntilVisible();
    await $(FreeBoardKeys.clockEnabledSwitch).tap();
    await $(FreeBoardKeys.clockMinutes(Side.white, minutes)).scrollTo().tap();
    await $(FreeBoardKeys.clockIncrement(Side.white, increment))
        .scrollTo()
        .tap();
    await $(FreeBoardKeys.clockStartButton).tap();
    await $.pumpAndSettle();
    expect(find.byKey(FreeBoardKeys.clockSheet), findsNothing);
  }

  /// Abre o painel do relógio e deixa o relógio ligado, sem confirmar.
  Future<void> openClockSheet() async {
    await $(FreeBoardKeys.clockButton).tap();
    await $(FreeBoardKeys.clockSheet).waitUntilVisible();
    await $(FreeBoardKeys.clockEnabledSwitch).tap();
    await $.pumpAndSettle();
  }

  /// O tempo escrito no relógio de um lado (`3:02`, `0:09.5`).
  Future<void> expectClock(Side side, String time) async {
    await $(
      find.descendant(
        of: find.byKey(FreeBoardKeys.clock(side)),
        matching: find.text(time),
      ),
    ).waitUntilVisible();
  }

  void expectNoClock() {
    expect(find.byKey(FreeBoardKeys.clock(Side.white)), findsNothing);
    expect(find.byKey(FreeBoardKeys.clock(Side.black)), findsNothing);
  }

  /// O relógio de [side] está acima ou abaixo do tabuleiro.
  void expectClockAbove(Side side) {
    final clock = $.tester.getRect(find.byKey(FreeBoardKeys.clock(side)));
    expect(clock.bottom, lessThanOrEqualTo(_board.top));
  }

  void expectClockBelow(Side side) {
    final clock = $.tester.getRect(find.byKey(FreeBoardKeys.clock(side)));
    expect(clock.top, greaterThanOrEqualTo(_board.bottom));
  }

  /// Desiste pelo botão da barra e confirma no painel.
  Future<void> resign() async {
    await $(FreeBoardKeys.resignButton).tap();
    await $(FreeBoardKeys.resignConfirmButton).waitUntilVisible();
    await $(FreeBoardKeys.resignConfirmButton).tap();
    await $.pumpAndSettle();
  }

  /// O resultado do treino no painel do fim.
  Future<void> expectGoalResult(String text) async {
    await $(FreeBoardKeys.endGoal).waitUntilVisible();
    expect(_text(FreeBoardKeys.endGoal), text);
  }

  /// "Jogar de novo" (no treino) ou "Nova partida", no painel do fim.
  Future<void> playAgain() async {
    await $(FreeBoardKeys.endNewGameButton).tap();
    await $.pumpAndSettle();
  }

  Future<void> flip() async {
    await $(FreeBoardKeys.flipButton).tap();
    await $.pumpAndSettle();
  }

  /// O lado que está embaixo no tabuleiro.
  void expectOrientation(Side side) {
    expect(_chessboard.orientation, side);
  }

  /// O lance que ficou marcado para depois da resposta do adversário.
  void expectPremove(String? uci) {
    expect(_chessboard.controller.premove?.uci, uci);
  }

  void expectShowsLegalMoves({required bool enabled}) {
    expect(_chessboard.settings.showValidMoves, enabled);
  }

  /// Os lances como aparecem escritos na lista (`♘f3` ou `Cf3`).
  Future<void> expectMoveTexts(List<String> texts) async {
    await $(FreeBoardKeys.move(texts.length - 1)).waitUntilVisible();
    final shown = [
      for (var index = 0; index < texts.length; index++)
        $.tester
            .widget<RichText>(
              find.descendant(
                of: find.byKey(FreeBoardKeys.move(index)),
                matching: find.byType(RichText),
              ),
            )
            .text
            .toPlainText(),
    ];
    expect(shown, texts);
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
    expect(_chessboard.controller.fen, fen);
  }

  /// A aparência com que o tabuleiro de jogo está desenhado.
  void expectAppearance({
    required BoardColors colors,
    required PieceStyle pieces,
    required bool coordinates,
  }) {
    final settings = _chessboard.settings;
    expect(settings.colorScheme, colors.scheme);
    expect(settings.pieceAssets, pieces.assets);
    expect(settings.enableCoordinates, coordinates);
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

  Chessboard get _chessboard =>
      $.tester.widget<Chessboard>(find.byKey(FreeBoardKeys.board));

  Rect get _board => $.tester.getRect(find.byKey(FreeBoardKeys.board));

  // Onde a casa está na tela, com o tabuleiro virado ou não.
  Offset _square(String square) =>
      squareCenter(_board, square, orientation: _chessboard.orientation);
}
