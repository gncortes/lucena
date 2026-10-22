import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/ui/race/view_models/race_cubit.dart';
import 'package:lucena/ui/race/view_models/race_warm_up_cubit.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_race_repository.dart';

void main() {
  late FakeNow now;
  late FakeRaceRepository repository;
  late RaceCubit cubit;

  const wrong = 'a1a2';

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 1, 1, 12));
    repository = FakeRaceRepository(now: now);
    cubit = RaceCubit(repository, now);
  });

  tearDown(() => cubit.close());

  Future<void> solveCurrent() => cubit.answer(cubit.state.problem!.solution);

  test('abre na introdução, com o banco e o recorde', () async {
    final stored = FakeRaceRepository(
      now: now,
      record: const RaceRecord(corrects: 14, hardest: 1620),
    );
    final cubit = RaceCubit(stored, now);
    await cubit.load();
    expect(cubit.state.phase, RacePhase.intro);
    expect(cubit.state.record.corrects, 14);
    expect(cubit.state.themes, [
      RaceTheme.rook,
      RaceTheme.pawns,
      RaceTheme.queen,
    ]);
    await cubit.close();
  });

  test('começar abre o problema mais fácil e guarda a Corrida', () async {
    await cubit.load();
    await cubit.start();
    expect(cubit.state.phase, RacePhase.playing);
    expect(cubit.state.problem!.level, 900);
    expect(cubit.state.remaining, const Duration(minutes: 3));
    expect((await repository.ongoing())!.startedAt, now());
  });

  test('acerto soma, mostra o ícone de certo e sobe o nível', () async {
    await cubit.load();
    await cubit.start();
    await solveCurrent();
    expect(cubit.state.run!.corrects, 1);
    expect(cubit.state.feedback, RaceFeedback.correct);
    expect(cubit.state.feedbackCount, 1);
    expect(cubit.state.problem!.level, 1060);
  });

  test('erro gasta uma chance e a Corrida segue até o terceiro', () async {
    await cubit.load();
    await cubit.start();
    await cubit.answer(wrong);
    await cubit.answer(wrong);
    expect(cubit.state.phase, RacePhase.playing);
    expect(cubit.state.run!.errors, 2);
    expect(cubit.state.feedback, RaceFeedback.wrong);

    await cubit.answer(wrong);
    expect(cubit.state.phase, RacePhase.finished);
    expect(cubit.state.outcome!.result.end, RaceEnd.errors);
    expect(await repository.ongoing(), isNull);
  });

  test('o tempo acabando fecha a Corrida no tique', () async {
    await cubit.load();
    await cubit.start();
    await solveCurrent();
    now.advance(const Duration(minutes: 2, seconds: 59));
    await cubit.tick();
    expect(cubit.state.phase, RacePhase.playing);
    expect(cubit.state.remaining, const Duration(seconds: 1));

    now.advance(const Duration(seconds: 1));
    await cubit.tick();
    expect(cubit.state.phase, RacePhase.finished);
    expect(cubit.state.outcome!.result.end, RaceEnd.time);
    expect(cubit.state.remaining, Duration.zero);
    expect(cubit.state.outcome!.isRecord, isTrue);
  });

  test('lance depois do tempo não vale', () async {
    await cubit.load();
    await cubit.start();
    now.advance(const Duration(minutes: 3, seconds: 1));
    await solveCurrent();
    expect(cubit.state.phase, RacePhase.finished);
    expect(cubit.state.outcome!.result.run.corrects, 0);
  });

  test('reabrir o app no meio continua do mesmo ponto', () async {
    await cubit.load();
    await cubit.start();
    await solveCurrent();
    now.advance(const Duration(seconds: 30));

    final reopened = RaceCubit(repository, now);
    await reopened.load();

    expect(reopened.state.phase, RacePhase.playing);
    expect(reopened.state.run!.corrects, 1);
    expect(reopened.state.remaining, const Duration(seconds: 150));
    expect(reopened.state.problem!.level, 1060);
    await reopened.close();
  });

  test('reabrir o app depois dos 3 minutos mostra o resultado', () async {
    await cubit.load();
    await cubit.start();
    await solveCurrent();
    now.advance(const Duration(minutes: 10));

    final reopened = RaceCubit(repository, now);
    await reopened.load();

    expect(reopened.state.phase, RacePhase.finished);
    expect(reopened.state.outcome!.result.end, RaceEnd.time);
    expect(reopened.state.outcome!.result.run.corrects, 1);
    await reopened.close();
  });

  test('sair no meio descarta a Corrida: sem resultado e sem contar', () async {
    await cubit.load();
    await cubit.start();
    await solveCurrent();
    await cubit.quit();
    expect(cubit.state.phase, RacePhase.intro);
    expect(cubit.state.outcome, isNull);
    expect(await repository.ongoing(), isNull);
    expect(await repository.history(), isEmpty);
    expect((await repository.record()).isEmpty, isTrue);
  });

  test('o filtro limita os problemas ao tema', () async {
    await cubit.load();
    await cubit.selectTheme(RaceTheme.queen);
    await cubit.start();
    expect(cubit.state.problem!.theme, RaceTheme.queen);
    await cubit.selectTheme(null);
    expect(cubit.state.theme, isNull);
  });

  test('o filtro escolhido persiste e volta na próxima abertura', () async {
    await cubit.load();
    await cubit.selectTheme(RaceTheme.rook);
    expect(await repository.theme(), RaceTheme.rook);
    final reopened = RaceCubit(repository, now);
    addTearDown(reopened.close);
    await reopened.load();
    expect(reopened.state.theme, RaceTheme.rook);
    await reopened.selectTheme(null);
    expect(await repository.theme(), isNull);
  });

  test('um filtro que o banco não tem volta a todos os finais', () async {
    await repository.setTheme(RaceTheme.minor);
    await cubit.load();
    expect(cubit.state.theme, isNull);
  });

  test('revisão passa pelos erros e volta ao resultado', () async {
    await cubit.load();
    await cubit.start();
    await cubit.answer(wrong);
    await solveCurrent();
    await cubit.answer(wrong);
    await cubit.answer(wrong);
    expect(cubit.state.phase, RacePhase.finished);
    expect(cubit.state.mistakes, hasLength(3));

    cubit.review();
    expect(cubit.state.phase, RacePhase.reviewing);
    cubit.nextMistake();
    cubit.nextMistake();
    expect(cubit.state.reviewIndex, 2);
    cubit.nextMistake();
    expect(cubit.state.phase, RacePhase.finished);
  });

  test('sem erros não há revisão', () async {
    await cubit.load();
    await cubit.start();
    await solveCurrent();
    now.advance(const Duration(minutes: 3));
    await cubit.tick();
    cubit.review();
    expect(cubit.state.phase, RacePhase.finished);
  });

  group('aquecimento', () {
    test('passa pelos problemas fáceis, sem guardar nada', () async {
      final warmUp = RaceWarmUpCubit(repository);
      await warmUp.load();
      expect(warmUp.state.problems, hasLength(4));
      warmUp.answer(warmUp.state.problem!.solution);
      warmUp.answer(wrong);
      expect(warmUp.state.results, [true, false]);
      warmUp.answer(warmUp.state.problem!.solution);
      warmUp.answer(warmUp.state.problem!.solution);
      expect(warmUp.state.done, isTrue);
      expect(warmUp.state.corrects, 3);
      expect(warmUp.state.problem, isNull);
      expect(await repository.history(), isEmpty);
      await warmUp.close();
    });
  });
}
