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
    now.advance(const Duration(seconds: 2));
    challenge.tick();
    expect(challenge.state.timeLeft, const Duration(seconds: 58));
  });

  test(
    'pegar a estrela vale os pontos dela e acende outra; errar não',
    () async {
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
      final worth = challenge.state.starKind.points;
      challenge.play(again);
      expect(challenge.state.collected, 1);
      expect(challenge.state.points, worth);
      expect(challenge.state.lastPoints, worth);
      expect(challenge.state.star, isNot(first));
    },
  );

  test('a estrela some no prazo dela e outra acende, sem ponto', () async {
    final challenge = cubit();
    await challenge.load(ChallengePiece.queen, ChallengeLevel.easy);
    challenge.start();
    final first = challenge.state.star!;
    final lifetime = challenge.state.starLifetime;
    expect(
      lifetime,
      ChallengeLevel.easy.starLifetime(challenge.state.starKind),
    );

    now.advance(lifetime - const Duration(milliseconds: 500));
    challenge.tick();
    expect(challenge.state.star, first);
    expect(challenge.state.starBlinking, isTrue);

    now.advance(const Duration(milliseconds: 600));
    challenge.tick();
    expect(challenge.state.star, isNotNull);
    expect(challenge.state.starTimeLeft, challenge.state.starLifetime);
    expect(challenge.state.points, 0);
  });

  test(
    'o tempo acaba: a nota, o recorde gravado e a pausa não conta',
    () async {
      final challenge = cubit();
      await challenge.load(ChallengePiece.knight, ChallengeLevel.easy);
      challenge.start();
      var points = 0;
      for (var i = 0; i < 12; i++) {
        points += challenge.state.starKind.points;
        challenge.play(toStar(challenge.state)!);
      }
      expect(challenge.state.points, points);
      now.advance(const Duration(seconds: 1));
      final starLeft =
          challenge.state.starLifetime - const Duration(seconds: 1);
      challenge.pause();
      now.advance(const Duration(minutes: 5));
      challenge.resume();
      challenge.tick();
      expect(challenge.state.phase, ChallengePhase.running);
      expect(challenge.state.timeLeft, const Duration(seconds: 59));
      // A pausa também não gastou o prazo da estrela.
      expect(challenge.state.starTimeLeft, starLeft);

      now.advance(const Duration(seconds: 60));
      challenge.tick();
      await Future<void>.delayed(Duration.zero);
      expect(challenge.state.phase, ChallengePhase.finished);
      expect(challenge.state.collected, 12);
      expect(
        challenge.state.earned,
        StarChallengeRules.earned(ChallengeLevel.easy, points),
      );
      expect(challenge.state.newBest, isTrue);
      expect(
        progress.saved.bestOf(ChallengePiece.knight, ChallengeLevel.easy),
        points,
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
    expect(challenge.state.points, 0);
  });
}
