import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/maia_level.dart';
import 'package:lucena/domain/models/pace.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/game_setup/view_models/game_setup_cubit.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_pace_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_training_repository.dart';

void main() {
  late FakeTrainingRepository training;

  GameSetupCubit build({String fen = '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1'}) {
    return GameSetupCubit(
      training,
      progress: FakeProgressRepository(),
      profile: FakeProfileRepository(),
      position: GameRules.fromFen(fen)!,
      goal: PositionGoal.win,
    );
  }

  setUp(() => training = FakeTrainingRepository());

  test('o jogador começa com o lado que joga na posição', () {
    expect(build().state.userSide, Side.white);
    expect(
      build(fen: '8/8/8/4k3/8/r7/4P3/4K2R b - - 0 1').state.userSide,
      Side.black,
    );
  });

  test('carrega a última configuração gravada', () async {
    training.setup = const GameSetup(clock: false);
    final cubit = build();
    addTearDown(cubit.close);
    expect(cubit.state.canStart, isFalse);

    await cubit.load();

    expect(cubit.state.setup.clock, isFalse);
    expect(cubit.state.canStart, isTrue);
  });

  test(
    '3+2 para o jogador e 1+0 para o adversário: cada relógio no seu lado',
    () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.setClock(enabled: false);
      await cubit.setTimes(
        user: const TimeControl(
          initial: Duration(minutes: 3),
          increment: Duration(seconds: 2),
        ),
        opponent: const TimeControl(initial: Duration(minutes: 1)),
      );

      // O ritmo montado à mão liga o relógio.
      expect(cubit.state.setup.clock, isTrue);

      expect(cubit.state.clockCodes, (white: '180+2', black: '60+0'));
      cubit.setUserSide(Side.black);
      expect(cubit.state.clockCodes, (white: '60+0', black: '180+2'));
      expect(
        training.setup.userTime,
        const TimeControl(
          initial: Duration(minutes: 3),
          increment: Duration(seconds: 2),
        ),
      );
    },
  );

  test('tempo zero bloqueia o começo', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.setTimes(
      user: const TimeControl(initial: Duration(minutes: 5)),
      opponent: const TimeControl(initial: Duration.zero),
    );

    expect(cubit.state.hasZeroTime, isTrue);
    expect(cubit.state.canStart, isFalse);

    await cubit.setClock(enabled: false);
    expect(cubit.state.canStart, isTrue);
    expect(cubit.state.clockCodes, (white: null, black: null));
  });

  test('os tempos ficam dentro dos limites', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.setTimes(
      user: const TimeControl(
        initial: Duration(minutes: 999),
        increment: Duration(seconds: -4),
      ),
      opponent: const TimeControl(initial: Duration(minutes: 5)),
    );

    expect(
      cubit.state.setup.userTime.initial.inMinutes,
      SetupLimits.maxMinutes,
    );
    expect(cubit.state.setup.userTime.increment, Duration.zero);
  });

  test(
    'a partida abre contra o Maia por padrão, com o lado do jogador',
    () async {
      final cubit = GameSetupCubit(
        training,
        progress: FakeProgressRepository(),
        profile: FakeProfileRepository(),
        position: GameRules.fromFen('8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1')!,
        goal: PositionGoal.win,
        positionId: 'basic.queen.0001',
      );
      addTearDown(cubit.close);
      await cubit.load();

      final query = Uri.parse(cubit.state.gameRoute).queryParameters;
      expect(query['opponent'], 'maia');
      // Perfil padrão (rating 1150): o nível mais próximo.
      expect(query['level'], '1200');
      expect(query['user'], 'white');
      expect(query['goal'], 'win');
      expect(query['position'], 'basic.queen.0001');
    },
  );

  test(
    'carrega o histórico da posição, da mais recente para a mais antiga',
    () async {
      final progress = FakeProgressRepository([
        for (final minute in [1, 2])
          Attempt(
            positionId: 'basic.queen.0001',
            playedAt: DateTime.utc(2026, 1, 1, 12, minute),
            outcome: AttemptOutcome.win,
            fulfilled: true,
            opponent: OpponentKind.stockfish,
          ),
      ]);
      final cubit = GameSetupCubit(
        training,
        progress: progress,
        profile: FakeProfileRepository(),
        position: GameRules.fromFen('8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1')!,
        goal: PositionGoal.win,
        positionId: 'basic.queen.0001',
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.attempts.map((a) => a.playedAt.minute), [2, 1]);
    },
  );

  group('nível do Maia', () {
    GameSetupCubit withRating(int rating) => GameSetupCubit(
      training,
      progress: FakeProgressRepository(),
      profile: FakeProfileRepository(UserProfile(rating: rating)),
      position: GameRules.fromFen('8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1')!,
      goal: PositionGoal.win,
    );

    test('o rating do perfil sugere o nível', () async {
      final cubit = withRating(1750);
      addTearDown(cubit.close);
      await cubit.load();

      expect(cubit.state.suggestedLevel, 1800);
      expect(cubit.state.maiaLevel, 1800);
      expect(Uri.parse(cubit.state.gameRoute).queryParameters['level'], '1800');
    });

    test('o nível escolhido vale mais que o sugerido e fica gravado', () async {
      final cubit = withRating(1750);
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.setMaiaLevel(1400);

      expect(cubit.state.maiaLevel, 1400);
      expect(cubit.state.suggestedLevel, 1800);
      expect(training.setup.maiaLevel, 1400);
      final reopened = withRating(1750);
      addTearDown(reopened.close);
      await reopened.load();
      expect(reopened.state.maiaLevel, 1400);
    });

    test('contra o Stockfish, a partida abre sem nível', () async {
      final cubit = withRating(1750);
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.setOpponent(OpponentKind.stockfish);

      final query = Uri.parse(cubit.state.gameRoute).queryParameters;
      expect(query['opponent'], 'stockfish');
      expect(query.containsKey('level'), isFalse);
    });
  });

  group('rating e ritmo', () {
    GameSetupCubit full({FakeRatingRepository? rating}) {
      final cubit = GameSetupCubit(
        training,
        progress: FakeProgressRepository(),
        profile: FakeProfileRepository(const UserProfile(rating: 1150)),
        rating: rating ?? FakeRatingRepository(),
        pace: FakePaceRepository(),
        characters: FakeCharacterRepository(),
        position: GameRules.fromFen('8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1')!,
        goal: PositionGoal.win,
      );
      addTearDown(cubit.close);
      return cubit;
    }

    test('com partidas contadas, o rating sugere o nível', () async {
      // Perto da divisa entre o 1200 e o 1400: uma vitória improvável leva
      // o rating para o lado do 1400.
      final rating = FakeRatingRepository(start: 1295, expected: 0.1);
      await rating.rate(
        Attempt(
          positionId: 'x',
          playedAt: DateTime.utc(2026),
          outcome: AttemptOutcome.win,
          fulfilled: true,
          opponent: OpponentKind.maia,
          opponentLevel: 1600,
        ),
        userSide: Side.white,
        drawGoal: false,
      );
      final cubit = full(rating: rating);
      await cubit.load();

      final current = (await rating.current()).rounded;
      expect(cubit.state.rating, current);
      expect(cubit.state.suggestedLevel, MaiaLevels.nearest(current));
      expect(cubit.state.suggestedLevel, greaterThan(1200));
    });

    test('sem partidas, a sugestão é a da faixa do perfil', () async {
      final cubit = full();
      await cubit.load();
      expect(cubit.state.rating, isNull);
      expect(cubit.state.suggestedLevel, 1200);
    });

    test('o ritmo nomeado põe o mesmo tempo dos dois lados', () async {
      final cubit = full();
      await cubit.load();
      final bullet = cubit.state.paces.first;
      await cubit.setPace(bullet);

      expect(cubit.state.pace, bullet);
      expect(bullet.category, PaceCategory.bullet);
      expect(cubit.state.clockCodes, (white: '60+0', black: '60+0'));
      expect(training.setup.userTime, bullet.time);

      await cubit.setTimes(
        user: bullet.time,
        opponent: const TimeControl(initial: Duration(minutes: 2)),
      );
      expect(cubit.state.pace, isNull);
    });

    test('os personagens chegam para a escolha do adversário', () async {
      final cubit = full();
      await cubit.load();
      expect(cubit.state.characters.map((c) => c.level), [1000, 1600, 2600]);
    });
  });
}
