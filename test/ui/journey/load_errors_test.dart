import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/journey.dart';
import 'package:lucena/domain/models/load_failure.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/ui/journey/view_models/journey_cubit.dart';
import 'package:lucena/ui/race/view_models/race_cubit.dart';
import 'package:lucena/ui/race/view_models/race_performance_cubit.dart';
import 'package:lucena/ui/race/view_models/race_warm_up_cubit.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';

import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_race_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';

class _Journey extends FakeJourneyRepository {
  bool fails = true;
  @override
  Future<List<Rung>> ladder() async {
    if (fails) throw StateError('unreadable');
    return super.ladder();
  }
}

class _Race extends FakeRaceRepository {
  _Race() : super(now: FakeNow(DateTime(2026, 11, 2)));
  bool fails = true;
  @override
  Future<List<RaceProblem>> problems() async {
    if (fails) throw StateError('unreadable');
    return super.problems();
  }
}

void main() {
  test('Jornada: falha tratada e nova tentativa carrega', () async {
    final repo = _Journey();
    final cubit = JourneyCubit(repo, FakeProgressRepository());
    addTearDown(cubit.close);
    await cubit.load();
    expect((cubit.state as dynamic).failure, LoadFailure.generic);
    repo.fails = false;
    await cubit.load();
    expect((cubit.state as dynamic).failure, isNull);
    expect(cubit.state.progress, isNotNull);
  });

  test('Jornada: degrau e desafio ausentes são notFound', () async {
    final cubit = JourneyCubit(
      FakeJourneyRepository(),
      FakeProgressRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load(rungId: 'missing');
    expect((cubit.state as dynamic).failure, LoadFailure.notFound);
    await cubit.load(rungId: '1000', positionId: 'missing');
    expect((cubit.state as dynamic).failure, LoadFailure.notFound);
  });

  for (final kind in ['corrida', 'desempenho', 'aquecimento']) {
    test('$kind: falha tratada e nova tentativa carrega', () async {
      final repo = _Race();
      final dynamic cubit = switch (kind) {
        'corrida' => RaceCubit(repo, FakeNow(DateTime(2026, 11, 2))),
        'desempenho' => RacePerformanceCubit(repo),
        _ => RaceWarmUpCubit(repo),
      };
      addTearDown(() async => cubit.close());
      await cubit.load();
      expect(cubit.state.failure, LoadFailure.generic);
      repo.fails = false;
      await cubit.load();
      expect(cubit.state.failure, isNull);
    });
  }

  test('Speedrun: id e tentativa ausentes são notFound', () async {
    final cubit = SpeedrunCubit(
      journey: FakeJourneyRepository(),
      speedruns: FakeSpeedrunRepository(FakeProgressRepository()),
      games: FakeOngoingGameRepository(),
      now: FakeNow(DateTime(2026, 11, 2)),
    );
    addTearDown(cubit.close);
    await cubit.load(speedrunId: 'missing');
    expect((cubit.state as dynamic).failure, LoadFailure.notFound);
    await cubit.load(speedrunId: 'rung.1000', attemptId: -1);
    expect((cubit.state as dynamic).failure, LoadFailure.notFound);
  });
}
