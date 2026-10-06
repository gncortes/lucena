import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/domain/use_cases/lesson_rules.dart';
import 'package:lucena/domain/use_cases/star_challenge_rules.dart';
import 'package:lucena/ui/school/view_models/star_challenge_cubit.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_star_challenge_repository.dart';

void main() {
  late FakeNow now;
  late FakeStarChallengeRepository progress;

  setUp(() {
    now = FakeNow(DateTime(2026, 10, 6, 10));
    progress = FakeStarChallengeRepository();
  });

  StarChallengeCubit cubit() {
    final cubit = StarChallengeCubit(
      progress: progress,
      now: now,
      random: Random(7),
      tickEvery: const Duration(hours: 1),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  /// O lance da peça até a estrela, se ela estiver a um lance.
  NormalMove? toStar(StarChallengeState state) {
    final board = LessonRules.starsBoard(state.fen!);
    final from = StarChallengeRules.pieceSquare(board)!;
    final star = state.star!;
    if (!StarChallengeRules.movesOf(board, from).contains(star)) return null;
    return NormalMove(from: from, to: star);
  }

  test('monta, espera o "vai", e a estrela aparece com o relógio', () async {
    final challenge = cubit();
    await challenge.load(ChallengePiece.rook, ChallengeLevel.easy);
    expect(challenge.state.phase, ChallengePhase.ready);
    expect(challenge.state.star, isNull);
    expect(challenge.state.timeLeft, const Duration(seconds: 60));

    challenge.start();
    expect(challenge.state.phase, ChallengePhase.running);
    expect(challenge.state.star, isNotNull);
    now.advance(const Duration(seconds: 20));
    challenge.tick();
    expect(challenge.state.timeLeft, const Duration(seconds: 40));
  });

  test('pegar a estrela conta uma e acende outra; errar não conta', () async {
    final challenge = cubit();
    await challenge.load(ChallengePiece.rook, ChallengeLevel.easy);
    challenge.start();
    final first = challenge.state.star!;
    final move = toStar(challenge.state)!;
    final elsewhere = StarChallengeRules.movesOf(
      LessonRules.starsBoard(challenge.state.fen!),
      move.from,
    ).firstWhere((square) => square != first);

    challenge.play(NormalMove(from: move.from, to: elsewhere));
    expect(challenge.state.collected, 0);
    expect(challenge.state.star, first);

    final again = toStar(challenge.state)!;
    challenge.play(again);
    expect(challenge.state.collected, 1);
    expect(challenge.state.star, isNot(first));
  });

  test(
    'o tempo acaba: a nota, o recorde gravado e a pausa não conta',
    () async {
      final challenge = cubit();
      await challenge.load(ChallengePiece.knight, ChallengeLevel.easy);
      challenge.start();
      for (var i = 0; i < 12; i++) {
        challenge.play(toStar(challenge.state)!);
      }
      now.advance(const Duration(seconds: 30));
      challenge.pause();
      now.advance(const Duration(minutes: 5));
      challenge.resume();
      challenge.tick();
      expect(challenge.state.phase, ChallengePhase.running);
      expect(challenge.state.timeLeft, const Duration(seconds: 30));

      now.advance(const Duration(seconds: 31));
      challenge.tick();
      await Future<void>.delayed(Duration.zero);
      expect(challenge.state.phase, ChallengePhase.finished);
      expect(challenge.state.collected, 12);
      expect(challenge.state.earned, 1);
      expect(challenge.state.newBest, isTrue);
      expect(
        progress.saved.bestOf(ChallengePiece.knight, ChallengeLevel.easy),
        12,
      );
    },
  );

  test('de novo: outro tabuleiro, a marca anterior como recorde', () async {
    progress = FakeStarChallengeRepository(
      const StarChallengeProgress().withBest(
        ChallengePiece.rook,
        ChallengeLevel.medium,
        9,
      ),
    );
    final challenge = cubit();
    await challenge.load(ChallengePiece.rook, ChallengeLevel.medium);
    expect(challenge.state.best, 9);
    challenge.start();
    now.advance(const Duration(seconds: 61));
    challenge.tick();
    await Future<void>.delayed(Duration.zero);
    expect(challenge.state.phase, ChallengePhase.finished);
    expect(challenge.state.newBest, isFalse);
    await challenge.retry();
    expect(challenge.state.phase, ChallengePhase.ready);
    expect(challenge.state.collected, 0);
  });
}
