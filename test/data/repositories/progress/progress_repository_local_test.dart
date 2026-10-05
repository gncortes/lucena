import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/progress/progress_repository_local.dart';
import 'package:lucena/data/services/database/app_database.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';

void main() {
  late AppDatabase database;
  late LocalProgressRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = LocalProgressRepository(database);
  });
  tearDown(() => database.close());

  Attempt attempt(String id, int minute, {required bool fulfilled}) => Attempt(
    positionId: id,
    playedAt: DateTime.utc(2026, 1, 1, 12, minute),
    outcome: fulfilled ? AttemptOutcome.win : AttemptOutcome.draw,
    fulfilled: fulfilled,
    opponent: OpponentKind.stockfish,
  );

  test('sem partidas, histórico vazio e nada cumprido', () async {
    expect(await repository.attemptsFor('basic.queen.0001'), isEmpty);
    expect(await repository.fulfilledPositions(), isEmpty);
  });

  test('as tentativas voltam da mais recente para a mais antiga', () async {
    await repository.addAttempt(
      attempt('basic.queen.0001', 1, fulfilled: false),
    );
    await repository.addAttempt(
      attempt('basic.queen.0001', 5, fulfilled: true),
    );
    await repository.addAttempt(attempt('basic.rook.0001', 3, fulfilled: true));

    final history = await repository.attemptsFor('basic.queen.0001');

    expect(history.map((a) => a.playedAt.minute), [5, 1]);
    expect(history.first.outcome, AttemptOutcome.win);
    expect(history.first.opponent, OpponentKind.stockfish);
  });

  test('as partidas voltam pelo id que a gravação devolveu', () async {
    final first = await repository.addAttempt(
      attempt('basic.queen.0001', 1, fulfilled: false),
    );
    await repository.addAttempt(attempt('basic.rook.0001', 2, fulfilled: true));
    final third = await repository.addAttempt(
      attempt('basic.rook.0002', 3, fulfilled: true),
    );

    final games = await repository.attemptsById({first, third, 999});

    expect(games.keys, unorderedEquals([first, third]));
    expect(games[first]!.positionId, 'basic.queen.0001');
    expect(games[third]!.positionId, 'basic.rook.0002');
  });

  test('cumprida uma vez, a posição fica marcada', () async {
    await repository.addAttempt(
      attempt('basic.queen.0001', 1, fulfilled: false),
    );
    await repository.addAttempt(attempt('basic.rook.0001', 2, fulfilled: true));
    await repository.addAttempt(
      attempt('basic.rook.0001', 3, fulfilled: false),
    );

    expect(await repository.fulfilledPositions(), {'basic.rook.0001'});
  });

  test('apagar tudo esquece o histórico', () async {
    await repository.addAttempt(attempt('basic.rook.0001', 2, fulfilled: true));

    await database.deleteEverything();

    expect(await repository.fulfilledPositions(), isEmpty);
  });

  test('o nível do Maia fica gravado com a tentativa', () async {
    await repository.addAttempt(
      attempt(
        'basic.queen.0001',
        1,
        fulfilled: true,
      ).copyWith(opponent: OpponentKind.maia, opponentLevel: 1400),
    );
    await repository.addAttempt(
      attempt('basic.queen.0001', 2, fulfilled: true),
    );

    final attempts = await repository.attemptsFor('basic.queen.0001');
    expect(attempts.last.opponent, OpponentKind.maia);
    expect(attempts.last.opponentLevel, 1400);
    expect(attempts.first.opponentLevel, isNull);
  });

  test('a partida completa volta igual: lances, relógio e desafio', () async {
    final full = Attempt(
      positionId: 'basic.queen.0001',
      playedAt: DateTime.utc(2026, 10, 4, 12, 5),
      outcome: AttemptOutcome.win,
      fulfilled: true,
      opponent: OpponentKind.maia,
      opponentLevel: 1000,
      startedAt: DateTime.utc(2026, 10, 4, 12),
      startFen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
      moves: const ['c1c7', 'd7e6'],
      endReason: GameEndReason.checkmate,
      userTime: const TimeControl(
        initial: Duration(minutes: 3),
        increment: Duration(seconds: 2),
      ),
      opponentTime: const TimeControl(initial: Duration(minutes: 3)),
      userClock: const Duration(seconds: 42, milliseconds: 500),
      challengeId: '1000/basic.queen.0001',
      speedrunAttemptId: 7,
      speedrunStage: 1,
    );
    await repository.addAttempt(full);

    expect(await repository.attemptsFor('basic.queen.0001'), [full]);
    expect(await repository.attemptsForChallenge('1000/basic.queen.0001'), [
      full,
    ]);
  });

  test('desafio cumprido fica marcado; o que só perdeu, não', () async {
    Attempt challenge(String id, {required bool fulfilled}) => attempt(
      'basic.queen.0001',
      1,
      fulfilled: fulfilled,
    ).copyWith(challengeId: id);
    await repository.addAttempt(challenge('1000/a', fulfilled: true));
    await repository.addAttempt(challenge('1000/b', fulfilled: false));
    await repository.addAttempt(attempt('basic.rook.0001', 2, fulfilled: true));

    expect(await repository.fulfilledChallenges(), {'1000/a'});
    expect(await repository.attemptsForChallenge('1000/b'), hasLength(1));
  });
}
