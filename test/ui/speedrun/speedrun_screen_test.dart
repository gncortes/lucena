import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/domain/use_cases/clock_format.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/history/widgets/history_labels.dart';
import 'package:lucena/ui/core/widgets/time_display.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/test_app.dart';

/// A tela de um speedrun de final: a trilha dos adversários e o histórico.
void main() {
  const id = 'ending.queen';
  late FakeNow now;
  late FakeProgressRepository progress;
  late FakeSpeedrunRepository speedruns;
  late FakeOngoingGameRepository games;
  late SpeedrunCubit cubit;
  final started = <int, String>{};

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 10, 4, 12));
    progress = FakeProgressRepository();
    speedruns = FakeSpeedrunRepository(progress);
    games = FakeOngoingGameRepository();
    cubit = SpeedrunCubit(
      journey: FakeJourneyRepository(),
      speedruns: speedruns,
      games: games,
      now: now,
      characters: FakeCharacterRepository(),
      rating: FakeRatingRepository(now: now)..speedrunOf = (id) => started[id]!,
    );
  });
  tearDown(() => cubit.close());

  Future<void> win(int attempt, int stage, int seconds) => progress.addAttempt(
    Attempt(
      positionId: 'basic.queen.0001',
      playedAt: now(),
      outcome: AttemptOutcome.win,
      fulfilled: true,
      opponent: OpponentKind.maia,
      userClock: Duration(seconds: seconds),
      speedrunAttemptId: attempt,
      speedrunStage: stage,
    ),
  );

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(400, 3000),
    double scale = 1,
    ThemeMode mode = ThemeMode.light,
    String? speedrunId,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await cubit.load(speedrunId: speedrunId ?? id);
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        themeMode: mode,
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: BlocProvider.value(
            value: cubit,
            child: const SpeedrunScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<int> start() async {
    await cubit.load(speedrunId: id);
    final (speedrun, attempt) = (await cubit.startWith(
      SpeedrunPaces.standard,
    ))!;
    started[attempt] = speedrun.id;
    return attempt;
  }

  /// Uma tentativa concluída, 10 s por etapa.
  Future<int> finished() async {
    final attempt = await start();
    final total = cubit.state.selected!.speedrun.stages.length;
    for (var stage = 0; stage < total; stage++) {
      now.advance(const Duration(minutes: 1));
      await win(attempt, stage, 10);
    }
    return attempt;
  }

  /// Uma que venceu uma etapa e foi abandonada.
  Future<int> gaveUp() async {
    final attempt = await start();
    await win(attempt, 0, 20);
    now.advance(const Duration(minutes: 5));
    await speedruns.abandon(attempt, now());
    return attempt;
  }

  String stageText(WidgetTester tester, int index) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(SpeedrunKeys.stageCard(index)),
          matching: find.byType(Text),
        ),
      )
      .map((text) => text.data)
      .join(' | ');

  String textOf(WidgetTester tester, Key key) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(Text),
          matchRoot: true,
        ),
      )
      .map((text) => text.data)
      .join(' | ');

  testWidgets('a trilha mostra os adversários em ordem, do mais fraco ao '
      'Stockfish, sem tempo por etapa e sem tentativas', (tester) async {
    await pump(tester);
    final stages = cubit.state.selected!.speedrun.stages;

    expect(stageText(tester, 0), startsWith('Coco | Stage 1 of'));
    expect(
      stageText(tester, stages.length - 1),
      startsWith('Stockfish | Stage ${stages.length} of'),
    );
    final tops = [
      for (var index = 0; index < stages.length; index++)
        tester.getTopLeft(find.byKey(SpeedrunKeys.stageCard(index))).dy,
    ];
    expect(tops, [...tops]..sort());
    expect(find.byKey(SpeedrunKeys.stageTime(0)), findsNothing);
    expect(find.text('Now'), findsNothing);
    expect(find.byKey(SpeedrunKeys.recordCard), findsNothing);
    expect(find.byKey(SpeedrunKeys.start), findsOneWidget);
  });

  testWidgets(
    'nunca concluiu e sem tentativa: a oferta por ritmo e o convite',
    (tester) async {
      await pump(tester);

      expect(cubit.state.offer, greaterThan(0));
      expect(find.byKey(SpeedrunKeys.ratingBonusOffer), findsOneWidget);
      expect(
        textOf(tester, SpeedrunKeys.ratingBonusOffer),
        contains(HistoryLabels.ltr('+${cubit.state.offer}')),
      );
      expect(find.byKey(SpeedrunKeys.bestAttempt), findsNothing);
      // Com a oferta, o convite não aparece.
      expect(find.text('Your first time will show up here'), findsNothing);
    },
  );

  testWidgets('nunca concluiu: a melhor tentativa é a etapa mais longe', (
    tester,
  ) async {
    await gaveUp();
    final second = await start();
    await win(second, 0, 20);
    await win(second, 1, 20);
    now.advance(const Duration(minutes: 5));
    await speedruns.abandon(second, now());
    final total = cubit.state.selected!.speedrun.stages.length;

    await pump(tester);

    expect(
      textOf(tester, SpeedrunKeys.bestAttempt),
      contains('Best attempt: stage 3 of $total'),
    );
    expect(find.byKey(SpeedrunKeys.ratingBonusOffer), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.recordCard), findsNothing);
    expect(find.byKey(SpeedrunKeys.start), findsOneWidget);
  });

  testWidgets('em um ritmo sem bônus, a oferta some', (tester) async {
    const classical = TimeControl(initial: Duration(minutes: 30));
    final slow = SpeedrunPaces.idFor(id, classical);
    await pump(tester, speedrunId: slow);

    expect(cubit.state.offer, 0);
    expect(find.byKey(SpeedrunKeys.ratingBonusOffer), findsNothing);
    expect(find.text('Your first time will show up here'), findsOneWidget);
  });

  testWidgets('com o recorde: o cartão, o link do histórico e a oferta some '
      'depois de paga', (tester) async {
    final total = (await () async {
      await cubit.load(speedrunId: id);
      return cubit.state.selected!.speedrun.stages.length;
    }());
    await gaveUp();
    await finished();
    now.advance(const Duration(minutes: 5));

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              BlocProvider.value(value: cubit, child: const SpeedrunScreen()),
        ),
        GoRoute(path: '/:a/:b/:c', builder: (_, _) => const Text('histórico')),
      ],
    );
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await cubit.load(speedrunId: id);
    await tester.pumpWidget(
      TestApp(router: router, child: const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();

    final best = tester.widget<TimeDisplay>(
      find.ancestor(
        of: find.byKey(SpeedrunKeys.best),
        matching: find.byType(TimeDisplay),
      ),
    );
    expect(best.type, TimeDisplayType.record);
    expect(best.size, TimeDisplaySize.pill);
    expect(best.state, TimeDisplayState.highlight);
    expect(best.value, RunTimeFormat.clock(Duration(seconds: total * 10)));
    expect(best.semanticsLabel, 'Your record: ${best.value}');
    expect(find.byKey(SpeedrunKeys.recordCard), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.seeHistory), findsOneWidget);
    // O link fica encostado no fim do cartão (16 de margem + 8 de padding).
    final card = tester.getRect(find.byKey(SpeedrunKeys.recordCard));
    final link = tester.getRect(
      find.descendant(
        of: find.byKey(SpeedrunKeys.seeHistory),
        matching: find.byIcon(Icons.chevron_right),
      ),
    );
    expect(card.right - link.right, lessThan(24));
    // A lista de tentativas saiu do detalhe; a conclusão já pagou o bônus.
    expect(find.text('Gave up at stage 2 of $total'), findsNothing);
    expect(cubit.state.offer, 0);
    expect(find.byKey(SpeedrunKeys.ratingBonusOffer), findsNothing);
    expect(find.byKey(SpeedrunKeys.start), findsOneWidget);

    await tester.tap(find.byKey(SpeedrunKeys.seeHistory));
    await tester.pumpAndSettle();
    expect(find.text('histórico'), findsOneWidget);
  });

  testWidgets('tentativa em andamento: o cartão, o tempo, o "+N" e o '
      'Continuar com a etapa', (tester) async {
    final attempt = await start();
    await win(attempt, 0, 20);
    await win(attempt, 1, 25);
    games.snapshot = GameSnapshot(
      startFen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
      mode: GameMode(speedrunId: started[attempt]!, speedrunAttemptId: attempt),
    );

    await pump(tester);

    final total = cubit.state.selected!.speedrun.stages.length;
    expect(find.byKey(SpeedrunKeys.ongoingCard), findsOneWidget);
    final card = textOf(tester, SpeedrunKeys.ongoingCard);
    expect(card, contains('Attempt in progress'));
    expect(card, contains('Time so far: 0:45.0'));
    expect(cubit.state.ongoingOffer, greaterThan(0));
    final offer = tester.widget<Text>(
      find.descendant(
        of: find.byKey(SpeedrunKeys.ongoingOffer),
        matching: find.byType(Text),
      ),
    );
    expect(
      offer.textSpan!.toPlainText(),
      contains('+${cubit.state.ongoingOffer} rating'),
    );
    // Sem o cartão verde da oferta nem o recorde.
    expect(find.byKey(SpeedrunKeys.ratingBonusOffer), findsNothing);
    expect(find.byKey(SpeedrunKeys.recordCard), findsNothing);
    expect(find.text('Now'), findsNothing);
    expect(find.byKey(SpeedrunKeys.stageTime(0)), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.stageTime(2)), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(SpeedrunKeys.resume),
        matching: find.text('Continue · stage 3 of $total'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(SpeedrunKeys.start), findsNothing);
  });

  testWidgets('Maratona: o título da barra é a seção, sem "Maratona:" no '
      'nome', (tester) async {
    final marathon = SpeedrunPaces.idFor('marathon.queen', sampleSpeedrunTime);
    await cubit.close();
    cubit = SpeedrunCubit(
      journey: FakeJourneyRepository(
        speedruns: [...sampleSpeedruns, sampleMarathon],
      ),
      speedruns: speedruns,
      games: games,
      now: now,
      characters: FakeCharacterRepository(),
      rating: FakeRatingRepository(now: now)..speedrunOf = (id) => started[id]!,
    );
    await pump(tester, speedrunId: marathon);

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Marathon')),
      findsOneWidget,
    );
    expect(find.textContaining('Marathon:'), findsNothing);
  });

  group('tamanhos, fonte 2,0, escuro e árabe', () {
    const sizes = [Size(360, 740), Size(412, 917)];
    for (final size in sizes) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        for (final state in ['sem tentativa', 'recorde', 'andamento']) {
          testWidgets('$state ${size.width.toInt()}×${size.height.toInt()} '
              '$mode, fonte 2,0', (tester) async {
            switch (state) {
              case 'recorde':
                await finished();
              case 'andamento':
                final attempt = await start();
                await win(attempt, 0, 20);
            }
            await pump(tester, size: size, scale: 2, mode: mode);

            expect(tester.takeException(), isNull);
            final bar = state == 'andamento'
                ? SpeedrunKeys.resume
                : SpeedrunKeys.start;
            expect(
              tester.getSize(find.byKey(bar)).height,
              greaterThanOrEqualTo(48),
            );
            final bottom = tester.getBottomLeft(find.byKey(bar)).dy;
            expect(bottom, lessThanOrEqualTo(size.height));
          });
        }
      }
    }

    testWidgets('em árabe, com as fontes de verdade: nada estoura', (
      tester,
    ) async {
      await Goldens.loadFonts();
      await gaveUp();
      await finished();
      await pump(
        tester,
        locale: const Locale('ar'),
        size: const Size(360, 740),
        scale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(SpeedrunKeys.recordCard), findsOneWidget);
      final best = tester.widget<TimeDisplay>(
        find.ancestor(
          of: find.byKey(SpeedrunKeys.best),
          matching: find.byType(TimeDisplay),
        ),
      );
      expect(best.value, isNotEmpty);
    });
  });
}
