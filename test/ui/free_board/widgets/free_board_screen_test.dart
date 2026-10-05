import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/clock_settings.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';
import 'package:lucena/ui/core/widgets/character_avatar.dart';
import 'package:lucena/ui/free_board/view_models/talk_cubit.dart';
import 'package:lucena/ui/free_board/widgets/free_board_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/board_gestures.dart';
import '../../../../testing/fakes/fake_achievements_repository.dart';
import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/fakes/fake_positions_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_evaluation_repository.dart';
import '../../../../testing/fakes/fake_haptics_repository.dart';
import '../../../../testing/fakes/fake_talk_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_opponent_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FreeBoardCubit cubit;
  late FakeNow now;
  late FakeOngoingGameRepository games;
  late FakeOpponentRepository opponent;
  late FakeProgressRepository progress;
  late TalkCubit talk;
  late FakeEvaluationRepository evaluation;
  late FakeTalkRepository talkRepository;

  Future<void> pumpScreen(
    WidgetTester tester, {
    String? fen,
    Locale locale = const Locale('en'),
    BoardSettings board = const BoardSettings(),
    Side? playerSide,
    ClockConfig? clock,
    ClockSettings clockSettings = const ClockSettings(),
    GameSnapshot? saved,
    GameMode mode = const GameMode(),
    AppSettings? appSettings,
    bool withReporter = false,
    Size screen = const Size(1080, 2400),
  }) async {
    // Tela de celular em retrato, como no app.
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final repository = FakeSettingsRepository(
      appSettings ?? AppSettings(board: board, clock: clockSettings),
    );
    final settings = SettingsCubit(
      repository,
      languages: AppLanguage.selectable,
    );
    now = FakeNow(DateTime.utc(2026, 1, 1, 12));
    addTearDown(settings.close);
    await settings.load();
    games = FakeOngoingGameRepository(saved);
    opponent = FakeOpponentRepository(now: now);
    progress = FakeProgressRepository();
    cubit = FreeBoardCubit(
      now: now,
      haptics: FakeHapticsRepository(),
      settings: repository,
      games: games,
      opponent: opponent,
      progress: progress,
      // Com partida gravada, a tela abre para continuar essa partida.
      start: saved != null
          ? null
          : fen == null
          ? GameRules.initial
          : GameRules.fromFen(fen)!,
      playerSide: playerSide,
      clock: clock,
      mode: mode,
      reporter: withReporter
          ? GameReporter(
              rating: FakeRatingRepository(),
              achievements: FakeAchievementsRepository(),
              journey: FakeJourneyRepository(),
              progress: progress,
              speedruns: FakeSpeedrunRepository(progress),
              positions: FakePositionsRepository(),
              now: now,
            )
          : null,
    );
    addTearDown(cubit.close);
    evaluation = FakeEvaluationRepository();
    talkRepository = FakeTalkRepository();
    talk = TalkCubit(
      characters: FakeCharacterRepository(),
      evaluation: evaluation,
      talk: talkRepository,
      settings: repository,
      now: now,
      language: 'en',
      random: Random(1),
    );
    addTearDown(talk.close);
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        settingsCubit: settings,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: talk),
          ],
          child: const FreeBoardScreen(),
        ),
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

  testWidgets('os lances ficam numa faixa no alto, lado a lado, com o número '
      'de cada jogada', (tester) async {
    await pumpScreen(tester);

    await move(tester, 'e2', 'e4');
    await move(tester, 'e7', 'e5');
    await move(tester, 'g1', 'f3');

    final white1 = tester.getRect(find.byKey(FreeBoardKeys.move(0)));
    final black1 = tester.getRect(find.byKey(FreeBoardKeys.move(1)));
    final white2 = tester.getRect(find.byKey(FreeBoardKeys.move(2)));
    // Como no chess.com: todos na mesma linha, um depois do outro.
    expect(black1.center.dy, white1.center.dy);
    expect(white2.center.dy, white1.center.dy);
    expect(black1.left, greaterThan(white1.right - 1));
    expect(white2.left, greaterThan(black1.right - 1));
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    // A faixa fica acima do tabuleiro, logo abaixo da barra do alto.
    expect(white1.bottom, lessThanOrEqualTo(boardRect(tester).top));
  });

  testWidgets('tocar num lance mostra a posição daquele momento, só para ver; '
      'voltar e avançar andam lance a lance', (tester) async {
    await pumpScreen(tester);
    await move(tester, 'e2', 'e4');
    await move(tester, 'e7', 'e5');
    await move(tester, 'g1', 'f3');
    final live = cubit.state.position.fen;

    // O primeiro lance: só o peão do rei saiu.
    await tester.tap(find.byKey(FreeBoardKeys.move(0)));
    await tester.pumpAndSettle();
    expect(cubit.state.browsing, isTrue);
    expect(cubit.state.shownPosition.board.pieceAt(Square.e4), isNotNull);
    expect(cubit.state.shownPosition.board.pieceAt(Square.e5), isNull);
    // A partida não mudou, e mexer nas peças não joga nada.
    await move(tester, 'd7', 'd5');
    expect(cubit.state.position.fen, live);
    expect(cubit.state.moves, ['e4', 'e5', 'Nf3']);

    await tester.tap(find.byKey(FreeBoardKeys.moveNext));
    await tester.pumpAndSettle();
    expect(cubit.state.viewedPly, 2);
    await tester.tap(find.byKey(FreeBoardKeys.movePrevious));
    await tester.tap(find.byKey(FreeBoardKeys.movePrevious));
    await tester.pumpAndSettle();
    // A posição de início: não há mais para onde voltar.
    expect(cubit.state.viewedPly, 0);
    expect(
      tester
          .widget<TextButton>(find.byKey(FreeBoardKeys.movePrevious))
          .onPressed,
      isNull,
    );

    // Avançar até o último lance devolve o tabuleiro à partida.
    for (var step = 0; step < 3; step++) {
      await tester.tap(find.byKey(FreeBoardKeys.moveNext));
      await tester.pumpAndSettle();
    }
    expect(cubit.state.browsing, isFalse);
    expect(
      tester.widget<TextButton>(find.byKey(FreeBoardKeys.moveNext)).onPressed,
      isNull,
    );
    await move(tester, 'b8', 'c6');
    expect(cubit.state.moves, ['e4', 'e5', 'Nf3', 'Nc6']);
  });

  testWidgets('sem lances, não há botões de rever a partida', (tester) async {
    await pumpScreen(tester);

    expect(find.byKey(FreeBoardKeys.noMoves), findsOneWidget);
    expect(find.byKey(FreeBoardKeys.movePrevious), findsNothing);
    expect(find.byKey(FreeBoardKeys.moveNext), findsNothing);
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

    // O número vem com reticências: o primeiro lance é das pretas.
    expect(find.text('1...'), findsOneWidget);
    final number = tester.getRect(find.text('1...'));
    final black = tester.getRect(find.byKey(FreeBoardKeys.move(0)));
    expect(black.center.dy, number.center.dy);
    expect(black.left, greaterThan(number.left));
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

  group('relógio', () {
    const fiveMinutes = TimeControl(initial: Duration(minutes: 5));
    const threeTwo = TimeControl(
      initial: Duration(minutes: 3),
      increment: Duration(seconds: 2),
    );
    const oneZero = TimeControl(initial: Duration(minutes: 1));

    String clockText(WidgetTester tester, Side side) =>
        textOf(tester, FreeBoardKeys.clockTime(side));

    Rect clockRect(WidgetTester tester, Side side) =>
        tester.getRect(find.byKey(FreeBoardKeys.clock(side)));

    /// O relógio do aparelho anda e a tela refaz os tempos no próximo tique.
    Future<void> elapse(WidgetTester tester, Duration duration) async {
      now.advance(duration);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
    }

    Future<void> tap(WidgetTester tester, Key key) async {
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }

    testWidgets('partida sem relógio não mostra relógio nenhum', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byKey(FreeBoardKeys.clock(Side.white)), findsNothing);
      expect(find.byKey(FreeBoardKeys.clock(Side.black)), findsNothing);
    });

    testWidgets('cada lado mostra o seu tempo', (tester) async {
      await pumpScreen(
        tester,
        clock: const ClockConfig(white: oneZero, black: threeTwo),
      );

      expect(clockText(tester, Side.white), '1:00');
      expect(clockText(tester, Side.black), '3:00');
    });

    testWidgets('o tempo de quem joga desconta sozinho na tela', (
      tester,
    ) async {
      await pumpScreen(tester, clock: ClockConfig.same(fiveMinutes));

      await elapse(tester, const Duration(seconds: 7));

      expect(clockText(tester, Side.white), '4:53');
      expect(clockText(tester, Side.black), '5:00');
    });

    testWidgets('incremento de 2 s: depois do lance o relógio soma 2 s', (
      tester,
    ) async {
      await pumpScreen(tester, clock: ClockConfig.same(threeTwo));

      await move(tester, 'e2', 'e4');

      expect(clockText(tester, Side.white), '3:02');
      expect(clockText(tester, Side.black), '3:00');
    });

    testWidgets('abaixo de 10 s aparecem os décimos', (tester) async {
      await pumpScreen(
        tester,
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(seconds: 15)),
        ),
      );
      expect(clockText(tester, Side.white), '0:15');

      await elapse(tester, const Duration(seconds: 5, milliseconds: 500));

      expect(clockText(tester, Side.white), '0:09.5');
      expect(clockText(tester, Side.black), '0:15');
    });

    testWidgets('tempo esgotado: tela de fim e tabuleiro travado', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(seconds: 5)),
        ),
      );

      await elapse(tester, const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(textOf(tester, FreeBoardKeys.endReason), 'Time out');
      expect(textOf(tester, FreeBoardKeys.endResult), 'Black wins');
      expect(clockText(tester, Side.white), '0:00.0');

      await move(tester, 'e2', 'e4');
      expect(cubit.state.moves, isEmpty);
    });

    testWidgets('bandeira contra rei sozinho: empate', (tester) async {
      await pumpScreen(
        tester,
        fen: 'k7/8/8/8/8/8/P7/K7 w - - 0 1',
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(seconds: 5)),
        ),
      );

      await elapse(tester, const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(
        textOf(tester, FreeBoardKeys.endReason),
        'Time out vs. insufficient material',
      );
      expect(textOf(tester, FreeBoardKeys.endResult), 'Draw');
    });

    testWidgets(
      'um de cada lado: pretas em cima, brancas embaixo; vira junto',
      (tester) async {
        await pumpScreen(tester, clock: ClockConfig.same(fiveMinutes));
        final board = boardRect(tester);

        expect(
          clockRect(tester, Side.black).bottom,
          lessThanOrEqualTo(board.top),
        );
        expect(
          clockRect(tester, Side.white).top,
          greaterThanOrEqualTo(board.bottom),
        );

        await tester.tap(find.byKey(FreeBoardKeys.flipButton));
        await tester.pumpAndSettle();

        expect(
          clockRect(tester, Side.white).bottom,
          lessThanOrEqualTo(board.top),
        );
        expect(
          clockRect(tester, Side.black).top,
          greaterThanOrEqualTo(board.bottom),
        );
      },
    );

    testWidgets('os dois em cima: os relógios ficam acima do tabuleiro', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        clock: ClockConfig.same(fiveMinutes),
        clockSettings: const ClockSettings(position: ClockPosition.top),
      );
      final board = boardRect(tester);

      for (final side in Side.values) {
        expect(clockRect(tester, side).bottom, lessThanOrEqualTo(board.top));
      }
      expect(
        clockRect(tester, Side.white).top,
        clockRect(tester, Side.black).top,
      );
    });

    testWidgets('os dois embaixo: os relógios ficam abaixo do tabuleiro', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        clock: ClockConfig.same(fiveMinutes),
        clockSettings: const ClockSettings(position: ClockPosition.bottom),
      );
      final board = boardRect(tester);

      for (final side in Side.values) {
        expect(clockRect(tester, side).top, greaterThanOrEqualTo(board.bottom));
      }
    });

    testWidgets('painel do relógio: escolher 3 min + 2 s começa a partida', (
      tester,
    ) async {
      await pumpScreen(tester);
      await move(tester, 'e2', 'e4');

      await tap(tester, FreeBoardKeys.clockButton);
      expect(find.byKey(FreeBoardKeys.clockSheet), findsOneWidget);
      await tap(tester, FreeBoardKeys.clockEnabledSwitch);
      await tap(tester, FreeBoardKeys.clockMinutes(Side.white, 3));
      await tap(tester, FreeBoardKeys.clockIncrement(Side.white, 2));
      await tap(tester, FreeBoardKeys.clockStartButton);

      expect(find.byKey(FreeBoardKeys.clockSheet), findsNothing);
      expect(cubit.state.clock?.config, ClockConfig.same(threeTwo));
      expect(cubit.state.moves, isEmpty);
      expect(clockText(tester, Side.white), '3:00');
      expect(clockText(tester, Side.black), '3:00');
    });

    testWidgets('painel do relógio: tempos diferentes para cada lado', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tap(tester, FreeBoardKeys.clockButton);
      await tap(tester, FreeBoardKeys.clockEnabledSwitch);
      await tap(tester, FreeBoardKeys.clockSameSwitch);
      await tap(tester, FreeBoardKeys.clockMinutes(Side.white, 1));
      await tap(tester, FreeBoardKeys.clockMinutes(Side.black, 3));
      await tap(tester, FreeBoardKeys.clockIncrement(Side.black, 2));
      await tap(tester, FreeBoardKeys.clockStartButton);

      expect(
        cubit.state.clock?.config,
        const ClockConfig(white: oneZero, black: threeTwo),
      );
      expect(clockText(tester, Side.white), '1:00');
      expect(clockText(tester, Side.black), '3:00');
    });

    testWidgets('painel do relógio fechado sem confirmar não muda a partida', (
      tester,
    ) async {
      await pumpScreen(tester);
      await move(tester, 'e2', 'e4');

      await tap(tester, FreeBoardKeys.clockButton);
      await tap(tester, FreeBoardKeys.clockEnabledSwitch);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.byKey(FreeBoardKeys.clockSheet), findsNothing);
      expect(cubit.state.clock, isNull);
      expect(cubit.state.moves, ['e4']);
    });

    testWidgets('painel do relógio: desligar o relógio tira os relógios', (
      tester,
    ) async {
      await pumpScreen(tester, clock: ClockConfig.same(fiveMinutes));

      await tap(tester, FreeBoardKeys.clockButton);
      await tap(tester, FreeBoardKeys.clockEnabledSwitch);
      await tap(tester, FreeBoardKeys.clockStartButton);

      expect(cubit.state.clock, isNull);
      expect(find.byKey(FreeBoardKeys.clock(Side.white)), findsNothing);
    });
  });

  group('restauração', () {
    testWidgets('enquanto a partida gravada é lida, o tabuleiro não aparece', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        saved: GameSnapshot(
          startFen: GameRules.initial.fen,
          moves: const ['e2e4', 'e7e5'],
        ),
      );

      expect(find.byKey(FreeBoardKeys.screen), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.board), findsNothing);
    });

    testWidgets('a partida gravada volta com a posição, a lista e o relógio', (
      tester,
    ) async {
      const time = TimeControl(initial: Duration(minutes: 5));
      await pumpScreen(
        tester,
        saved: GameSnapshot(
          startFen: GameRules.initial.fen,
          moves: const ['e2e4', 'e7e5'],
          orientation: Side.black,
          clock: ClockState(
            config: ClockConfig.same(time),
            white: const Duration(minutes: 4),
            black: const Duration(minutes: 5),
            running: Side.white,
            // A vez começou 30 s antes de o app reabrir.
            turnStartedAt: DateTime.utc(2026, 1, 1, 11, 59, 30),
          ),
        ),
      );

      await cubit.open();
      await tester.pumpAndSettle();

      expect(cubit.state.moves, ['e4', 'e5']);
      expect(boardFen(tester), cubit.state.position.fen);
      expect(boardWidget(tester).orientation, Side.black);
      expect(textOf(tester, FreeBoardKeys.clockTime(Side.white)), '3:30');
      expect(textOf(tester, FreeBoardKeys.clockTime(Side.black)), '5:00');
      expect(find.byKey(FreeBoardKeys.move(1)), findsOneWidget);
    });
  });

  group('treino', () {
    const vsMachine = GameMode(
      opponent: OpponentKind.stockfish,
      userSide: Side.white,
      goal: PositionGoal.win,
      positionId: 'basic.queen.0001',
    );

    testWidgets('a barra de cima fica só com os botões', (tester) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine,
        locale: const Locale('pt'),
      );

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Ganhar')),
        findsNothing,
      );
    });

    testWidgets('desistir pede confirmação e termina como não cumprido', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine,
      );

      await tester.tap(find.byKey(FreeBoardKeys.resignButton));
      await tester.pumpAndSettle();
      expect(find.byKey(FreeBoardKeys.resignSheet), findsOneWidget);
      await tester.tap(find.byKey(FreeBoardKeys.resignConfirmButton));
      await tester.pumpAndSettle();

      expect(textOf(tester, FreeBoardKeys.endReason), 'Resignation');
      expect(textOf(tester, FreeBoardKeys.endGoal), 'Goal not achieved');
      expect(find.text('Play again'), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.resignButton), findsNothing);
    });

    testWidgets('no fim de um desafio: rating com a variação e o próximo '
        'desafio', (tester) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine.copyWith(
          opponent: OpponentKind.maia,
          level: 1000,
          challengeId: '1000/basic.queen.0001',
        ),
        withReporter: true,
      );

      await tester.tap(find.byKey(FreeBoardKeys.resignButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FreeBoardKeys.resignConfirmButton));
      await tester.pumpAndSettle();

      // O rating fica dentro do painel do fim, com a variação num selo.
      final panel = find.byKey(FreeBoardKeys.endPanel);
      expect(
        find.descendant(
          of: panel,
          matching: find.byKey(FreeBoardKeys.ratingChange),
        ),
        findsOneWidget,
      );
      final delta = find.descendant(
        of: find.byKey(FreeBoardKeys.ratingDelta),
        matching: find.byType(Text),
      );
      expect(tester.widget<Text>(delta).data, startsWith('\u2212'));
      // Perdeu, mas a Jornada segue: o próximo desafio do degrau.
      expect(find.byKey(FreeBoardKeys.endNextButton), findsOneWidget);
      expect(find.text('Next challenge'), findsOneWidget);
    });

    testWidgets('fim: o cartão do resultado abre por cima e, fechado, vira o '
        'painel embaixo do tabuleiro', (tester) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine,
        withReporter: true,
      );

      await tester.tap(find.byKey(FreeBoardKeys.resignButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FreeBoardKeys.resignConfirmButton));
      await tester.pumpAndSettle();

      expect(find.byKey(FreeBoardKeys.resultCard), findsOneWidget);
      expect(textOf(tester, FreeBoardKeys.resultTitle), 'You lost');
      // O rating terminou de contar até o valor novo.
      final value = tester.widget<Text>(find.byKey(FreeBoardKeys.ratingValue));
      expect(int.parse(value.data!), lessThan(1150));

      await tester.tap(find.byKey(FreeBoardKeys.resultClose));
      await tester.pumpAndSettle();
      expect(find.byKey(FreeBoardKeys.resultCard), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(FreeBoardKeys.scrollArea),
          matching: find.byKey(FreeBoardKeys.endPanel),
        ),
        findsOneWidget,
      );
    });

    testWidgets('fora da Jornada, sem botão de próximo desafio', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine,
        withReporter: true,
      );

      await tester.tap(find.byKey(FreeBoardKeys.resignButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FreeBoardKeys.resignConfirmButton));
      await tester.pumpAndSettle();

      expect(find.byKey(FreeBoardKeys.endNextButton), findsNothing);
      expect(find.byKey(FreeBoardKeys.endNewGameButton), findsOneWidget);
    });

    testWidgets('celular pequeno: o tabuleiro ainda ocupa a largura toda e '
        'a parte de baixo rola', (tester) async {
      // 360 x 640, com o relógio dos lados e o personagem.
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1600),
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(minutes: 3)),
        ),
        screen: const Size(720, 1280),
        withReporter: true,
      );
      tester.view.devicePixelRatio = 2;
      await tester.pumpAndSettle();
      await talk.settled();
      await tester.pumpAndSettle();

      expect(boardRect(tester).width, 360);
      await tester.tap(find.byKey(FreeBoardKeys.resignButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FreeBoardKeys.resignConfirmButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // O cartão do resultado cabe na tela pequena.
      expect(
        find.byKey(FreeBoardKeys.endNewGameButton).hitTestable(),
        findsOneWidget,
      );
      // Fechado, o botão do fim é alcançável rolando a parte de baixo.
      await tester.tap(find.byKey(FreeBoardKeys.resultClose));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(FreeBoardKeys.endNewGameButton),
        40,
        scrollable: find
            .descendant(
              of: find.byKey(FreeBoardKeys.scrollArea),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.byKey(FreeBoardKeys.endNewGameButton).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('a tela inteira rola, mas arrastar uma peça não rola', (
      tester,
    ) async {
      // Celular baixo: personagem, dois relógios e o tabuleiro não cabem (a
      // fileira de baixo do tabuleiro fica fora da tela).
      await pumpScreen(
        tester,
        fen: '2Q5/8/8/8/2K5/8/8/5k2 w - - 0 1',
        mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1600),
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(minutes: 3)),
        ),
        board: const BoardSettings(moveMethod: MoveMethod.drag),
        // 360 x 533 na densidade do teste.
        screen: const Size(945, 1400),
      );
      // A posição é refeita quando a rolagem trava e destrava: lida de novo
      // a cada conferência.
      ScrollPosition scroll() => tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(FreeBoardKeys.scrollArea),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      expect(scroll().maxScrollExtent, greaterThan(0));

      // Arrastar a dama no tabuleiro joga o lance e não mexe na tela.
      opponent.hold();
      final board = boardRect(tester);
      final gesture = await tester.startGesture(squareCenter(board, 'c8'));
      await tester.pump();
      for (var step = 1; step <= 6; step++) {
        await gesture.moveBy(
          (squareCenter(board, 'g4') - squareCenter(board, 'c8')) / 6,
        );
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(cubit.state.moves, ['Qg4']);
      expect(scroll().pixels, 0);

      // Arrastar fora do tabuleiro (na linha do adversário) rola a tela.
      await tester.drag(
        find.byKey(FreeBoardKeys.clock(Side.black)),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(scroll().pixels, greaterThan(0));
      opponent.release();
    });

    testWidgets('fechar o painel de desistir não muda nada', (tester) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine,
      );

      await tester.tap(find.byKey(FreeBoardKeys.resignButton));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(cubit.state.end, isNull);
    });

    testWidgets('mate na posição de ganhar: objetivo cumprido', (tester) async {
      await pumpScreen(
        tester,
        fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
        mode: vsMachine,
      );

      await move(tester, 'h1', 'h8');

      expect(textOf(tester, FreeBoardKeys.endGoal), 'Goal achieved!');
      expect(progress.attempts.single.fulfilled, isTrue);
    });

    testWidgets('a máquina responde e o jogador não move as peças dela', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine,
      );

      await move(tester, 'c1', 'g5');
      await tester.pumpAndSettle();

      expect(cubit.state.moves, hasLength(2));
      expect(cubit.state.position.turn, Side.white);
    });
    testWidgets('contra o Maia, o lado dele leva o nome e o nível', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1400),
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(minutes: 3)),
        ),
      );

      expect(find.text('Maia 1400'), findsOneWidget);
      // O lado do jogador leva o apelido (o de fábrica, sem apelido).
      expect(find.text('Player'), findsOneWidget);
      expect(find.text('White'), findsNothing);
      expect(find.text('Black'), findsNothing);
    });

    testWidgets('contra um personagem: retrato e balão numa linha, o relógio '
        'na de baixo, sem cobrir o tabuleiro', (tester) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1600),
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(minutes: 3)),
        ),
      );
      await talk.settled();
      await tester.pumpAndSettle();

      expect(find.byKey(FreeBoardKeys.characterBar), findsOneWidget);
      // O retrato fica só em cima, com o nome para o leitor de tela.
      expect(find.byType(CharacterAvatar), findsOneWidget);
      expect(find.bySemanticsLabel('Valdini'), findsOneWidget);
      expect(
        find.byKey(FreeBoardKeys.speechText('magician.gameStart.1')),
        findsOneWidget,
      );
      final bar = tester.getRect(find.byKey(FreeBoardKeys.characterBar));
      // O relógio da máquina fica numa linha própria, entre o personagem e o
      // tabuleiro.
      final clock = tester.getRect(find.byKey(FreeBoardKeys.clock(Side.black)));
      final board = boardRect(tester);
      expect(clock.top, greaterThanOrEqualTo(bar.bottom));
      expect(clock.bottom, lessThanOrEqualTo(board.top));
      final bubble = tester.getRect(find.byKey(FreeBoardKeys.speechBubble));
      expect(bubble.bottom, lessThanOrEqualTo(board.top));
      // Um respiro entre o retrato e a linha de baixo.
      final avatar = tester.getRect(find.byType(CharacterAvatar));
      expect(bar.bottom - avatar.bottom, greaterThanOrEqualTo(8));
      // O tabuleiro ocupa a largura toda.
      expect(board.width, tester.getSize(find.byType(Scaffold)).width);
    });

    testWidgets('com as falas desligadas, o balão não aparece', (tester) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1600),
        appSettings: const AppSettings(characterTalk: false),
      );
      await talk.settled();
      await tester.pumpAndSettle();

      expect(find.byKey(FreeBoardKeys.characterBar), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.speechBubble), findsNothing);
    });

    testWidgets('contra a máquina sem relógio, a linha de cada lado diz de '
        'quem é a vez, sem o "pensando"', (tester) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1400),
      );
      opponent.hold();

      // A vez do jogador, na linha dele, embaixo do tabuleiro.
      expect(textOf(tester, FreeBoardKeys.turn), 'Your turn');
      expect(
        tester.getCenter(find.byKey(FreeBoardKeys.turn)).dy,
        greaterThan(boardRect(tester).bottom),
      );
      await move(tester, 'c1', 'g5');
      await tester.pump();

      // A vez da máquina, na linha dela, em cima do tabuleiro.
      expect(textOf(tester, FreeBoardKeys.turn), 'Black to move');
      expect(
        tester.getCenter(find.byKey(FreeBoardKeys.turn)).dy,
        lessThan(boardRect(tester).top),
      );

      expect(find.byKey(FreeBoardKeys.machineThinking), findsNothing);
      expect(find.text('Maia 1400 is thinking…'), findsNothing);
      opponent.release();
      await tester.pumpAndSettle();
    });
  });
}
