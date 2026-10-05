import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/game_details/view_models/game_details_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';

void main() {
  late FakeProgressRepository progress;
  late FakeRatingRepository rating;

  setUp(() {
    progress = FakeProgressRepository();
    rating = FakeRatingRepository();
  });

  Attempt game({
    List<String> moves = const ['e2e4', 'e7e5', 'g1f3'],
    List<Duration> moveTimes = const [
      Duration(seconds: 3),
      Duration(milliseconds: 1500),
      Duration(seconds: 65),
    ],
    int minute = 0,
  }) => Attempt(
    positionId: 'basic.queen.0001',
    playedAt: DateTime.utc(2026, 10, 5, 12, minute),
    outcome: AttemptOutcome.win,
    fulfilled: true,
    opponent: OpponentKind.maia,
    opponentLevel: 1000,
    startFen: GameRules.initial.fen,
    moves: moves,
    moveTimes: moveTimes,
    userSide: Side.white,
  );

  /// Grava e conta no rating, como o fim da partida faz.
  Future<int> playRated(Attempt attempt) async {
    final id = await progress.addAttempt(attempt);
    await rating.rate(
      attempt,
      userSide: Side.white,
      drawGoal: false,
      gameId: id,
    );
    return id;
  }

  GameDetailsCubit build(int id) {
    final cubit = GameDetailsCubit(
      id,
      progress: progress,
      rating: rating,
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('refaz os lances a partir do que foi gravado, com o tempo de cada '
      'um', () async {
    final id = await progress.addAttempt(game());
    final cubit = build(id);

    await cubit.load();

    final state = cubit.state;
    expect(state.ready, isTrue);
    expect(state.attempt, isNotNull);
    expect(state.start?.fen, GameRules.initial.fen);
    expect(state.moves.map((move) => move.san), ['e4', 'e5', 'Nf3']);
    expect(state.moves.map((move) => move.time), const [
      Duration(seconds: 3),
      Duration(milliseconds: 1500),
      Duration(seconds: 65),
    ]);
    expect(state.moves.last.move, Move.parse('g1f3'));
    // Sem escolha, o tabuleiro mostra o último lance.
    expect(state.shownIndex, 2);
    expect(state.shownPosition, state.moves.last.position);
    expect(state.characters, isNotEmpty);
  });

  test(
    'partida de antes do tempo por lance: os lances ficam sem tempo',
    () async {
      final id = await progress.addAttempt(game(moveTimes: const []));
      final cubit = build(id);

      await cubit.load();

      expect(cubit.state.moves, hasLength(3));
      expect(cubit.state.moves.every((move) => move.time == null), isTrue);
    },
  );

  test('lance gravado que não fecha com as regras para a lista ali', () async {
    final id = await progress.addAttempt(
      game(moves: const ['e2e4', 'e2e4', 'g1f3']),
    );
    final cubit = build(id);

    await cubit.load();

    expect(cubit.state.moves.map((move) => move.san), ['e4']);
  });

  test('o rating da partida é achado pelo id dela', () async {
    await playRated(game());
    final second = await playRated(game(minute: 1));
    await playRated(game(minute: 2));
    final history = await rating.history();
    final cubit = build(second);

    await cubit.load();

    expect(cubit.state.ratingAfter, history[1].rating.rounded);
    expect(
      cubit.state.ratingChange,
      history[1].rating.rounded - history[0].rating.rounded,
    );
  });

  test(
    'a primeira partida com rating só mostra o rating, sem variação',
    () async {
      final id = await playRated(game());
      final cubit = build(id);

      await cubit.load();

      expect(cubit.state.ratingAfter, isNotNull);
      expect(cubit.state.ratingChange, isNull);
    },
  );

  test('partida que não contou no rating: sem rating', () async {
    final id = await progress.addAttempt(game());
    final cubit = build(id);

    await cubit.load();

    expect(cubit.state.ratingAfter, isNull);
    expect(cubit.state.ratingChange, isNull);
  });

  test('partida que não existe mais', () async {
    final cubit = build(42);

    await cubit.load();

    expect(cubit.state.ready, isTrue);
    expect(cubit.state.attempt, isNull);
    expect(cubit.state.moves, isEmpty);
  });

  test(
    'escolher um lance mostra a posição depois dele; -1 é o início',
    () async {
      final id = await progress.addAttempt(game());
      final cubit = build(id);
      await cubit.load();

      cubit.select(0);
      expect(cubit.state.shownIndex, 0);
      expect(cubit.state.shownPosition, cubit.state.moves.first.position);
      expect(cubit.state.shownMove, Move.parse('e2e4'));

      cubit.select(-1);
      expect(cubit.state.shownPosition?.fen, GameRules.initial.fen);
      expect(cubit.state.shownMove, isNull);

      // Fora da lista, fica no limite.
      cubit.select(10);
      expect(cubit.state.shownIndex, 2);
      cubit.select(-5);
      expect(cubit.state.shownIndex, -1);
    },
  );

  test('antes de ler, escolher não faz nada', () {
    final cubit = build(1);

    cubit.select(0);

    expect(cubit.state.selected, isNull);
  });
}
