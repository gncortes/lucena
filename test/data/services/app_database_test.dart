import 'package:dartchess/dartchess.dart' show Side;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/progress/progress_repository_local.dart';
import 'package:lucena/data/services/database/app_database.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';

/// O banco de quem já tinha o app instalado continua valendo depois de
/// atualizar.
void main() {
  const profiles =
      'CREATE TABLE profiles (id INTEGER NOT NULL, nickname TEXT NOT NULL, '
      'rating INTEGER NOT NULL, PRIMARY KEY (id))';
  // A tabela como era na versão 2, antes do nível do Maia.
  const attemptsV2 =
      'CREATE TABLE attempts (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'position_id TEXT NOT NULL, played_at INTEGER NOT NULL, '
      'outcome TEXT NOT NULL, '
      'fulfilled INTEGER NOT NULL CHECK (fulfilled IN (0, 1)), '
      'opponent TEXT NOT NULL)';

  // A tabela como era na versão 3.
  const attemptsV3 =
      'CREATE TABLE attempts (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'position_id TEXT NOT NULL, played_at INTEGER NOT NULL, '
      'outcome TEXT NOT NULL, '
      'fulfilled INTEGER NOT NULL CHECK (fulfilled IN (0, 1)), '
      'opponent TEXT NOT NULL, opponent_level INTEGER NULL)';

  test('da versão 2 para a 4: as partidas antigas passam para a tabela nova', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(profiles)
            ..execute(attemptsV2)
            ..execute(
              'INSERT INTO attempts '
              '(position_id, played_at, outcome, fulfilled, opponent) '
              "VALUES ('basic.queen.0001', 1767268800, 'win', 1, 'stockfish')",
            )
            ..execute('PRAGMA user_version = 2');
        },
      ),
    );
    addTearDown(database.close);
    final repository = LocalProgressRepository(database);

    await repository.addAttempt(
      Attempt(
        positionId: 'basic.queen.0001',
        playedAt: DateTime.utc(2026, 10, 4),
        outcome: AttemptOutcome.loss,
        fulfilled: false,
        opponent: OpponentKind.maia,
        opponentLevel: 1400,
      ),
    );

    final attempts = await repository.attemptsFor('basic.queen.0001');
    expect(attempts, hasLength(2));
    expect(attempts.first.opponentLevel, 1400);
    expect(attempts.last.opponent, OpponentKind.stockfish);
    expect(attempts.last.opponentLevel, isNull);
    expect(attempts.last.fulfilled, isTrue);
    expect(await repository.fulfilledPositions(), {'basic.queen.0001'});
  });

  test('da versão 1 para a 4: a tabela de partidas nasce completa', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(profiles)
            ..execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(database.close);
    final repository = LocalProgressRepository(database);

    await repository.addAttempt(
      Attempt(
        positionId: 'basic.rook.0001',
        playedAt: DateTime.utc(2026, 10, 4),
        outcome: AttemptOutcome.win,
        fulfilled: true,
        opponent: OpponentKind.maia,
        opponentLevel: 2000,
      ),
    );

    final attempts = await repository.attemptsFor('basic.rook.0001');
    expect(attempts.single.opponentLevel, 2000);
  });

  test('da versão 3 para a 4: nada se perde e as marcas continuam', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(profiles)
            ..execute(attemptsV3)
            ..execute(
              'INSERT INTO attempts (position_id, played_at, outcome, '
              'fulfilled, opponent, opponent_level) VALUES '
              "('basic.queen.0001', 1767268800, 'win', 1, 'maia', 1200), "
              "('basic.rook.0001', 1767268900, 'loss', 0, 'stockfish', NULL)",
            )
            ..execute('PRAGMA user_version = 3');
        },
      ),
    );
    addTearDown(database.close);
    final repository = LocalProgressRepository(database);

    final queen = await repository.attemptsFor('basic.queen.0001');
    expect(queen.single.opponentLevel, 1200);
    expect(queen.single.fulfilled, isTrue);
    expect(queen.single.playedAt, DateTime.utc(2026, 1, 1, 12));
    // As partidas antigas não têm lances nem desafio.
    expect(queen.single.moves, isEmpty);
    expect(queen.single.challengeId, isNull);
    expect(await repository.fulfilledPositions(), {'basic.queen.0001'});
    expect(await repository.fulfilledChallenges(), isEmpty);
  });

  test('da versão 4 para a 5: as partidas ficam e as tabelas novas vêm '
      'vazias', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          final v4 = AppDatabase(NativeDatabase.memory());
          // As tabelas da versão 4, como o drift as cria.
          raw
            ..execute(profiles)
            ..execute(
              'CREATE TABLE games (id INTEGER NOT NULL PRIMARY KEY '
              'AUTOINCREMENT, position_id TEXT NOT NULL, played_at INTEGER '
              'NOT NULL, outcome TEXT NOT NULL, fulfilled INTEGER NOT NULL, '
              'opponent TEXT NOT NULL, opponent_level INTEGER NULL, '
              'started_at INTEGER NULL, start_fen TEXT NULL, moves TEXT NOT '
              "NULL DEFAULT '', end_reason TEXT NULL, user_time TEXT NULL, "
              'opponent_time TEXT NULL, user_clock_ms INTEGER NULL, '
              'challenge_id TEXT NULL, speedrun_attempt_id INTEGER NULL, '
              'speedrun_stage INTEGER NULL)',
            )
            ..execute(
              'CREATE TABLE speedrun_attempts (id INTEGER NOT NULL PRIMARY '
              'KEY AUTOINCREMENT, speedrun_id TEXT NOT NULL, started_at '
              'INTEGER NOT NULL, abandoned_at INTEGER NULL)',
            )
            ..execute(
              'INSERT INTO games (position_id, played_at, outcome, fulfilled, '
              "opponent) VALUES ('basic.queen.0001', 1767268800, 'win', 1, "
              "'maia')",
            )
            ..execute('PRAGMA user_version = 4');
          v4.close();
        },
      ),
    );
    addTearDown(database.close);

    final games = await LocalProgressRepository(database).allAttempts();
    expect(games, hasLength(1));
    expect(await database.select(database.ratingHistory).get(), isEmpty);
    expect(await database.select(database.unlockedAchievements).get(), isEmpty);
  });

  test('da versão 5 para a 6: as partidas ficam, sem tempo por lance nem '
      'lado, e as novas guardam os dois', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          // A tabela de partidas da versão 5, antes do tempo por lance.
          raw
            ..execute(profiles)
            ..execute(
              'CREATE TABLE games (id INTEGER NOT NULL PRIMARY KEY '
              'AUTOINCREMENT, position_id TEXT NOT NULL, played_at INTEGER '
              'NOT NULL, outcome TEXT NOT NULL, fulfilled INTEGER NOT NULL, '
              'opponent TEXT NOT NULL, opponent_level INTEGER NULL, '
              'started_at INTEGER NULL, start_fen TEXT NULL, moves TEXT NOT '
              "NULL DEFAULT '', end_reason TEXT NULL, user_time TEXT NULL, "
              'opponent_time TEXT NULL, user_clock_ms INTEGER NULL, '
              'challenge_id TEXT NULL, speedrun_attempt_id INTEGER NULL, '
              'speedrun_stage INTEGER NULL)',
            )
            ..execute(
              'CREATE TABLE speedrun_attempts (id INTEGER NOT NULL PRIMARY '
              'KEY AUTOINCREMENT, speedrun_id TEXT NOT NULL, started_at '
              'INTEGER NOT NULL, abandoned_at INTEGER NULL)',
            )
            ..execute(
              'INSERT INTO games (position_id, played_at, outcome, fulfilled, '
              "opponent, moves) VALUES ('basic.queen.0001', 1767268800, "
              "'win', 1, 'maia', 'c1c7 d7e6')",
            )
            // A das conquistas, como a versão 5 criou (a 7 mexe nela).
            ..execute(
              'CREATE TABLE unlocked_achievements (achievement_id TEXT NOT '
              'NULL, at INTEGER NOT NULL, PRIMARY KEY (achievement_id))',
            )
            ..execute('PRAGMA user_version = 5');
        },
      ),
    );
    addTearDown(database.close);
    final repository = LocalProgressRepository(database);

    final old = (await repository.allAttempts()).single;
    expect(old.moves, ['c1c7', 'd7e6']);
    expect(old.moveTimes, isEmpty);
    expect(old.userSide, isNull);

    final fresh = Attempt(
      positionId: 'basic.rook.0001',
      playedAt: DateTime.utc(2026, 10, 5, 12),
      outcome: AttemptOutcome.win,
      fulfilled: true,
      opponent: OpponentKind.maia,
      moves: const ['e2e4'],
      moveTimes: const [Duration(milliseconds: 1200)],
      userSide: Side.black,
    );
    final id = await repository.addAttempt(fresh);
    final saved = (await repository.attemptsById([id]))[id]!;
    expect(saved.moveTimes, const [Duration(milliseconds: 1200)]);
    expect(saved.userSide, Side.black);
  });
}
