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

  test('da versão 2 para a 3: as partidas antigas ficam e ganham o nível', () async {
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

  test('da versão 1 para a 3: a tabela de partidas nasce completa', () async {
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
}
