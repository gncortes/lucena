import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/domain/use_cases/clock_format.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
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
    Size size = const Size(1080, 4800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await cubit.load(speedrunId: id);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const SpeedrunScreen()),
      ),
    );
    await tester.pumpAndSettle();
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

  testWidgets('a trilha mostra os adversários em ordem, do mais fraco ao '
      'Stockfish', (tester) async {
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
    // Sem tentativa, nada de histórico.
    expect(find.byKey(SpeedrunKeys.run(0)), findsNothing);
  });

  testWidgets('com a etapa no tabuleiro (o app fechou no meio), as etapas '
      'vencidas ganham o selo, a da vez diz "agora" e a partida continua', (
    tester,
  ) async {
    await cubit.load(speedrunId: id);
    final (speedrun, attempt) = (await cubit.startWith(
      SpeedrunPaces.standard,
    ))!;
    await win(attempt, 0, 20);
    games.snapshot = GameSnapshot(
      startFen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
      mode: GameMode(speedrunId: speedrun.id, speedrunAttemptId: attempt),
    );

    await pump(tester);

    expect(
      find.descendant(
        of: find.byKey(SpeedrunKeys.stageCard(0)),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
    expect(stageText(tester, 1), contains('Up next'));
    expect(find.byKey(SpeedrunKeys.resume), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.start), findsNothing);
  });

  testWidgets('o histórico diz até onde foi a tentativa abandonada e o tempo '
      'da concluída', (tester) async {
    await cubit.load(speedrunId: id);
    final total = cubit.state.selected!.speedrun.stages.length;
    // A primeira: venceu uma etapa e saiu (sem a etapa no tabuleiro, ela é
    // largada ao abrir).
    final (_, first) = (await cubit.startWith(SpeedrunPaces.standard))!;
    await win(first, 0, 20);
    now.advance(const Duration(minutes: 5));
    await cubit.load(speedrunId: id);
    // A segunda: concluída, 10 s por etapa.
    now.advance(const Duration(minutes: 5));
    final (_, second) = (await cubit.startWith(SpeedrunPaces.standard))!;
    for (var stage = 0; stage < total; stage++) {
      now.advance(const Duration(minutes: 1));
      await win(second, stage, 10);
    }

    await pump(tester);

    // Da mais recente para a mais antiga.
    expect(
      find.descendant(
        of: find.byKey(SpeedrunKeys.run(0)),
        matching: find.text(RunTimeFormat.clock(Duration(seconds: total * 10))),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(SpeedrunKeys.run(1)),
        matching: find.text('Gave up at stage 2 of $total'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(SpeedrunKeys.start), findsOneWidget);
  });

  testWidgets('histórico em árabe, com as fontes de verdade: nada estoura', (
    tester,
  ) async {
    await Goldens.loadFonts();
    await cubit.load(speedrunId: id);
    final total = cubit.state.selected!.speedrun.stages.length;
    final (_, first) = (await cubit.startWith(SpeedrunPaces.standard))!;
    await win(first, 0, 20);
    now.advance(const Duration(minutes: 5));
    await cubit.load(speedrunId: id);
    now.advance(const Duration(minutes: 5));
    final (_, second) = (await cubit.startWith(SpeedrunPaces.standard))!;
    for (var stage = 0; stage < total; stage++) {
      now.advance(const Duration(minutes: 1));
      await win(second, stage, 10);
    }

    await pump(
      tester,
      locale: const Locale('ar'),
      size: const Size(1080, 6000),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(SpeedrunKeys.run(1)), findsOneWidget);
  });
}
