import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/game_feedback.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/conclusion.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_review.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/ui/conclusion/view_models/conclusion_cubit.dart';
import 'package:lucena/ui/free_board/view_models/game_reporter.dart';

import '../../../testing/fakes/fake_achievements_repository.dart';
import '../../../testing/fakes/fake_analysis_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_game_review_repository.dart';
import '../../../testing/fakes/fake_conclusion_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';

void main() {
  late FakeProgressRepository progress;
  late FakeAchievementsRepository achievements;
  late FakeRatingRepository rating;
  late FakeSpeedrunRepository speedruns;
  late FakeConclusionRepository pending;
  late GameReporter reporter;
  final now = FakeNow(DateTime.utc(2026, 10, 8, 12));

  setUp(() {
    progress = FakeProgressRepository();
    achievements = FakeAchievementsRepository();
    rating = FakeRatingRepository();
    speedruns = FakeSpeedrunRepository(progress);
    pending = FakeConclusionRepository();
    reporter = GameReporter(
      rating: rating,
      achievements: achievements,
      journey: FakeJourneyRepository(),
      progress: progress,
      speedruns: speedruns,
      positions: FakePositionsRepository(),
      now: now,
    );
  });

  ConclusionCubit cubit({
    FakeAnalysisRepository? analysis,
    FakeGameReviewRepository? reviews,
  }) => ConclusionCubit(
    analysis: analysis,
    reviews: reviews,
    progress: progress,
    rating: rating,
    achievements: achievements,
    journey: FakeJourneyRepository(),
    speedruns: speedruns,
    positions: FakePositionsRepository(),
    characters: FakeCharacterRepository(),
    now: now,
    pending: pending,
  );

  /// Joga e grava a partida como o tabuleiro faz no fim: a partida, o
  /// rating, as conquistas e o passo do speedrun.
  Future<int> play({
    required bool won,
    String? challengeId,
    int? attemptId,
    int? stage,
    String? positionId,
    String? fen,
  }) async {
    final game = Attempt(
      positionId: positionId ?? samplePositions[0].id,
      playedAt: now(),
      outcome: won ? AttemptOutcome.win : AttemptOutcome.loss,
      fulfilled: won,
      opponent: OpponentKind.maia,
      opponentLevel: 1000,
      startFen: fen ?? samplePositions[0].fen,
      userSide: Side.white,
      endReason: won ? GameEndReason.checkmate : GameEndReason.resign,
      userClock: const Duration(seconds: 42),
      challengeId: challengeId,
      speedrunAttemptId: attemptId,
      speedrunStage: stage,
    );
    final id = await progress.addAttempt(game);
    await reporter.report(
      game,
      gameId: id,
      userSide: Side.white,
      drawGoal: false,
    );
    return id;
  }

  test('duas vitórias iguais (mesma hora): só a primeira diz "pela primeira '
      'vez"', () async {
    final first = await play(won: true);
    final second = await play(won: true);
    bool firstWin(ConclusionState state) => state.feedback.any(
      (feedback) => feedback.kind == FeedbackKind.firstWinAgainstLevel,
    );

    final a = cubit();
    await a.load(first, 'en');
    expect(firstWin(a.state), isTrue);
    final b = cubit();
    await b.load(second, 'en');
    expect(firstWin(b.state), isFalse);
  });

  test('desafio da Jornada perdido: rating de antes e depois, o próximo '
      'desafio e as ações da Jornada', () async {
    final id = await play(
      won: false,
      challengeId: sampleLadder[0].challenges[0].id,
    );
    final conclusions = cubit();
    await conclusions.load(id, 'en');
    final state = conclusions.state;
    final conclusion = state.conclusion!;

    expect(conclusion.kind, ConclusionKind.journey);
    expect(conclusion.result, ConclusionResult.lost);
    expect(conclusion.end?.reason, GameEndReason.resign);
    expect(conclusion.ratingDelta, lessThan(0));
    // Perdeu: o mesmo desafio de novo, sem pular para o próximo.
    expect(conclusion.next, isNull);
    expect(conclusion.actions.first, ConclusionAction.playAgain);
    expect(conclusion.actions, contains(ConclusionAction.analyze));
    expect(state.opponent?.level, 1000);
    expect(state.comment, isNotNull);
    expect(state.replay, contains('challenge='));
    await conclusions.close();
  });

  test('desafio vencido: "Próximo desafio" primeiro', () async {
    final id = await play(
      won: true,
      challengeId: sampleLadder[0].challenges[0].id,
    );
    final conclusions = cubit();
    await conclusions.load(id, 'en');
    final conclusion = conclusions.state.conclusion!;

    expect(conclusion.next?.id, sampleLadder[0].challenges[1].id);
    expect(conclusion.actions.first, ConclusionAction.nextChallenge);
    expect(conclusion.achievements, isNotEmpty);
    await conclusions.close();
  });

  test('reaberta: o mesmo rating e as mesmas conquistas, sem contar de '
      'novo', () async {
    final id = await play(won: true);
    final first = cubit();
    await first.load(id, 'en');
    final again = cubit();
    await again.load(id, 'en');

    expect(
      again.state.conclusion!.after!.rating,
      first.state.conclusion!.after!.rating,
    );
    expect(
      again.state.conclusion!.achievements.map((a) => a.id),
      first.state.conclusion!.achievements.map((a) => a.id),
    );
    expect((await rating.history()).length, 1);
    await first.close();
    await again.close();
  });

  test('a conclusão aberta fica gravada até sair dela', () async {
    final id = await play(won: true);
    final conclusions = cubit();
    await conclusions.load(id, 'en');
    expect(await pending.pending(), id);

    await conclusions.close();
    expect(await pending.pending(), isNull);
  });

  test('partida que não existe: a tela avisa que falta', () async {
    final conclusions = cubit();
    await conclusions.load(99, 'en');
    expect(conclusions.state.missing, isTrue);
    await conclusions.close();
  });

  group('speedrun', () {
    final pace = SpeedrunPaces.all.first;
    final speedrunId = SpeedrunPaces.idFor(sampleSpeedruns[0].id, pace);
    final stages = SpeedrunPaces.withTime(sampleSpeedruns[0], pace).stages;

    Future<int> stage(int attemptId, int index, {required bool won}) => play(
      won: won,
      attemptId: attemptId,
      stage: index,
      positionId: stages[index].position.id,
      fen: stages[index].position.fen,
    );

    test('etapa vencida: o tempo dela e "Continuar" para a próxima', () async {
      final attempt = await speedruns.start(speedrunId, now());
      final id = await stage(attempt.id, 0, won: true);
      final conclusions = cubit();
      await conclusions.load(id, 'en');
      final conclusion = conclusions.state.conclusion!;

      expect(conclusion.kind, ConclusionKind.speedrunStage);
      expect(conclusion.actions.first, ConclusionAction.nextStage);
      expect(conclusion.run!.nextStage, 1);
      expect(conclusion.run!.stages[0].time, const Duration(seconds: 42));
      // O tempo de relógio gasto, como o jogador viu.
      expect(conclusion.run!.spent[0], const Duration(seconds: 42));
      expect(conclusion.run!.spentSoFar, const Duration(seconds: 42));
      await conclusions.close();
    });

    test('última etapa: o fim, com o total e o recorde', () async {
      final attempt = await speedruns.start(speedrunId, now());
      await stage(attempt.id, 0, won: true);
      final id = await stage(attempt.id, 1, won: true);
      final conclusions = cubit();
      await conclusions.load(id, 'en');
      final conclusion = conclusions.state.conclusion!;

      expect(conclusion.kind, ConclusionKind.speedrunEnd);
      expect(conclusion.run!.total, const Duration(seconds: 84));
      expect(conclusion.run!.newRecord, isTrue);
      expect(conclusion.actions.take(2), [
        ConclusionAction.retry,
        ConclusionAction.speedruns,
      ]);
      await conclusions.close();
    });

    test('etapa perdida: a tentativa acabou; tentar de novo começa outra, '
        'da primeira etapa', () async {
      final attempt = await speedruns.start(speedrunId, now());
      final id = await stage(attempt.id, 0, won: false);
      final conclusions = cubit();
      await conclusions.load(id, 'en');
      expect(conclusions.state.conclusion!.kind, ConclusionKind.speedrunLost);

      final route = await conclusions.retry();
      expect(route, contains('stage=0'));
      expect(route, isNot(contains('attempt=${attempt.id}&')));
      expect((await speedruns.attempts(speedrunId)).length, 2);
      await conclusions.close();
    });
  });

  group('em segundo plano', () {
    test('a melhor linha sai sozinha; a análise rápida só no toque, e fica '
        'gravada para a tela da revisão', () async {
      final analysis = FakeAnalysisRepository();
      final reviews = FakeGameReviewRepository();
      final id = await play(won: true);
      progress.attempts[id - 1] = progress.attempts[id - 1].copyWith(
        moves: const ['c1g5'],
      );
      final conclusions = cubit(analysis: analysis, reviews: reviews);
      await conclusions.load(id, 'en');
      // As ações já estão prontas antes da engine terminar.
      expect(conclusions.state.conclusion, isNotNull);
      await pumpEventQueue();

      expect(conclusions.state.bestLine, isNotEmpty);
      // Sem tocar em "Análise rápida", nada de revisão.
      expect(conclusions.state.review, isNull);
      expect(await reviews.load(id), isNull);

      await conclusions.quickReview();
      expect(conclusions.state.review, isNotNull);
      // Vale como a revisão rápida: a tela da revisão já a mostra feita.
      expect((await reviews.load(id))!.depth, ConclusionCubit.reviewWeight);
      expect(conclusions.state.reviewDone, 1);
      expect(conclusions.state.reviewing, isFalse);
      expect(await reviews.load(id), isNotNull);
      await conclusions.close();
    });

    test('revisão já gravada: não calcula de novo', () async {
      final analysis = FakeAnalysisRepository();
      final reviews = FakeGameReviewRepository();
      final id = await play(won: true);
      progress.attempts[id - 1] = progress.attempts[id - 1].copyWith(
        moves: const ['c1g5'],
      );
      final first = cubit(analysis: analysis, reviews: reviews);
      await first.load(id, 'en');
      await pumpEventQueue();
      await first.quickReview();
      final asked = analysis.requests.length;
      final again = cubit(analysis: analysis, reviews: reviews);
      await again.load(id, 'en');
      await pumpEventQueue();

      expect(again.state.review, isNotNull);
      // Só a melhor linha foi pedida de novo.
      expect(analysis.requests.length, asked + 1);
      await first.close();
      await again.close();
    });

    test('a melhor linha anda e volta lance a lance', () async {
      final analysis = FakeAnalysisRepository();
      final id = await play(won: true);
      analysis.answer[samplePositions[0].fen] = [
        const EngineLine(
          score: EngineScore(centipawns: 900),
          moves: ['c1g5', 'd7e6', 'g5g6'],
        ),
      ];
      final conclusions = cubit(analysis: analysis);
      await conclusions.load(id, 'en');
      await pumpEventQueue();

      expect(conclusions.state.bestPly, -1);
      conclusions
        ..bestForward()
        ..bestForward();
      expect(conclusions.state.bestPly, 1);
      conclusions
        ..bestForward()
        ..bestForward();
      expect(conclusions.state.bestPly, 2);
      conclusions
        ..bestBack()
        ..bestBack()
        ..bestBack()
        ..bestBack();
      expect(conclusions.state.bestPly, -1);
      await conclusions.close();
    });
  });
}
