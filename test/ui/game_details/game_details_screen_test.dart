import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/game_details/view_models/game_details_cubit.dart';
import 'package:lucena/ui/game_details/widgets/game_details_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeProgressRepository progress;
  late FakeRatingRepository rating;

  setUp(() {
    progress = FakeProgressRepository();
    rating = FakeRatingRepository();
  });

  // Mate do pastor: as brancas ganham em 7 lances.
  final game = Attempt(
    positionId: 'basic.queen.0001',
    playedAt: DateTime.utc(2026, 10, 5, 12),
    outcome: AttemptOutcome.win,
    fulfilled: true,
    opponent: OpponentKind.maia,
    opponentLevel: 1000,
    startFen: GameRules.initial.fen,
    moves: const ['e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6', 'h5f7'],
    moveTimes: const [
      Duration(seconds: 2),
      Duration(milliseconds: 3400),
      Duration(seconds: 1),
      Duration(seconds: 1),
      Duration(seconds: 65),
      Duration(seconds: 4),
      Duration(milliseconds: 500),
    ],
    userSide: Side.white,
    endReason: GameEndReason.checkmate,
    userTime: const TimeControl(initial: Duration(minutes: 5)),
  );

  Future<GameDetailsCubit> pump(
    WidgetTester tester,
    int id, {
    Size screen = const Size(1080, 4000),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 2.625;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.reset);
    final cubit = GameDetailsCubit(
      id,
      progress: progress,
      rating: rating,
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    // O tabuleiro lê as peças e as cores das preferências.
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: const GameDetailsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  String boardFen(WidgetTester tester) => tester
      .widget<Chessboard>(find.byKey(GameDetailsKeys.board))
      .controller
      .fen;

  String plain(WidgetTester tester, Key key) {
    final text = tester.widget<Text>(find.byKey(key));
    return text.data ?? text.textSpan!.toPlainText();
  }

  for (final (screen, scale) in [
    (const Size(1080, 2400), 1.0),
    (const Size(945, 1680), 1.0),
    (const Size(945, 1680), 1.6),
  ]) {
    testWidgets('T64, $screen × $scale: o tabuleiro no centro do espaço '
        'entre a barra do app e o painel, os botões de lance embaixo dele e '
        'o resto rolando no painel', (tester) async {
      final id = await progress.addAttempt(game);
      await pump(tester, id, screen: screen, textScale: scale);
      final appBar = tester.getRect(find.byType(AppBar));
      final panel = tester.getRect(find.byKey(GameDetailsKeys.panel));
      final board = tester.getRect(find.byKey(GameDetailsKeys.board));
      expect(board.center.dy, closeTo((appBar.bottom + panel.top) / 2, 1));
      expect(find.byKey(GameDetailsKeys.next).hitTestable(), findsOne);
      expect(
        tester.getRect(find.byKey(GameDetailsKeys.next)).bottom,
        lessThanOrEqualTo(panel.top),
      );
      await tester.scrollUntilVisible(
        find.byKey(GameDetailsKeys.move(0)),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byKey(GameDetailsKeys.move(0)));
      await tester.pumpAndSettle();
      expect(find.byKey(GameDetailsKeys.move(0)).hitTestable(), findsOne);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('o cabeçalho diz contra quem, o resultado e o rating', (
    tester,
  ) async {
    final id = await progress.addAttempt(game);
    await rating.rate(game, userSide: Side.white, drawGoal: false, gameId: id);
    await pump(tester, id);

    expect(find.byKey(GameDetailsKeys.screen), findsOneWidget);
    expect(plain(tester, GameDetailsKeys.opponent), 'Coco (1000)');
    expect(plain(tester, GameDetailsKeys.result), 'Win · Checkmate');
    final after = (await rating.history()).single.rating.rounded;
    expect(find.text('$after'), findsOneWidget);
  });

  testWidgets('a tabela traz cada lance com o tempo que levou', (tester) async {
    final id = await progress.addAttempt(game);
    await pump(tester, id);

    for (var index = 0; index < game.moves.length; index++) {
      expect(find.byKey(GameDetailsKeys.move(index)), findsOneWidget);
    }
    expect(plain(tester, GameDetailsKeys.moveTime(0)), '2.0 s');
    expect(plain(tester, GameDetailsKeys.moveTime(1)), '3.4 s');
    // Acima de um minuto, em minutos e segundos.
    expect(plain(tester, GameDetailsKeys.moveTime(4)), '1:05');
    // Numeração das jogadas: 4 linhas para 7 lances.
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('4.'), findsOneWidget);
    expect(find.text('5.'), findsNothing);
  });

  testWidgets('tocar num lance mostra a posição depois dele', (tester) async {
    final id = await progress.addAttempt(game);
    final cubit = await pump(tester, id);
    // Abre na posição de início.
    expect(cubit.state.shownIndex, -1);
    expect(boardFen(tester), cubit.state.start!.fen);

    cubit.last();
    await tester.pumpAndSettle();
    expect(boardFen(tester), cubit.state.moves.last.position.fen);

    await tester.tap(find.byKey(GameDetailsKeys.move(0)));
    await tester.pumpAndSettle();

    expect(cubit.state.shownIndex, 0);
    expect(boardFen(tester), cubit.state.moves.first.position.fen);
    expect(
      Position.setupPosition(
        Rule.chess,
        Setup.parseFen(boardFen(tester)),
      ).board.pieceAt(Square.e4),
      Piece.whitePawn,
    );
  });

  /// O texto do lance [ply] da variante na tabela.
  String variationText(WidgetTester tester, int ply) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(GameDetailsKeys.variationMove(ply)),
          matching: find.byType(Text),
        ),
      )
      .textSpan!
      .toPlainText();

  /// Toca na casa [square] do tabuleiro (brancas embaixo).
  Future<void> tapSquare(WidgetTester tester, Square square) async {
    final rect = tester.getRect(find.byKey(GameDetailsKeys.board));
    final size = rect.width / 8;
    await tester.tapAt(
      rect.topLeft +
          Offset(
            (square.file.value + 0.5) * size,
            (7 - square.rank.value + 0.5) * size,
          ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('um lance no tabuleiro vira variante na tabela; tocar num '
      'lance da partida volta para ela', (tester) async {
    final id = await progress.addAttempt(game);
    final cubit = await pump(tester, id);
    await tester.tap(find.byKey(GameDetailsKeys.move(0)));
    await tester.pumpAndSettle();
    expect(find.byKey(GameDetailsKeys.variation), findsNothing);

    // 1... c5 no lugar de 1... e5.
    await tapSquare(tester, Square.c7);
    await tapSquare(tester, Square.c5);

    expect(cubit.state.inVariation, isTrue);
    final fen = cubit.state.variation.single.position.fen;
    expect(boardFen(tester), fen);
    expect(find.byKey(GameDetailsKeys.variation), findsOneWidget);
    expect(variationText(tester, 0), '(1... c5)');

    // A variante continua: 2. Nf3.
    await tapSquare(tester, Square.g1);
    await tapSquare(tester, Square.f3);
    expect(cubit.state.variation, hasLength(2));
    expect(variationText(tester, 0), '(1... c5');
    expect(variationText(tester, 1), '2. ♘f3)');

    // Tocar num lance da variante mostra a posição dele.
    await tester.tap(find.byKey(GameDetailsKeys.variationMove(0)));
    await tester.pumpAndSettle();
    expect(boardFen(tester), fen);

    // Tocar num lance da partida volta para ela; a variante fica na lista.
    await tester.tap(find.byKey(GameDetailsKeys.move(2)));
    await tester.pumpAndSettle();
    expect(cubit.state.inVariation, isFalse);
    expect(boardFen(tester), cubit.state.moves[2].position.fen);
    expect(find.byKey(GameDetailsKeys.variation), findsOneWidget);
  });

  testWidgets('lance ilegal no tabuleiro não muda nada', (tester) async {
    final id = await progress.addAttempt(game);
    final cubit = await pump(tester, id);
    final before = boardFen(tester);

    // Na posição de início, a dama não anda.
    await tapSquare(tester, Square.d1);
    await tapSquare(tester, Square.d4);
    tester.widget<Chessboard>(find.byKey(GameDetailsKeys.board)).onMove!(
      Move.parse('d1d4')!,
    );
    await tester.pumpAndSettle();

    expect(cubit.state.inVariation, isFalse);
    expect(boardFen(tester), before);
    expect(find.byKey(GameDetailsKeys.variation), findsNothing);
  });

  testWidgets('partida que não existe mais: o aviso', (tester) async {
    await pump(tester, 99);

    expect(find.byKey(GameDetailsKeys.notFound), findsOneWidget);
    expect(find.byKey(GameDetailsKeys.board), findsNothing);
  });
}
