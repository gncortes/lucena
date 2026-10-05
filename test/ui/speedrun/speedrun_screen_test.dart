import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
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
import '../../../testing/test_app.dart';

/// A tela de um speedrun de final: a trilha dos adversários e o histórico.
void main() {
  const id = 'ending.queen';
  late FakeNow now;
  late FakeProgressRepository progress;
  late FakeSpeedrunRepository speedruns;
  late SpeedrunCubit cubit;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 10, 4, 12));
    progress = FakeProgressRepository();
    speedruns = FakeSpeedrunRepository(progress);
    cubit = SpeedrunCubit(
      journey: FakeJourneyRepository(),
      speedruns: speedruns,
      games: FakeOngoingGameRepository(),
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

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4800);
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

  testWidgets('em andamento: as etapas vencidas ganham o selo e a da vez diz '
      '"agora"', (tester) async {
    await cubit.load(speedrunId: id);
    final attempt = (await cubit.start())!;
    await win(attempt, 0, 20);

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
  });

  testWidgets('o histórico diz até onde foi a tentativa abandonada e o tempo '
      'da concluída', (tester) async {
    await cubit.load(speedrunId: id);
    final total = cubit.state.selected!.speedrun.stages.length;
    // A primeira: venceu uma etapa e desistiu.
    final first = (await cubit.start())!;
    await win(first, 0, 20);
    now.advance(const Duration(minutes: 5));
    await cubit.load(speedrunId: id, attemptId: first);
    await cubit.abandon();
    // A segunda: concluída, 10 s por etapa.
    now.advance(const Duration(minutes: 5));
    final second = (await cubit.start())!;
    for (var stage = 0; stage < total; stage++) {
      now.advance(const Duration(minutes: 1));
      await win(second, stage, 10);
    }

    await pump(tester);

    // Da mais recente para a mais antiga.
    expect(
      find.descendant(
        of: find.byKey(SpeedrunKeys.run(0)),
        matching: find.text('0:${total * 10}.0'),
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
}
