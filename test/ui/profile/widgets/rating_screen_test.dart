import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/rating_period.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/rating_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';
import 'package:lucena/ui/core/widgets/rating_chart.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/profile/view_models/rating_cubit.dart';
import 'package:lucena/ui/profile/widgets/rating_screen.dart';

import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/test_app.dart';
import 'one_line_check.dart';

void main() {
  late FakeProgressRepository progress;
  late FakeRatingRepository rating;
  // As partidas começam em 5/10 às 12h; "agora" é logo depois da última.
  late FakeNow now;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 10, 5, 13));
    progress = FakeProgressRepository();
    rating = FakeRatingRepository();
  });

  /// Joga [outcomes] contra o Maia 1000, da mais antiga para a mais recente,
  /// uma por minuto ou, com [daysApart], uma a cada tantos dias (a última
  /// em 5/10 às 12h).
  Future<void> play(List<AttemptOutcome> outcomes, {int? daysApart}) async {
    final last = DateTime.utc(2026, 10, 5, 12);
    for (final (index, outcome) in outcomes.indexed) {
      final game = Attempt(
        positionId: 'basic.queen.0001',
        playedAt: daysApart == null
            ? last.add(Duration(minutes: index))
            : last.subtract(
                Duration(days: daysApart * (outcomes.length - 1 - index)),
              ),
        outcome: outcome,
        fulfilled: outcome == AttemptOutcome.win,
        opponent: OpponentKind.maia,
        opponentLevel: 1000,
      );
      final id = await progress.addAttempt(game);
      await rating.rate(
        game,
        userSide: Side.white,
        drawGoal: false,
        gameId: id,
      );
    }
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    Locale? locale,
    double width = 600,
    int? highlightedGame,
  }) async {
    // Tela de celular larga (a fonte de teste é mais larga que a real): o
    // histórico cabe embaixo do gráfico.
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        locale: locale ?? const Locale('en'),
        child: BlocProvider(
          create: (_) => RatingCubit(
            rating,
            progress: progress,
            now: now,
            highlightedGame: highlightedGame,
          )..load(),
          child: const RatingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Abre o filtro do período e escolhe [period] no painel.
  Future<void> choose(WidgetTester tester, RatingPeriod period) async {
    final button = find.byKey(RatingKeys.periods);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RatingKeys.period(period.name)));
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  testWidgets('sem partidas: o rating de partida, sem gráfico, e o convite', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(textOf(tester, RatingKeys.value), '1150');
    expect(find.byKey(RatingKeys.chart), findsNothing);
    expect(find.byKey(RatingKeys.emptyHistory), findsOneWidget);
    // Os números do jogador, zerados.
    expect(find.byKey(RatingKeys.stats), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(RatingKeys.stat(0)),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('com partidas: o gráfico e o histórico, da mais recente para a '
      'mais antiga, com a variação de cada uma', (tester) async {
    await play([AttemptOutcome.win, AttemptOutcome.loss, AttemptOutcome.win]);
    await pumpScreen(tester);
    final history = await rating.history();

    expect(textOf(tester, RatingKeys.value), '${history.last.rating.rounded}');
    expect(textOf(tester, RatingKeys.games), '3 rated games');
    // Partidas e vitórias nos números do jogador.
    for (final (index, value, label) in [(0, '3', 'Games'), (1, '2', 'Wins')]) {
      final stat = find.byKey(RatingKeys.stat(index));
      expect(find.descendant(of: stat, matching: find.text(value)), findsOne);
      expect(find.descendant(of: stat, matching: find.text(label)), findsOne);
    }
    expect(find.byKey(RatingKeys.chart), findsOneWidget);
    expect(find.byKey(RatingKeys.emptyHistory), findsNothing);

    String? result(int index) => tester
        .widget<Icon>(
          find.descendant(
            of: find.byKey(RatingKeys.entryResult(index)),
            matching: find.byType(Icon),
          ),
        )
        .semanticLabel;
    expect(textOf(tester, RatingKeys.gamesCount), '3');
    // A mais recente em cima: vitória, com o rating de agora e a subida.
    expect(result(0), 'Win');
    expect(
      textOf(tester, RatingKeys.entryRating(0)),
      '${history.last.rating.rounded}',
    );
    expect(textOf(tester, RatingKeys.entryChange(0)), startsWith('+'));
    expect(result(1), 'Loss');
    expect(textOf(tester, RatingKeys.entryChange(1)), startsWith('−'));
    // A primeira partida só tem o rating: não há variação (o ponto de
    // partida não é gravado).
    expect(find.byKey(RatingKeys.entry(2)), findsOneWidget);
    expect(find.byKey(RatingKeys.entryChange(2)), findsNothing);
    expect(
      textOf(tester, RatingKeys.entryRating(2)),
      '${history.first.rating.rounded}',
    );
    // O adversário em cada linha, enxuta.
    expect(
      find.textContaining('Maia 1000', findRichText: true),
      findsNWidgets(3),
    );
    // Sem o selo de provisório.
    expect(find.text('Provisional'), findsNothing);
  });

  testWidgets('o mais alto e a barra de vitórias, empates e derrotas', (
    tester,
  ) async {
    await play([AttemptOutcome.win, AttemptOutcome.win, AttemptOutcome.loss]);
    await pumpScreen(tester);
    final history = await rating.history();

    final highest = history
        .map((entry) => entry.rating.rounded)
        .reduce((a, b) => a > b ? a : b);
    expect(
      find.descendant(
        of: find.byKey(RatingKeys.highest),
        matching: find.text('$highest'),
      ),
      findsOneWidget,
    );
    final results = find.byKey(RatingKeys.results);
    expect(results, findsOneWidget);
    expect(find.descendant(of: results, matching: find.text('2')), findsOne);
    expect(find.descendant(of: results, matching: find.text('1')), findsOne);
    expect(
      find.descendant(of: results, matching: find.text('Win · 67%')),
      findsOne,
    );
  });

  testWidgets('tocar numa partida do histórico abre os detalhes dela', (
    tester,
  ) async {
    await play([AttemptOutcome.win, AttemptOutcome.loss]);
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: Routes.rating,
      routes: [
        GoRoute(
          path: Routes.rating,
          builder: (context, state) => BlocProvider(
            create: (_) =>
                RatingCubit(rating, progress: progress, now: now)..load(),
            child: const RatingScreen(),
          ),
          routes: [
            GoRoute(
              path: 'game/:id',
              builder: (context, state) =>
                  Text('game ${state.pathParameters['id']}'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => ProfileCubit(FakeProfileRepository())..load(),
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.of(Brightness.light),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A mais recente em cima: a segunda partida gravada.
    await tester.tap(find.byKey(RatingKeys.entry(0)));
    await tester.pumpAndSettle();

    expect(find.text('game 2'), findsOneWidget);
  });

  testWidgets('o período escolhe os dias que o gráfico mostra', (tester) async {
    // Uma partida a cada 10 dias, a última hoje.
    await play([
      for (var game = 0; game < 12; game++)
        game.isEven ? AttemptOutcome.win : AttemptOutcome.loss,
    ], daysApart: 10);
    await pumpScreen(tester);

    List<double> charted() =>
        tester.widget<RatingChart>(find.byKey(RatingKeys.chart)).ratings;
    // Abre com tudo.
    expect(charted(), hasLength(12));

    // 30 dias: as 3 partidas do período e a de antes, de onde ele partiu.
    await choose(tester, RatingPeriod.month);
    expect(charted(), hasLength(4));

    await choose(tester, RatingPeriod.week);
    expect(charted(), hasLength(2));

    await choose(tester, RatingPeriod.all);
    expect(charted(), hasLength(12));
  });

  testWidgets('período sem partidas avisa no lugar do gráfico', (tester) async {
    await play([AttemptOutcome.win, AttemptOutcome.loss], daysApart: 1);
    now.advance(const Duration(days: 60));
    await pumpScreen(tester);

    await choose(tester, RatingPeriod.week);

    expect(find.byKey(RatingKeys.chart), findsNothing);
    expect(find.byKey(RatingKeys.chartEmpty), findsOneWidget);
  });

  testWidgets('tocar e arrastar no gráfico marca uma partida, sem erro, no '
      'escuro e em árabe', (tester) async {
    await play([
      for (var game = 0; game < 20; game++)
        game % 3 == 0 ? AttemptOutcome.loss : AttemptOutcome.win,
    ]);
    await pumpScreen(tester, locale: const Locale('ar'));

    final chart = find.byKey(RatingKeys.chart);
    await tester.tapAt(tester.getCenter(chart));
    await tester.pump();
    await tester.drag(chart, const Offset(80, 0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(RatingKeys.entry(0)), findsOneWidget);
  });

  testWidgets('a barra de resultados: uma só, na proporção, com a contagem e '
      'a porcentagem de cada parte embaixo', (tester) async {
    await play([
      AttemptOutcome.win,
      AttemptOutcome.win,
      AttemptOutcome.draw,
      AttemptOutcome.loss,
    ]);
    await pumpScreen(tester);

    final bar = find.byKey(RatingKeys.resultsBar);
    final parts = tester
        .widgetList<ColoredBox>(
          find.descendant(of: bar, matching: find.byType(ColoredBox)),
        )
        .toList();
    expect(parts, hasLength(3));
    final widths = [
      for (final box
          in find
              .descendant(of: bar, matching: find.byType(ColoredBox))
              .evaluate())
        box.size!.width,
    ];
    // Cada parte com a altura da barra (sem esticar, a cor some).
    for (final box
        in find
            .descendant(of: bar, matching: find.byType(ColoredBox))
            .evaluate()) {
      expect(box.size!.height, tester.getSize(bar).height);
    }
    // Vitórias, empates e derrotas: 2, 1 e 1.
    expect(widths[0], closeTo(widths[1] * 2, 1));
    expect(widths[1], closeTo(widths[2], 1));
    expect(
      widths.reduce((a, b) => a + b),
      closeTo(tester.getSize(bar).width, 1),
    );
    for (final (name, count, label) in [
      ('win', '2', 'Win · 50%'),
      ('draw', '1', 'Draw · 25%'),
      ('loss', '1', 'Loss · 25%'),
    ]) {
      final part = find.byKey(RatingKeys.resultsPart(name));
      expect(find.descendant(of: part, matching: find.text(count)), findsOne);
      expect(find.descendant(of: part, matching: find.text(label)), findsOne);
      // Os números logo embaixo da barra.
      expect(
        tester.getTopLeft(part).dy,
        greaterThan(tester.getBottomLeft(bar).dy),
      );
    }
    // Sem espaço vazio em cima: o título logo no alto do cartão.
    final card = tester.getRect(find.byKey(RatingKeys.results));
    final title = tester.getRect(find.text('Results'));
    expect(title.top - card.top, lessThan(24));
  });

  testWidgets('o período fica num botão de filtro: abre em "tudo", o painel '
      'marca o escolhido e o botão mostra o novo', (tester) async {
    await play([
      for (var game = 0; game < 6; game++)
        game.isEven ? AttemptOutcome.win : AttemptOutcome.loss,
    ], daysApart: 10);
    await pumpScreen(tester);

    String buttonLabel() => tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(RatingKeys.periods),
            matching: find.byType(Text),
          ),
        )
        .data!;
    expect(buttonLabel(), 'All');

    await tester.tap(find.byKey(RatingKeys.periods));
    await tester.pumpAndSettle();
    expect(find.text('Period'), findsOneWidget);
    expect(
      tester.widget<ListTile>(find.byKey(RatingKeys.period('all'))).selected,
      isTrue,
    );
    await tester.tap(find.byKey(RatingKeys.period(RatingPeriod.month.name)));
    await tester.pumpAndSettle();

    expect(find.text('Period'), findsNothing);
    expect(buttonLabel(), '30 days');
  });

  testWidgets('a explicação fica no ⓘ, não no fim da tela', (tester) async {
    await play([AttemptOutcome.win, AttemptOutcome.loss]);
    await pumpScreen(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byKey(RatingKeys.screen)),
    );

    expect(find.text(l10n.profileRatingHint), findsNothing);
    await tester.tap(find.byKey(RatingKeys.help));
    await tester.pumpAndSettle();
    expect(find.byKey(RatingKeys.helpText), findsOneWidget);
    expect(textOf(tester, RatingKeys.helpText), l10n.profileRatingHint);
  });

  testWidgets('o histórico começa com o cabeçalho e a última partida sai de '
      'trás da barra do sistema', (tester) async {
    await play([
      for (var game = 0; game < 12; game++)
        game.isEven ? AttemptOutcome.win : AttemptOutcome.draw,
    ]);
    tester.view.padding = const FakeViewPadding(bottom: 48);
    await pumpScreen(tester, width: 412);
    // Altura de celular: a lista tem que rolar.
    tester.view.physicalSize = const Size(412, 800);
    await tester.pumpAndSettle();

    final header = find.byKey(RatingKeys.historyHeader);
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: header, matching: find.text('Game history')),
      findsOne,
    );
    expect(
      find.descendant(of: header, matching: find.byKey(RatingKeys.gamesCount)),
      findsOne,
    );
    expect(textOf(tester, RatingKeys.gamesCount), '12');

    // Rola até o fim: a última partida acima da barra de navegação.
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    final last = tester.getRect(find.byKey(RatingKeys.entry(11)));
    expect(last.bottom, lessThanOrEqualTo(800 - 48));
  });

  const locales = [
    Locale('pt'),
    Locale('de'),
    Locale('ar'),
    Locale('en', 'XA'),
  ];
  for (final width in [320.0, 412.0]) {
    for (final locale in locales) {
      testWidgets('em $locale, ${width.round()} dp: números, resultados e '
          'períodos sem quebrar nem estourar', (tester) async {
        await play([
          AttemptOutcome.win,
          AttemptOutcome.draw,
          AttemptOutcome.loss,
          AttemptOutcome.win,
        ], daysApart: 3);
        await pumpScreen(tester, locale: locale, width: width);

        expect(tester.takeException(), isNull);
        expectNoWrappedText(tester, find.byKey(RatingKeys.stats));
        expectNoWrappedText(tester, find.byKey(RatingKeys.results));
        expectNoWrappedText(tester, find.byKey(RatingKeys.periods));
        // Grade de 2 × 2 com os cartões da mesma altura.
        final first = tester.getRect(find.byKey(RatingKeys.stat(0)));
        for (var index = 1; index < 4; index++) {
          expect(
            tester.getSize(find.byKey(RatingKeys.stat(index))).height,
            closeTo(first.height, 0.01),
          );
        }
        expect(tester.getRect(find.byKey(RatingKeys.stat(1))).top, first.top);
      });
    }
  }

  group('vindo da conclusão (T51 B)', () {
    // Três partidas: a do meio é de outro final.
    Future<List<int>> playMixed() async {
      final ids = <int>[];
      final last = DateTime.utc(2026, 10, 5, 12);
      for (final (index, position) in [
        'basic.queen.0001',
        'basic.rook.0001',
        'basic.queen.0001',
      ].indexed) {
        final game = Attempt(
          positionId: position,
          playedAt: last.add(Duration(minutes: index)),
          outcome: AttemptOutcome.win,
          fulfilled: true,
          opponent: OpponentKind.maia,
          opponentLevel: 1000,
        );
        final id = await progress.addAttempt(game);
        ids.add(id);
        await rating.rate(
          game,
          userSide: Side.white,
          drawGoal: false,
          gameId: id,
        );
      }
      return ids;
    }

    testWidgets('a partida em destaque: a linha tingida e o ponto no '
        'gráfico', (tester) async {
      final ids = await playMixed();
      await pumpScreen(tester, highlightedGame: ids[1]);

      // A mais recente é a 0; a do meio, a 1.
      expect(
        find.descendant(
          of: find.byKey(RatingKeys.entryHighlighted),
          matching: find.byKey(RatingKeys.entry(1)),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<RatingChart>(find.byKey(RatingKeys.chart)).highlighted,
        1,
      );
    });

    testWidgets('id que não existe: nada em destaque', (tester) async {
      await playMixed();
      await pumpScreen(tester, highlightedGame: 999);

      expect(find.byKey(RatingKeys.entryHighlighted), findsNothing);
      expect(
        tester.widget<RatingChart>(find.byKey(RatingKeys.chart)).highlighted,
        isNull,
      );
    });
  });
}
