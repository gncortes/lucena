import 'package:dartchess/dartchess.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/rating/rating_repository_local.dart';
import 'package:lucena/data/services/database/app_database.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/move_prediction.dart';
import 'package:lucena/domain/models/user_profile.dart';

import '../../../../testing/fakes/fake_maia_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';

void main() {
  late AppDatabase database;
  late FakeMaiaRepository maia;
  late LocalRatingRepository repository;
  final now = FakeNow(DateTime.utc(2026, 10, 4, 12));
  // Dama contra rei, brancas jogam: o jogador é as brancas.
  const fen = '4k3/8/8/8/8/8/8/3QK3 w - - 0 1';

  Attempt game({
    required bool fulfilled,
    OpponentKind opponent = OpponentKind.maia,
    int? level = 1600,
  }) => Attempt(
    positionId: 'basic.queen.0001',
    playedAt: now(),
    outcome: fulfilled ? AttemptOutcome.win : AttemptOutcome.loss,
    fulfilled: fulfilled,
    opponent: opponent,
    opponentLevel: opponent == OpponentKind.maia ? level : null,
    startFen: fen,
  );

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    maia = FakeMaiaRepository(
      byLevel: {
        // Meio a meio para quem joga, em qualquer nível.
        for (final level in [1000, 1200, 1400, 1600, 2600])
          level: const MovePrediction(
            moves: {},
            win: 0.5,
            draw: 0,
            loss: 0.5,
            elapsed: Duration.zero,
          ),
      },
    );
    repository = LocalRatingRepository(
      database,
      maia: maia,
      profile: FakeProfileRepository(const UserProfile(rating: 1150)),
      now: now,
    );
  });

  tearDown(() => database.close());

  test('sem partidas, o rating é o da faixa do perfil', () async {
    expect((await repository.current()).rounded, 1150);
    expect(await repository.history(), isEmpty);
  });

  test(
    'vencer sobe, perder desce, e o histórico guarda cada partida',
    () async {
      final won = await repository.rate(
        game(fulfilled: true),
        userSide: Side.white,
        drawGoal: false,
        gameId: 1,
      );
      expect(won!.rating.rounded, greaterThan(1150));
      final lost = await repository.rate(
        game(fulfilled: false),
        userSide: Side.white,
        drawGoal: false,
        gameId: 2,
      );
      expect(lost!.rating.rounded, lessThan(won.rating.rounded));

      final history = await repository.history();
      expect(history.map((e) => e.gameId), [1, 2]);
      expect((await repository.current()).rounded, lost.rating.rounded);
    },
  );

  test('o Maia avalia a posição entre o rating do jogador e o nível', () async {
    await repository.rate(
      game(fulfilled: true),
      userSide: Side.white,
      drawGoal: false,
    );
    // O jogador (1150 → nível 1200) move primeiro, contra o 1600.
    expect(maia.matches.single, (fen, 1200, 1600));
  });

  test('posição em que o jogador é favorito vale menos', () async {
    maia.byLevel[1200] = const MovePrediction(
      moves: {},
      win: 0.95,
      draw: 0.05,
      loss: 0,
      elapsed: Duration.zero,
    );
    final easy = await repository.rate(
      game(fulfilled: true),
      userSide: Side.white,
      drawGoal: false,
    );
    expect(easy!.rating.rounded - 1150, lessThan(30));
  });

  test('contra o Stockfish, a chance é a contra o Maia 2600', () async {
    await repository.rate(
      game(fulfilled: false, opponent: OpponentKind.stockfish),
      userSide: Side.white,
      drawGoal: false,
    );
    expect(maia.matches.single.$3, 2600);
  });

  test('partida sem máquina não conta', () async {
    final entry = await repository.rate(
      game(fulfilled: true, opponent: OpponentKind.twoPlayers),
      userSide: Side.white,
      drawGoal: false,
    );
    expect(entry, isNull);
    expect(await repository.history(), isEmpty);
  });
}
