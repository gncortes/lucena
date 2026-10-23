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
import 'package:lucena_ui/lucena_ui.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_game_review_repository.dart';
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

  String boardFen(WidgetTester tester) => tester
      .widget<Chessboard>(find.byKey(GameDetailsKeys.board))
      .controller
      .fen;

  String plain(WidgetTester tester, Key key) {
    final text = tester.widget<Text>(find.byKey(key));
    return text.data ?? text.textSpan!.toPlainText();
  }

  double sheetTop(WidgetTester tester) =>
      tester.getTopLeft(find.byKey(GameDetailsKeys.panel)).dy;

  testWidgets(
    'o painel da análise é a folha padrão (`surfaceContainerLow`), sem '
    'cartões com cor própria',
    (tester) async {
      final id = await progress.addAttempt(game);
      await pump(tester, id, screen: const Size(1080, 2400));
      final surface = Theme.of(
        tester.element(find.byKey(GameDetailsKeys.panel)),
      ).colorScheme.surfaceContainerLow;
      final sheet = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.byKey(GameDetailsKeys.panel),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((sheet.decoration as BoxDecoration).color, surface);
      final cards = tester.widgetList<Card>(find.byType(Card));
      expect(cards, isNotEmpty);
      for (final card in cards) {
        expect(card.color, Colors.transparent);
        expect(card.elevation, 0);
      }
    },
  );

  testWidgets('a folha: recolhida embaixo do tabuleiro; puxada, sobe por '
      'cima dele com o x; o x a desce de volta', (tester) async {
    final id = await progress.addAttempt(game);
    await pump(tester, id, screen: const Size(1080, 2400));
    final board = tester.getRect(find.byKey(GameDetailsKeys.board));
    final appBar = tester.getRect(find.byType(AppBar));
    final collapsed = sheetTop(tester);
    // Recolhida: o tabuleiro inteiro acima dela, no centro do espaço, e os
    // botões de lance à vista; o x escondido.
    expect(board.bottom, lessThanOrEqualTo(collapsed));
    expect(
      board.center.dy,
      closeTo((appBar.bottom + collapsed) / 2, AppSpacing.xxl * 2),
    );
    expect(find.byKey(GameDetailsKeys.next).hitTestable(), findsOne);
    expect(find.byKey(GameDetailsKeys.closeSheet).hitTestable(), findsNothing);

    // Puxada para cima: cobre o tabuleiro e o x aparece.
    await tester.drag(find.byKey(GameDetailsKeys.panel), const Offset(0, -600));
    await tester.pumpAndSettle();
    final open = sheetTop(tester);
    expect(open, lessThan(board.center.dy));
    expect(find.byKey(GameDetailsKeys.closeSheet).hitTestable(), findsOne);

    // O x desce a folha de uma vez.
    await tester.tap(find.byKey(GameDetailsKeys.closeSheet));
    await tester.pumpAndSettle();
    expect(sheetTop(tester), closeTo(collapsed, 1));
    expect(find.byKey(GameDetailsKeys.closeSheet).hitTestable(), findsNothing);
    expect(find.byKey(GameDetailsKeys.next).hitTestable(), findsOne);
  });

  testWidgets('folha rolada até a legenda e fechada pelo x: o conteúdo volta '
      'ao topo e puxar de novo abre a folha', (tester) async {
    final id = await progress.addAttempt(game);
    await pump(tester, id, screen: const Size(1080, 2400));
    final collapsed = sheetTop(tester);
    final panel = find.byKey(GameDetailsKeys.panel);
    // Abre e rola até a legenda.
    await tester.drag(panel, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.fling(panel, const Offset(0, -1500), 3000);
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(
      find.descendant(of: panel, matching: find.byType(Scrollable)),
    );
    expect(scroll.position.pixels, greaterThan(0));

    await tester.tap(find.byKey(GameDetailsKeys.closeSheet));
    await tester.pumpAndSettle();
    expect(sheetTop(tester), closeTo(collapsed, 1));
    expect(scroll.position.pixels, 0);

    // Puxar o conteúdo (ou a alça) abre de novo, com o x.
    await tester.drag(panel, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(sheetTop(tester), lessThan(collapsed - 100));
    expect(find.byKey(GameDetailsKeys.closeSheet).hitTestable(), findsOne);
  });

  for (final screen in const [Size(945, 1680), Size(720, 1280)]) {
    testWidgets('tela pequena ($screen) com fonte 1,6: nada estoura, os '
        'botões de lance ficam à vista e, com a folha aberta, tudo rola até a '
        'legenda', (tester) async {
      final id = await progress.addAttempt(game);
      await pump(tester, id, screen: screen, textScale: 1.6);
      expect(tester.takeException(), isNull);
      expect(find.byKey(GameDetailsKeys.board), findsOne);
      expect(find.byKey(GameDetailsKeys.next).hitTestable(), findsOne);
      expect(
        tester.getRect(find.byKey(GameDetailsKeys.next)).bottom,
        lessThanOrEqualTo(sheetTop(tester)),
      );

      await tester.drag(
        find.byKey(GameDetailsKeys.panel),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(GameDetailsKeys.closeSheet).hitTestable(), findsOne);
      // Dentro da folha aberta, a tabela inteira chega à vista rolando.
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

  testWidgets('toque na folha abre até 76 dp do topo sem mover o tabuleiro', (
    tester,
  ) async {
    final id = await progress.addAttempt(game);
    await pump(tester, id, screen: const Size(1080, 2400));
    final board = tester.getRect(find.byKey(GameDetailsKeys.board));
    final panel = find.byKey(GameDetailsKeys.panel);
    await tester.tapAt(tester.getTopLeft(panel) + const Offset(40, 12));
    await tester.pumpAndSettle();
    final appBar = tester.getRect(find.byType(AppBar));
    expect(
      sheetTop(tester),
      // Aberta, a folha para 76 dp abaixo do topo da área (LICOES-V2 §5).
      closeTo(appBar.bottom + 76, 1),
    );
    expect(tester.getRect(find.byKey(GameDetailsKeys.board)), board);
    expect(
      find.byKey(GameDetailsKeys.closeSheet).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('o cabeçalho diz contra quem, o resultado e o rating', (
    tester,
  ) async {
    final id = await progress.addAttempt(game);
    await rating.rate(game, userSide: Side.white, drawGoal: false, gameId: id);
    await pump(tester, id);

    expect(find.byKey(GameDetailsKeys.screen), findsOneWidget);
    expect(plain(tester, GameDetailsKeys.opponent), 'Coco (1000)');
    expect(plain(tester, GameDetailsKeys.result), 'Win · Checkmate');
    // O placar fecha a lista de lances, só com a notação.
    await tester.scrollUntilVisible(
      find.byKey(GameDetailsKeys.score),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(plain(tester, GameDetailsKeys.score), '1–0');
    final after = (await rating.history()).single.rating.rounded;
    expect(find.text('$after'), findsOneWidget);
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
            await tester.drag(panel, const Offset(0, -1000));
            await tester.pumpAndSettle();
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
