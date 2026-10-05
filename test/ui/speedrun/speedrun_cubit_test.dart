import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';

import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';

void main() {
  late FakeNow now;
  late FakeProgressRepository progress;
  late FakeSpeedrunRepository speedruns;
  late FakeOngoingGameRepository games;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 10, 4, 12));
    progress = FakeProgressRepository();
    speedruns = FakeSpeedrunRepository(progress);
    games = FakeOngoingGameRepository();
  });

  late FakeSettingsRepository settings;

  SpeedrunCubit build() {
    settings = FakeSettingsRepository(const AppSettings());
    final cubit = SpeedrunCubit(
      journey: FakeJourneyRepository(),
      speedruns: speedruns,
      games: games,
      now: now,
      settings: settings,
    );
    addTearDown(cubit.close);
    return cubit;
  }

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

  test('lista os speedruns sem recorde nem tentativa', () async {
    final cubit = build();
    await cubit.load();

    expect(cubit.state.all!.map((s) => s.speedrun.id), [
      'rung.1000',
      'ending.queen',
    ]);
    expect(cubit.state.all!.first.records.best, isNull);
    expect(cubit.state.all!.first.ongoing, isNull);
  });

  test('começar cria a tentativa em andamento', () async {
    final cubit = build();
    await cubit.load(speedrunId: 'rung.1000');

    final id = await cubit.start();
    await cubit.load(speedrunId: 'rung.1000', attemptId: id);

    expect(cubit.state.selected!.ongoing!.attempt.id, id);
    expect(cubit.state.run!.currentStage, 0);
    expect(cubit.state.gameOngoing, isFalse);
  });

  test('a etapa no tabuleiro é da tentativa: jogar continua ela', () async {
    final cubit = build();
    await cubit.load(speedrunId: 'rung.1000');
    final id = (await cubit.start())!;
    games.snapshot = GameSnapshot(
      startFen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
      mode: GameMode(speedrunId: 'rung.1000', speedrunAttemptId: id),
    );

    await cubit.load(speedrunId: 'rung.1000', attemptId: id);

    expect(cubit.state.gameOngoing, isTrue);
  });

  test('concluída: vira recorde e mostra o recorde de antes', () async {
    final cubit = build();
    await cubit.load(speedrunId: 'rung.1000');
    final first = (await cubit.start())!;
    await win(first, 0, 30);
    await win(first, 1, 40);
    now.advance(const Duration(hours: 1));
    final second = (await cubit.start())!;
    await win(second, 0, 20);
    await win(second, 1, 30);

    await cubit.load(speedrunId: 'rung.1000', attemptId: second);

    expect(cubit.state.run!.completed, isTrue);
    expect(cubit.state.selected!.records.best, const Duration(seconds: 50));
    expect(cubit.state.previousBest, const Duration(seconds: 70));
    expect(cubit.state.selected!.ongoing, isNull);
  });

  test('abandonar encerra a tentativa e tira a etapa do tabuleiro', () async {
    final cubit = build();
    await cubit.load(speedrunId: 'rung.1000');
    final id = (await cubit.start())!;
    games.snapshot = GameSnapshot(
      startFen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
      mode: GameMode(speedrunId: 'rung.1000', speedrunAttemptId: id),
    );
    await cubit.load(speedrunId: 'rung.1000', attemptId: id);

    await cubit.abandon();

    expect(cubit.state.run!.abandoned, isTrue);
    expect(cubit.state.selected!.ongoing, isNull);
    expect(games.snapshot, isNull);
    // A desistência fica no resumo, para o histórico dizer até onde foi.
    expect(cubit.state.selected!.abandoned.map((run) => run.attempt.id), [id]);
    expect(cubit.state.selected!.records.completed, isEmpty);
  });

  group('ritmos', () {
    const threeTwo = TimeControl(
      initial: Duration(minutes: 3),
      increment: Duration(seconds: 2),
    );

    test('a lista abre no ritmo padrão (5+3)', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.pace, SpeedrunPaces.standard);
      expect(cubit.state.all!.first.speedrun.time, SpeedrunPaces.standard);
    });

    test('trocar o ritmo troca os speedruns da lista e fica gravado', () async {
      final cubit = build();
      await cubit.load();

      await cubit.choosePace(threeTwo);

      expect(cubit.state.pace, threeTwo);
      expect(cubit.state.all!.first.speedrun.id, 'rung.1000@180+2');
      expect(cubit.state.all!.first.speedrun.stages.first.time, threeTwo);
      expect((await settings.load()).clock.speedrunTime, threeTwo);
    });

    test('cada ritmo tem os seus recordes', () async {
      final cubit = build();
      await cubit.load(speedrunId: 'rung.1000');
      final (id, attempt) = (await cubit.startWith(threeTwo))!;
      expect(id, 'rung.1000@180+2');
      await win(attempt, 0, 20);
      await win(attempt, 1, 30);

      await cubit.load();
      // No 3+2, o recorde; no 5+3, nada.
      expect(cubit.state.all!.first.records.best, const Duration(seconds: 50));
      await cubit.choosePace(SpeedrunPaces.standard);
      expect(cubit.state.all!.first.records.best, isNull);
    });

    test('a tentativa em andamento aparece mesmo em outro ritmo', () async {
      final cubit = build();
      await cubit.load(speedrunId: 'rung.1000');
      await cubit.startWith(threeTwo);
      await cubit.choosePace(SpeedrunPaces.standard);

      await cubit.load();

      expect(cubit.state.inProgress.map((s) => s.speedrun.id), [
        'rung.1000@180+2',
      ]);
    });
  });
}
