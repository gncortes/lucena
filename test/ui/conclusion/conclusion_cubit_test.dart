import 'dart:async';

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
import '../../../testing/fakes/fake_opponent_repository.dart';
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
    FakeOpponentRepository? opponent,
  }) => ConclusionCubit(
    opponent: opponent,
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
    // A análise detalhada sai do resumo da análise rápida, não dos atalhos.
    expect(conclusion.actions, contains(ConclusionAction.ratingHistory));
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
      // Só a volta para a lista, sem "Tentar de novo".
      expect(conclusion.actions.first, ConclusionAction.speedruns);
      expect(conclusion.actions, isNot(contains(ConclusionAction.retry)));
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
    // Uma partida longa: 16 lances (a dama e o rei indo e voltando), em
    // cinco minutos.
    const longMoves = [
      'c1b1', 'd7e7', 'b1c1', 'e7d7', //
      'c1b1', 'd7e7', 'b1c1', 'e7d7',
      'c1b1', 'd7e7', 'b1c1', 'e7d7',
      'c1b1', 'd7e7', 'b1c1', 'e7d7',
    ];

    test('partida longa: a análise rápida só no toque, e fica gravada para a '
        'tela da revisão', () async {
      final analysis = FakeAnalysisRepository();
      final reviews = FakeGameReviewRepository();
      final id = await play(won: true);
      progress.attempts[id - 1] = progress.attempts[id - 1].copyWith(
        moves: longMoves,
        startedAt: now().subtract(const Duration(minutes: 5)),
      );
      final conclusions = cubit(analysis: analysis, reviews: reviews);
      await conclusions.load(id, 'en');
      expect(conclusions.state.conclusion, isNotNull);
      await pumpEventQueue();

      expect(conclusions.state.autoReview, isFalse);
      expect(conclusions.state.reviewing, isFalse);
      // Sem tocar em "Análise rápida", nada de revisão nem de engine.
      expect(conclusions.state.review, isNull);
      expect(analysis.requests, isEmpty);
      expect(await reviews.load(id), isNull);

      await conclusions.quickReview();
      expect(conclusions.state.review, isNotNull);
      // Vale como a revisão rápida: a tela da revisão já a mostra feita.
      expect((await reviews.load(id))!.depth, ConclusionCubit.reviewWeight);
      expect(conclusions.state.reviewDone, longMoves.length);
      expect(conclusions.state.reviewing, isFalse);
      await conclusions.close();
    });

    test('partida curta: a análise rápida começa sozinha, andando, e fica '
        'gravada', () async {
      final analysis = FakeAnalysisRepository()..hold = Completer<void>();
      final reviews = FakeGameReviewRepository();
      final id = await play(won: true);
      progress.attempts[id - 1] = progress.attempts[id - 1].copyWith(
        moves: const ['c1g5'],
      );
      final conclusions = cubit(analysis: analysis, reviews: reviews);
      await conclusions.load(id, 'en');
      // Já abre com a análise rodando, sem toque.
      expect(conclusions.state.autoReview, isTrue);
      expect(conclusions.state.reviewing, isTrue);
      await pumpEventQueue();
      expect(conclusions.state.review, isNull);
      expect(analysis.requests, isNotEmpty);

      analysis.hold!.complete();
      analysis.hold = null;
      await pumpEventQueue();
      expect(conclusions.state.reviewing, isFalse);
      expect(conclusions.state.review, isNotNull);
      expect(await reviews.load(id), isNotNull);
      await conclusions.close();
    });

    test('partida curta com a engine falhando: o convite volta', () async {
      final id = await play(won: true);
      progress.attempts[id - 1] = progress.attempts[id - 1].copyWith(
        moves: const ['c1g5'],
      );
      final conclusions = cubit(analysis: _FailingAnalysis());
      await conclusions.load(id, 'en');
      await pumpEventQueue();
      expect(conclusions.state.reviewing, isFalse);
      expect(conclusions.state.review, isNull);
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
      expect(first.state.review, isNotNull);
      final asked = analysis.requests.length;
      final again = cubit(analysis: analysis, reviews: reviews);
      await again.load(id, 'en');
      await pumpEventQueue();

      expect(again.state.review, isNotNull);
      expect(again.state.reviewing, isFalse);
      expect(analysis.requests.length, asked);
      await first.close();
      await again.close();
    });
  });

  group('melhor linha', () {
    test('o Stockfish (1 s) no lugar do jogador contra o mesmo adversário '
        '(o Maia no nível dele), lance a lance', () async {
      final opponent = FakeOpponentRepository();
      final id = await play(won: true);
      final conclusions = cubit(opponent: opponent);
      await conclusions.load(id, 'en');
      expect(conclusions.canPlayBestLine, isTrue);
      final seen = <int>[];
      final sub = conclusions.stream.listen(
        (state) => seen.add(state.bestLine.length),
      );

      await conclusions.playBestLine();
      final state = conclusions.state;
      expect(state.bestLineDone, isTrue);
      expect(state.bestLineRunning, isFalse);
      expect(state.bestLine, isNotEmpty);
      // Os lances chegaram um a um, com o tabuleiro no último.
      expect(seen, containsAllInOrder([1, 2]));
      expect(state.bestPly, state.bestLine.length - 1);
      // As brancas (o jogador) com o Stockfish; as pretas com o Maia 1000.
      expect(opponent.kinds.first, OpponentKind.stockfish);
      expect(opponent.levels.first, isNull);
      if (opponent.kinds.length > 1) {
        expect(opponent.kinds[1], OpponentKind.maia);
        expect(opponent.levels[1], 1000);
      }
      for (final (index, kind) in opponent.kinds.indexed) {
        expect(kind, index.isEven ? OpponentKind.stockfish : OpponentKind.maia);
      }
      expect(opponent.thinkTimes.toSet(), {ConclusionCubit.bestLineThink});
      expect(ConclusionCubit.bestLineThink, const Duration(seconds: 1));
      // Pronta, dá para voltar e avançar.
      conclusions.bestBack();
      expect(conclusions.state.bestPly, state.bestLine.length - 2);
      conclusions.bestForward();
      expect(conclusions.state.bestPly, state.bestLine.length - 1);
      await sub.cancel();
      await conclusions.close();
    });

    test('contra o Stockfish: o Stockfish dos dois lados', () async {
      final opponent = FakeOpponentRepository();
      final id = await play(won: true);
      progress.attempts[id - 1] = progress.attempts[id - 1].copyWith(
        opponent: OpponentKind.stockfish,
        opponentLevel: null,
      );
      final conclusions = cubit(opponent: opponent);
      await conclusions.load(id, 'en');
      await conclusions.playBestLine();
      expect(opponent.kinds.toSet(), {OpponentKind.stockfish});
      await conclusions.close();
    });

    test('sem quem jogar, nada a mostrar', () async {
      final id = await play(won: true);
      final conclusions = cubit();
      await conclusions.load(id, 'en');
      expect(conclusions.canPlayBestLine, isFalse);
      await conclusions.close();
    });
  });
}

/// Uma engine que sempre falha.
class _FailingAnalysis extends FakeAnalysisRepository {
  @override
  Future<List<EngineLine>> analyse(
    Position position, {
    required int depth,
    int lines = 1,
    bool urgent = false,
    Duration? time,
    bool preemptible = false,
  }) async => throw StateError('engine');
}
