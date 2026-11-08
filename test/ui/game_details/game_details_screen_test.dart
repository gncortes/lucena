import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucena/domain/models/game_review.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/ui/core/review/move_quality_ui.dart';
import 'package:lucena/ui/core/widgets/figurine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
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

import '../../../testing/board_center.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_game_review_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';
import '../../../testing/motion_expectations.dart';

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
    GameReview? review,
    ThemeMode themeMode = ThemeMode.light,
    bool reducedMotion = false,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 2.625;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.reset);
    final reviews = FakeGameReviewRepository();
    if (review != null) reviews.reviews[id] = review;
    final cubit = GameDetailsCubit(
      id,
      reviews: reviews,
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
        themeMode: themeMode,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reducedMotion),
            child: BlocProvider.value(
              value: cubit,
              child: const GameDetailsScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  Future<void> openMoves(WidgetTester tester) async {
    await tester.tap(find.byKey(GameDetailsKeys.tabMoves));
    await tester.pumpAndSettle();
  }

  String boardFen(WidgetTester tester) => tester
      .widget<Chessboard>(find.byKey(GameDetailsKeys.board))
      .controller
      .fen;

  String plain(WidgetTester tester, Key key) {
    final text = tester.widget<Text>(find.byKey(key));
    return text.data ?? text.textSpan!.toPlainText();
  }

  testWidgets('layout: tabuleiro na largura toda, abas Resumo/Lances/Motor e '
      'a navegação fixa embaixo', (tester) async {
    final id = await progress.addAttempt(game);
    await pump(tester, id, screen: const Size(1080, 2400));
    final board = tester.getRect(find.byKey(GameDetailsKeys.board));
    final tabs = tester.getRect(find.byKey(GameDetailsKeys.tabSummary));
    final next = tester.getRect(find.byKey(GameDetailsKeys.next));
    final panel = tester.getRect(find.byKey(GameDetailsKeys.panel));
    expect(board.bottom, lessThanOrEqualTo(tabs.top));
    expect(tabs.bottom, lessThanOrEqualTo(panel.top));
    expect(panel.bottom, lessThanOrEqualTo(next.top));
    expect(find.byKey(GameDetailsKeys.tabMoves), findsOne);
    expect(find.byKey(GameDetailsKeys.tabEngine), findsOne);
  });

  testWidgetsA8('A8: tabuleiro no centro útil e de ponta a ponta', (
    tester,
  ) async {
    final id = await progress.addAttempt(game);
    await pump(tester, id);
    setCentroAparelho(tester);
    await tester.pumpAndSettle();
    debugPrint('A8 game_details fora do centro: ${foraDoCentro(tester)}');
    expectTabuleiroNoCentro(tester);
    // As abas e a lista ficam com a sobra de baixo, acima da navegação.
    final board = tester.getRect(find.byKey(GameDetailsKeys.board));
    final tabs = tester.getRect(find.byKey(GameDetailsKeys.tabSummary));
    final panel = tester.getRect(find.byKey(GameDetailsKeys.panel));
    final next = tester.getRect(find.byKey(GameDetailsKeys.next));
    expect(board.bottom, lessThanOrEqualTo(tabs.top));
    expect(panel.bottom, lessThanOrEqualTo(next.top));
    expect(panel.height, greaterThan(0));
    expect(tester.takeException(), isNull);
  }, pendente360x740: true);

  testWidgets('H-ANI-10: o tabuleiro dos detalhes é o TabuleiroAnimado', (
    tester,
  ) async {
    final id = await progress.addAttempt(game);
    await pump(tester, id, screen: const Size(1080, 2400));
    expectTabuleiroAnimado(tester, GameDetailsKeys.board);
  });

  testWidgets('cada aba tem o próprio conteúdo: Resumo o cartão, Lances a '
      'tabela e Motor liga a engine', (tester) async {
    final id = await progress.addAttempt(game);
    await pump(tester, id, screen: const Size(1080, 2400));
    // A8: com o tabuleiro no centro, o cartão fica mais abaixo na lista.
    await tester.scrollUntilVisible(
      find.byKey(GameDetailsKeys.opponent),
      200,
      scrollable: find.descendant(
        of: find.byKey(GameDetailsKeys.panel),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(GameDetailsKeys.opponent), findsOne);
    expect(find.byKey(GameDetailsKeys.move(0)), findsNothing);

    await tester.tap(find.byKey(GameDetailsKeys.tabMoves));
    await tester.pumpAndSettle();
    expect(find.byKey(GameDetailsKeys.move(0)), findsOne);
    expect(find.byKey(GameDetailsKeys.opponent), findsNothing);

    await tester.tap(find.byKey(GameDetailsKeys.tabEngine));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(GameDetailsKeys.move(0)), findsNothing);
    expect(find.byKey(GameDetailsKeys.engineLines), findsOne);
  });

  for (final screen in const [Size(945, 1680), Size(720, 1280)]) {
    testWidgets('tela pequena ($screen) com fonte 1,6: nada estoura, os '
        'botões de lance ficam à vista e a tabela rola até o fim', (
      tester,
    ) async {
      final id = await progress.addAttempt(game);
      await pump(tester, id, screen: screen, textScale: 1.6);
      expect(tester.takeException(), isNull);
      expect(find.byKey(GameDetailsKeys.board), findsOne);
      expect(find.byKey(GameDetailsKeys.next).hitTestable(), findsOne);
      await tester.tap(find.byKey(GameDetailsKeys.tabMoves));
      await tester.pumpAndSettle();
      final last = find.byKey(GameDetailsKeys.move(game.moves.length - 1));
      await tester.scrollUntilVisible(
        last,
        200,
        scrollable: find.descendant(
          of: find.byKey(GameDetailsKeys.panel),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(last.hitTestable(), findsOne);
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
    expect(plain(tester, GameDetailsKeys.opponent), 'Against Coco (1000)');
    expect(plain(tester, GameDetailsKeys.result), 'Win · Checkmate');
    final after = (await rating.history()).single.rating.rounded;
    expect(find.text('$after'), findsOneWidget);
    // O placar fecha a lista de lances, só com a notação.
    await openMoves(tester);
    await tester.scrollUntilVisible(
      find.byKey(GameDetailsKeys.score),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(plain(tester, GameDetailsKeys.score), '1–0');
  });

  final qualities = [
    MoveQuality.forced,
    MoveQuality.great,
    MoveQuality.best,
    MoveQuality.good,
    MoveQuality.inaccuracy,
    MoveQuality.mistake,
    MoveQuality.blunder,
  ];
  final presentationReview = GameReview(
    moves: [
      for (final quality in qualities)
        ReviewedMove(
          before: const EngineScore(centipawns: 0),
          after: const EngineScore(centipawns: 0),
          quality: quality,
          accuracy: 100,
        ),
    ],
  );

  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(412, 915),
  ]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets(
          'B7b $size $mode fonte$scale: SAN legível e tempos alinhados',
          (tester) async {
            final id = await progress.addAttempt(game);
            final cubit = await pump(
              tester,
              id,
              screen: size * 2.625,
              textScale: scale,
              review: presentationReview,
              themeMode: mode,
              reducedMotion: true,
            );
            final panel = find.byKey(GameDetailsKeys.panel);
            await openMoves(tester);
            await tester.scrollUntilVisible(
              find.byKey(GameDetailsKeys.move(0)),
              150,
              scrollable: find.descendant(
                of: panel,
                matching: find.byType(Scrollable),
              ),
            );
            await tester.pumpAndSettle();
            final rightEdges = <double>[];
            for (var i = 0; i < game.moves.length; i++) {
              final cell = find.byKey(GameDetailsKeys.move(i));
              expect(
                find.descendant(
                  of: cell,
                  matching: find.byType(MoveQualityBadge),
                ),
                findsNothing,
              );
              final sanFinder = find.byKey(GameDetailsKeys.moveQuality(i));
              final san = tester.widget<Text>(sanFinder);
              final quality = qualities[i];
              final rendered = san.textSpan!.toPlainText();
              final expected = cubit.state.moves[i].san
                  .split('')
                  .map((char) => Figurine.ofLetter[char] ?? char)
                  .join();
              expect(rendered, '$expected${quality.listAnnotation}');
              if (quality == MoveQuality.best ||
                  quality == MoveQuality.forced) {
                expect(rendered, expected);
              }
              if (quality == MoveQuality.great) expect(rendered, endsWith('!'));
              if (quality == MoveQuality.blunder) {
                expect(rendered, endsWith('??'));
              }
              expect(san.strutStyle!.forceStrutHeight, isTrue);
              expect(rendered, isNot(contains('□')));
              expect(rendered, isNot(contains('✓')));
              final context = tester.element(sanFinder);
              final theme = Theme.of(context);
              expect(san.style!.color, quality.listColor(theme.brightness));
              double contrast(Color a, Color b) {
                final aa = a.computeLuminance(), bb = b.computeLuminance();
                return ((aa > bb ? aa : bb) + .05) /
                    ((aa < bb ? aa : bb) + .05);
              }

              expect(
                contrast(
                  san.style!.color!,
                  theme.colorScheme.surfaceContainerLow,
                ),
                greaterThanOrEqualTo(4.5),
              );
              expect(
                contrast(
                  san.style!.color!,
                  theme.colorScheme.secondaryContainer,
                ),
                greaterThanOrEqualTo(4.5),
              );
              for (final value in MoveQuality.values) {
                expect(
                  contrast(
                    value.listColor(theme.brightness),
                    theme.colorScheme.surfaceContainerLow,
                  ),
                  greaterThanOrEqualTo(4.5),
                );
                expect(
                  contrast(
                    value.listColor(theme.brightness),
                    theme.colorScheme.secondaryContainer,
                  ),
                  greaterThanOrEqualTo(4.5),
                );
              }
              final paragraph = tester.renderObject<RenderParagraph>(sanFinder);
              final glyphs = paragraph.getBoxesForSelection(
                TextSelection(baseOffset: 0, extentOffset: rendered.length),
              );
              expect(
                glyphs.last.right,
                lessThanOrEqualTo(paragraph.size.width + .5),
              );
              final sanRect = tester.getRect(sanFinder);
              final clockRect = tester.getRect(
                find.byKey(GameDetailsKeys.moveTime(i)),
              );
              expect(sanRect.overlaps(clockRect), isFalse);
              expect(
                clockRect.right,
                lessThanOrEqualTo(tester.getRect(cell).right),
              );
              rightEdges.add(clockRect.right);
              final semanticWidget = tester.widget<Semantics>(
                find
                    .ancestor(
                      of: cell,
                      matching: find.byWidgetPredicate(
                        (widget) =>
                            widget is Semantics &&
                            widget.properties.button == true,
                      ),
                    )
                    .first,
              );
              final semantics = semanticWidget.properties.label!;
              expect(semanticWidget.properties.onTap, isNotNull);
              expect(
                semantics,
                contains(quality.label(AppLocalizations.of(context))),
              );
              expect(
                semantics,
                contains(plain(tester, GameDetailsKeys.moveTime(i))),
              );
            }
            // Cada lado tem sua própria coluna fixa; se empilhados, a coluna é única.
            for (var i = 2; i < rightEdges.length; i++) {
              expect(rightEdges[i], closeTo(rightEdges[i - 2], .5));
            }
            final cell = find.byKey(GameDetailsKeys.move(0));
            final container = tester.widget<AnimatedContainer>(
              find
                  .descendant(
                    of: cell,
                    matching: find.byType(AnimatedContainer),
                  )
                  .first,
            );
            expect(container.duration, Duration.zero);
            cubit.select(0);
            await tester.pumpAndSettle();
            final selected = tester.widget<AnimatedContainer>(
              find
                  .descendant(
                    of: cell,
                    matching: find.byType(AnimatedContainer),
                  )
                  .first,
            );
            final border =
                (selected.decoration! as BoxDecoration).border! as Border;
            expect(border.top.color, isNot(Colors.transparent));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('a tabela traz cada lance com o tempo que levou', (tester) async {
    final id = await progress.addAttempt(game);
    await pump(tester, id);
    await openMoves(tester);

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
    await openMoves(tester);
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
    await openMoves(tester);
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

    // Toque e segure abre o menu do lance; apagar corta a partir dele.
    expect(find.byKey(GameDetailsKeys.variationHint), findsNothing);
    await tester.longPress(find.byKey(GameDetailsKeys.variationMove(1)));
    await tester.pumpAndSettle();
    expect(find.byKey(GameDetailsKeys.moveMenu), findsOneWidget);
    await tester.tap(find.byKey(GameDetailsKeys.menuDelete));
    await tester.pumpAndSettle();
    expect(cubit.state.variation, hasLength(1));
    await tapSquare(tester, Square.g1);
    await tapSquare(tester, Square.f3);
    expect(cubit.state.variation, hasLength(2));

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

  testWidgets(
    'H-PAR-17 partida que não existe mais: título e aviso do quadro',
    (tester) async {
      await pump(tester, 99);
      final t = lookupAppLocalizations(const Locale('en'));

      expect(find.byKey(LoadErrorKeys.screen), findsNothing);
      expect(find.text(t.partidaAnaliseTitulo), findsOneWidget);
      expect(find.text(t.gameDetailsNotFound), findsOneWidget);
      expect(find.byKey(GameDetailsKeys.notFound), findsOneWidget);
      expect(find.byKey(GameDetailsKeys.board), findsNothing);
    },
  );
}
