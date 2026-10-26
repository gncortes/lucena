import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/ongoing_game/ongoing_game_repository.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/domain/models/journey.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/journey/widgets/journey_resume.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';

void main() {
  const challenge = Challenge(
    id: '1000.basic.queen.0001',
    position: EndgamePosition(
      id: 'basic.queen.0001',
      category: 'basic',
      subcategory: 'queen',
      fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
      goal: PositionGoal.win,
    ),
    opponent: OpponentRef(kind: OpponentKind.maia, level: 1000),
  );
  final snapshot = GameSnapshot(
    startFen: challenge.position.fen,
    moves: const ['c1d1'],
    mode: GameMode(
      challengeId: challenge.id,
      positionId: challenge.position.id,
      opponent: challenge.opponent.kind,
      level: challenge.opponent.level,
      goal: challenge.goal,
    ),
  );

  Future<BuildContext> mount(
    WidgetTester tester,
    FakeOngoingGameRepository games,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<OngoingGameRepository>.value(value: games),
          RepositoryProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(),
          ),
        ],
        child: Builder(
          builder: (value) {
            context = value;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return context;
  }

  void expectPreserved(FakeOngoingGameRepository games, GameSnapshot original) {
    expect(games.snapshot, same(original));
    expect(games.saved, isEmpty);
    expect(games.clearCalls, 0);
  }

  testWidgets('retoma o desafio compatível na posição após os lances', (
    tester,
  ) async {
    final games = FakeOngoingGameRepository(snapshot);
    final context = await mount(tester, games);

    final saved = await savedJourneyGame(context, challenge);

    expect(saved, isNotNull);
    expect(saved!.snapshot, same(snapshot));
    final played = GameRules.play(
      GameRules.fromFen(snapshot.startFen)!,
      Move.parse('c1d1')!,
    )!;
    expect(saved.position.fen, played.position.fen);
    expect(saved.lastMove, Move.parse('c1d1'));
    expectPreserved(games, snapshot);
  });

  final incompatible = <String, GameSnapshot>{
    'outro desafio': snapshot.copyWith(
      mode: snapshot.mode.copyWith(challengeId: 'outro'),
    ),
    'sem desafio': snapshot.copyWith(
      mode: snapshot.mode.copyWith(challengeId: null),
    ),
    'outro FEN inicial': snapshot.copyWith(
      startFen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 1 1',
    ),
    'outra posição': snapshot.copyWith(
      mode: snapshot.mode.copyWith(positionId: 'basic.queen.0002'),
    ),
    'outro adversário': snapshot.copyWith(
      mode: snapshot.mode.copyWith(opponent: OpponentKind.stockfish),
    ),
    'outro nível': snapshot.copyWith(mode: snapshot.mode.copyWith(level: 1600)),
    'outro objetivo': snapshot.copyWith(
      mode: snapshot.mode.copyWith(goal: PositionGoal.draw),
    ),
    'speedrun': snapshot.copyWith(
      mode: snapshot.mode.copyWith(speedrunAttemptId: 1),
    ),
    'link': snapshot.copyWith(mode: snapshot.mode.copyWith(fromLink: true)),
    'FEN corrompido': snapshot.copyWith(startFen: 'invalid'),
    'lance corrompido': snapshot.copyWith(moves: ['invalid']),
    'lance ilegal': snapshot.copyWith(moves: ['c1c8']),
    'sem progresso': snapshot.copyWith(moves: []),
  };
  for (final entry in incompatible.entries) {
    testWidgets('recusa ${entry.key} e preserva o snapshot', (tester) async {
      final games = FakeOngoingGameRepository(entry.value);
      final context = await mount(tester, games);

      expect(await savedJourneyGame(context, challenge), isNull);

      expectPreserved(games, entry.value);
    });
  }

  testWidgets('recusa partida terminal mesmo com todos os campos compatíveis', (
    tester,
  ) async {
    const fen = '7k/6Q1/5K2/8/8/8/8/8 b - - 0 1';
    final terminalChallenge = challenge.copyWith(
      position: challenge.position.copyWith(fen: fen),
    );
    final terminal = snapshot.copyWith(
      startFen: fen,
      moves: [],
      clock: ClockState(
        config: ClockConfig.same(
          const TimeControl(initial: Duration(minutes: 3)),
        ),
        white: const Duration(minutes: 3),
        black: const Duration(minutes: 3),
      ),
    );
    expect(GameRules.endOf(GameRules.fromFen(fen)!), isNotNull);
    final games = FakeOngoingGameRepository(terminal);
    final context = await mount(tester, games);

    expect(await savedJourneyGame(context, terminalChallenge), isNull);

    expectPreserved(games, terminal);
  });

  testWidgets('sem snapshot não oferece retomada', (tester) async {
    final games = FakeOngoingGameRepository();
    final context = await mount(tester, games);
    expect(await savedJourneyGame(context, challenge), isNull);
    expect(games.saved, isEmpty);
    expect(games.clearCalls, 0);
  });

  testWidgets('recusa a partida que terminou após reproduzir os lances', (
    tester,
  ) async {
    const fen = '7k/8/5KQ1/8/8/8/8/8 w - - 0 1';
    final beforeMate = challenge.copyWith(
      position: challenge.position.copyWith(fen: fen),
    );
    final terminal = snapshot.copyWith(startFen: fen, moves: ['g6g7']);
    final played = GameRules.play(
      GameRules.fromFen(fen)!,
      Move.parse('g6g7')!,
    )!;
    expect(GameRules.endOf(played.position), isNotNull);
    final games = FakeOngoingGameRepository(terminal);
    final context = await mount(tester, games);

    expect(await savedJourneyGame(context, beforeMate), isNull);

    expectPreserved(games, terminal);
  });

  testWidgets('relógio salvo permite retomar mesmo antes do primeiro lance', (
    tester,
  ) async {
    final timed = snapshot.copyWith(
      moves: [],
      clock: ClockState(
        config: ClockConfig.same(
          const TimeControl(initial: Duration(minutes: 3)),
        ),
        white: const Duration(minutes: 2),
        black: const Duration(minutes: 3),
      ),
    );
    final games = FakeOngoingGameRepository(timed);
    final context = await mount(tester, games);

    final saved = await savedJourneyGame(context, challenge);

    expect(saved, isNotNull);
    expect(saved!.snapshot, same(timed));
    expect(saved.position.fen, timed.startFen);
    expect(saved.lastMove, isNull);
    expectPreserved(games, timed);
  });
}
