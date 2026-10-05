import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/core/keys/rating_keys.dart';
import 'package:lucena/ui/core/widgets/rating_chart.dart';
import 'package:lucena/ui/profile/view_models/rating_cubit.dart';
import 'package:lucena/ui/profile/widgets/rating_screen.dart';

import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FakeProgressRepository progress;
  late FakeRatingRepository rating;

  setUp(() {
    progress = FakeProgressRepository();
    rating = FakeRatingRepository();
  });

  /// Joga [outcomes] contra o Maia 1000, da mais antiga para a mais recente.
  Future<void> play(List<AttemptOutcome> outcomes) async {
    for (final (index, outcome) in outcomes.indexed) {
      final game = Attempt(
        positionId: 'basic.queen.0001',
        playedAt: DateTime.utc(2026, 10, 5, 12, index),
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

  Future<void> pumpScreen(WidgetTester tester, {Locale? locale}) async {
    // Tela de celular: o histórico cabe embaixo do gráfico.
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        locale: locale ?? const Locale('en'),
        child: BlocProvider(
          create: (_) => RatingCubit(rating, progress: progress)..load(),
          child: const RatingScreen(),
        ),
      ),
    );
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

    // A mais recente em cima: vitória, com o rating de agora e a subida.
    expect(
      find.descendant(
        of: find.byKey(RatingKeys.entry(0)),
        matching: find.text('Win'),
      ),
      findsOneWidget,
    );
    expect(
      textOf(tester, RatingKeys.entryRating(0)),
      '${history.last.rating.rounded}',
    );
    expect(textOf(tester, RatingKeys.entryChange(0)), startsWith('+'));
    expect(
      find.descendant(
        of: find.byKey(RatingKeys.entry(1)),
        matching: find.text('Loss'),
      ),
      findsOneWidget,
    );
    expect(textOf(tester, RatingKeys.entryChange(1)), startsWith('−'));
    // A primeira partida não tem variação (o ponto de partida não é gravado).
    expect(find.byKey(RatingKeys.entry(2)), findsOneWidget);
    expect(find.byKey(RatingKeys.entryChange(2)), findsNothing);
    expect(find.textContaining('Maia 1000'), findsNWidgets(3));
  });

  testWidgets('o período escolhe quantas partidas o gráfico mostra', (
    tester,
  ) async {
    await play([
      for (var game = 0; game < 12; game++)
        game.isEven ? AttemptOutcome.win : AttemptOutcome.loss,
    ]);
    await pumpScreen(tester);

    List<double> charted() =>
        tester.widget<RatingChart>(find.byKey(RatingKeys.chart)).ratings;
    expect(charted(), hasLength(12));

    await tester.tap(find.byKey(RatingKeys.period(10)));
    await tester.pumpAndSettle();
    expect(charted(), hasLength(10));

    await tester.tap(find.byKey(RatingKeys.period(null)));
    await tester.pumpAndSettle();
    expect(charted(), hasLength(12));
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
}
