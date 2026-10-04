import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';
import 'package:lucena/ui/free_board/widgets/free_board_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/board_gestures.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FreeBoardCubit cubit;

  Future<void> pumpScreen(
    WidgetTester tester, {
    String? fen,
    Locale locale = const Locale('en'),
    BoardSettings board = const BoardSettings(),
    Side? playerSide,
  }) async {
    // Tela de celular em retrato, como no app.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(AppSettings(board: board)),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    cubit = FreeBoardCubit(
      start: fen == null ? GameRules.initial : GameRules.fromFen(fen)!,
      playerSide: playerSide,
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const FreeBoardScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect boardRect(WidgetTester tester) =>
      tester.getRect(find.byKey(FreeBoardKeys.board));

  /// Toca na casa de origem e depois na de destino.
  Future<void> move(WidgetTester tester, String from, String to) async {
    final orientation = cubit.state.orientation;
    final board = boardRect(tester);
    await tester.tapAt(squareCenter(board, from, orientation: orientation));
    await tester.pump();
    await tester.tapAt(squareCenter(board, to, orientation: orientation));
    await tester.pumpAndSettle();
  }

  Future<void> drag(WidgetTester tester, String from, String to) async {
    final board = boardRect(tester);
    await tester.dragFrom(
      squareCenter(board, from),
      squareCenter(board, to) - squareCenter(board, from),
    );
    await tester.pumpAndSettle();
  }

  Chessboard boardWidget(WidgetTester tester) =>
      tester.widget<Chessboard>(find.byKey(FreeBoardKeys.board));

  String moveText(WidgetTester tester, int index) {
    final text = tester.widget<RichText>(
      find.descendant(
        of: find.byKey(FreeBoardKeys.move(index)),
        matching: find.byType(RichText),
      ),
    );
    return text.text.toPlainText();
  }

  String boardFen(WidgetTester tester) =>
      tester.widget<Chessboard>(find.byKey(FreeBoardKeys.board)).controller.fen;

  String textOf(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  testWidgets('abre na posição inicial, com as brancas para jogar', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(boardFen(tester), GameRules.initial.fen);
    expect(textOf(tester, FreeBoardKeys.turn), 'White to move');
    expect(find.byKey(FreeBoardKeys.noMoves), findsOneWidget);
  });

  testWidgets(
    'o tabuleiro usa as cores, as peças e as coordenadas escolhidas',
    (tester) async {
      await pumpScreen(
        tester,
        board: const BoardSettings(
          colors: BoardColors.green,
          pieces: PieceStyle.merida,
          coordinates: false,
        ),
      );

      final settings = tester
          .widget<Chessboard>(find.byKey(FreeBoardKeys.board))
          .settings;
      expect(settings.colorScheme, ChessboardColorScheme.green);
      expect(settings.pieceAssets, PieceSet.meridaAssets);
      expect(settings.enableCoordinates, isFalse);
    },
  );

  testWidgets('tocar na peça e no destino joga o lance e passa a vez', (
    tester,
  ) async {
    await pumpScreen(tester);

    await move(tester, 'e2', 'e4');

    expect(cubit.state.moves, ['e4']);
    expect(textOf(tester, FreeBoardKeys.turn), 'Black to move');
    expect(find.byKey(FreeBoardKeys.move(0)), findsOneWidget);
    expect(find.byKey(FreeBoardKeys.noMoves), findsNothing);
    expect(boardFen(tester), cubit.state.position.fen);
  });

  testWidgets('arrastar a peça também joga o lance', (tester) async {
    await pumpScreen(tester);
    final board = boardRect(tester);

    await tester.dragFrom(
      squareCenter(board, 'g1'),
      squareCenter(board, 'f3') - squareCenter(board, 'g1'),
    );
    await tester.pumpAndSettle();

    expect(cubit.state.moves, ['Nf3']);
  });

  testWidgets('lance ilegal não muda o tabuleiro nem a lista', (tester) async {
    await pumpScreen(tester);

    await move(tester, 'e2', 'e5');
    await move(tester, 'e7', 'e5');

    expect(boardFen(tester), GameRules.initial.fen);
    expect(cubit.state.moves, isEmpty);
    expect(textOf(tester, FreeBoardKeys.turn), 'White to move');
  });

  testWidgets('a lista mostra a peça em figurino no lugar da letra', (
    tester,
  ) async {
    await pumpScreen(tester);

    await move(tester, 'g1', 'f3');

    final chip = find.byKey(FreeBoardKeys.move(0));
    final text = tester.widget<RichText>(
      find.descendant(of: chip, matching: find.byType(RichText)),
    );
    expect(text.text.toPlainText(), '♘f3');
    expect(tester.getSemantics(chip).label, 'Nf3');
  });

  testWidgets('cada linha tem o número, o lance das brancas e o das pretas', (
    tester,
  ) async {
    await pumpScreen(tester);

    await move(tester, 'e2', 'e4');
    await move(tester, 'e7', 'e5');
    await move(tester, 'g1', 'f3');

    final white1 = tester.getRect(find.byKey(FreeBoardKeys.move(0)));
    final black1 = tester.getRect(find.byKey(FreeBoardKeys.move(1)));
    final white2 = tester.getRect(find.byKey(FreeBoardKeys.move(2)));
    expect(black1.top, white1.top);
    expect(black1.left, greaterThan(white1.left));
    expect(white2.left, white1.left);
    expect(white2.top, greaterThan(white1.top));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('promoção: o seletor aparece e o cavalo escolhido entra', (
    tester,
  ) async {
    await pumpScreen(tester, fen: '8/P6k/8/8/8/8/8/K7 w - - 0 1');

    await move(tester, 'a7', 'a8');
    // O lance só entra depois de escolher a peça no seletor.
    expect(cubit.state.moves, isEmpty);

    await tester.tapAt(
      promotionChoiceCenter(boardRect(tester), 'a8', Role.knight),
    );
    await tester.pumpAndSettle();

    expect(cubit.state.moves, ['a8=N']);
    expect(cubit.state.position.board.roleAt(Square.a8), Role.knight);
  });

  testWidgets('com as pretas começando, a lista abre com reticências', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      fen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
    );

    await move(tester, 'e7', 'e5');

    // A coluna das brancas fica com reticências; o lance vai na das pretas.
    expect(find.text('…', findRichText: true), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(cubit.state.moves, ['e5']);
  });

  testWidgets('mate: mostra o resultado traduzido e trava o tabuleiro', (
    tester,
  ) async {
    // Falta só Dxf7 para o mate do pastor.
    await pumpScreen(
      tester,
      fen:
          'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
      locale: const Locale('pt'),
    );

    await move(tester, 'h5', 'f7');

    expect(textOf(tester, FreeBoardKeys.endReason), 'Xeque-mate');
    expect(textOf(tester, FreeBoardKeys.endResult), 'Vitória das brancas');
    expect(find.byKey(FreeBoardKeys.turn), findsNothing);

    final fen = boardFen(tester);
    await move(tester, 'e8', 'f7');
    expect(boardFen(tester), fen);
  });

  testWidgets('nova partida volta à posição inicial e limpa a lista', (
    tester,
  ) async {
    await pumpScreen(tester);
    await move(tester, 'e2', 'e4');
    await move(tester, 'e7', 'e5');

    await tester.tap(find.byKey(FreeBoardKeys.newGameButton));
    await tester.pumpAndSettle();

    expect(boardFen(tester), GameRules.initial.fen);
    expect(find.byKey(FreeBoardKeys.noMoves), findsOneWidget);
    expect(textOf(tester, FreeBoardKeys.turn), 'White to move');
  });

  testWidgets('no fim, o botão do painel começa outra partida', (tester) async {
    await pumpScreen(
      tester,
      fen:
          'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
    );
    await move(tester, 'h5', 'f7');

    await tester.tap(find.byKey(FreeBoardKeys.endNewGameButton));
    await tester.pumpAndSettle();

    expect(find.byKey(FreeBoardKeys.endPanel), findsNothing);
    expect(cubit.state.moves, isEmpty);
  });

  testWidgets('em árabe o tabuleiro e a lista não espelham', (tester) async {
    await pumpScreen(tester, locale: const Locale('ar'));

    await move(tester, 'e2', 'e4');

    // a1 continua embaixo à esquerda: o lance e2-e4 só vale se não espelhou.
    expect(cubit.state.moves, ['e4']);
    final list = tester.element(find.byKey(FreeBoardKeys.move(0)));
    expect(Directionality.of(list), TextDirection.ltr);
  });

  testWidgets('só tocar: arrastar não move a peça, tocar move', (tester) async {
    await pumpScreen(
      tester,
      board: const BoardSettings(moveMethod: MoveMethod.tap),
    );

    await drag(tester, 'e2', 'e4');
    expect(cubit.state.moves, isEmpty);

    await move(tester, 'g1', 'f3');
    expect(cubit.state.moves, ['Nf3']);
  });

  testWidgets('só arrastar: tocar não move a peça, arrastar move', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      board: const BoardSettings(moveMethod: MoveMethod.drag),
    );

    await move(tester, 'e2', 'e4');
    expect(cubit.state.moves, isEmpty);

    await drag(tester, 'g1', 'f3');
    expect(cubit.state.moves, ['Nf3']);
  });

  testWidgets('ajudas visuais e animação seguem as preferências', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      board: const BoardSettings(
        showLegalMoves: false,
        highlightLastMove: false,
        animation: false,
      ),
    );

    final settings = boardWidget(tester).settings;
    expect(settings.showValidMoves, isFalse);
    expect(settings.showLastMove, isFalse);
    expect(settings.animationDuration, Duration.zero);
  });

  testWidgets('virar o tabuleiro inverte a orientação e mantém a lista', (
    tester,
  ) async {
    await pumpScreen(tester);
    await move(tester, 'e2', 'e4');
    await move(tester, 'e7', 'e5');

    await tester.tap(find.byKey(FreeBoardKeys.flipButton));
    await tester.pumpAndSettle();

    expect(boardWidget(tester).orientation, Side.black);
    expect(cubit.state.moves, ['e4', 'e5']);

    // Com o tabuleiro virado, as casas trocam de lugar na tela.
    await move(tester, 'g1', 'f3');
    expect(cubit.state.moves, ['e4', 'e5', 'Nf3']);
  });

  testWidgets('notação por letras em português mostra C, B, T, D e R', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      fen: '4k3/8/8/8/8/8/8/R1BQKBN1 w - - 0 1',
      locale: const Locale('pt'),
      board: const BoardSettings(notation: MoveNotation.letters),
    );

    await move(tester, 'g1', 'f3');
    await move(tester, 'e8', 'e7');
    await move(tester, 'f1', 'c4');
    await move(tester, 'e7', 'f6');
    await move(tester, 'd1', 'd4');
    await move(tester, 'f6', 'e7');
    await move(tester, 'a1', 'a7');

    expect(
      [for (var i = 0; i < 7; i++) moveText(tester, i)],
      ['Cf3', 'Re7', 'Bc4', 'Rf6', 'Dd4+', 'Re7', 'Ta7+'],
    );
    expect(tester.getSemantics(find.byKey(FreeBoardKeys.move(0))).label, 'Cf3');
  });

  testWidgets('pré-lance: marcado na vez do adversário e jogado em seguida', (
    tester,
  ) async {
    await pumpScreen(tester, playerSide: Side.white);
    await move(tester, 'e2', 'e4');

    // Vez das pretas: o lance das brancas fica só marcado.
    await move(tester, 'd2', 'd4');
    expect(cubit.state.moves, ['e4']);
    expect(boardWidget(tester).controller.premove, NormalMove.fromUci('d2d4'));

    cubit.play(NormalMove.fromUci('e7e5'));
    await tester.pumpAndSettle();

    expect(cubit.state.moves, ['e4', 'e5', 'd4']);
    expect(boardWidget(tester).controller.premove, isNull);
  });

  testWidgets('pré-lance que deixou de ser legal é descartado', (tester) async {
    await pumpScreen(tester, playerSide: Side.white);
    await move(tester, 'e2', 'e4');
    await move(tester, 'e4', 'e5');

    cubit.play(NormalMove.fromUci('e7e5'));
    await tester.pumpAndSettle();

    expect(cubit.state.moves, ['e4', 'e5']);
    expect(boardWidget(tester).controller.premove, isNull);
  });

  testWidgets('com os pré-lances desligados, nada fica marcado', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      playerSide: Side.white,
      board: const BoardSettings(premoves: false),
    );
    await move(tester, 'e2', 'e4');

    await move(tester, 'd2', 'd4');
    expect(boardWidget(tester).controller.premove, isNull);

    cubit.play(NormalMove.fromUci('e7e5'));
    await tester.pumpAndSettle();
    expect(cubit.state.moves, ['e4', 'e5']);
  });

  testWidgets('o jogador de um lado só não move as peças do adversário', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      playerSide: Side.white,
      board: const BoardSettings(premoves: false),
    );
    await move(tester, 'e2', 'e4');

    await move(tester, 'e7', 'e5');

    expect(cubit.state.moves, ['e4']);
  });
}
