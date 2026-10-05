import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/progress/progress_repository_local.dart';
import 'package:lucena/data/repositories/speedrun/speedrun_repository_local.dart';
import 'package:lucena/data/services/database/app_database.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';

void main() {
  late AppDatabase database;
  late LocalSpeedrunRepository repository;
  late LocalProgressRepository progress;
  final at = DateTime.utc(2026, 10, 4, 12);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = LocalSpeedrunRepository(database);
    progress = LocalProgressRepository(database);
  });
  tearDown(() => database.close());

  Attempt stage(int attempt, int stage) => Attempt(
    positionId: 'basic.queen.0001',
    playedAt: at.add(Duration(minutes: stage)),
    outcome: AttemptOutcome.win,
    fulfilled: true,
    opponent: OpponentKind.maia,
    userClock: const Duration(seconds: 30),
    speedrunAttemptId: attempt,
    speedrunStage: stage,
  );

  test(
    'a tentativa traz as partidas dela, na ordem em que foram jogadas',
    () async {
      final first = await repository.start('rung.1000', at);
      final other = await repository.start('rung.1000', at);
      await progress.addAttempt(stage(first.id, 0));
      await progress.addAttempt(stage(other.id, 0));
      await progress.addAttempt(stage(first.id, 1));

      final loaded = await repository.attempt(first.id);

      expect(loaded!.speedrunId, 'rung.1000');
      expect(loaded.startedAt, at);
      expect(loaded.games.map((game) => game.speedrunStage), [0, 1]);
    },
  );

  test(
    'as tentativas de um speedrun, da mais antiga para a mais recente',
    () async {
      final first = await repository.start('rung.1000', at);
      await repository.start('ending.queen', at);
      final second = await repository.start('rung.1000', at);

      final attempts = await repository.attempts('rung.1000');

      expect(attempts.map((attempt) => attempt.id), [first.id, second.id]);
      expect(await repository.attempts('rung.1200'), isEmpty);
    },
  );

  test('abandonar grava o instante', () async {
    final attempt = await repository.start('rung.1000', at);
    final later = at.add(const Duration(hours: 1));

    await repository.abandon(attempt.id, later);

    expect((await repository.attempt(attempt.id))!.abandonedAt, later);
    expect(await repository.attempt(999), isNull);
  });
}
