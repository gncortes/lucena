import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/data/repositories/deep_analysis/deep_analysis_repository.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/game_details/view_models/game_details_cubit.dart';

import '../../../testing/fakes/fake_analysis_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_game_review_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_progress_repository.dart';

void main() {
  // H-PAR-13: a análise a fundo roda em segundo plano e sobrevive à saída da
  // tela.
  const start = '7k/8/5K2/8/8/8/8/6Q1 w - - 0 1';
  late FakeProgressRepository progress;
  late FakeAnalysisRepository analysis;
  late FakeGameReviewRepository reviews;
  late FakeNow now;
  late EngineDeepAnalysisRepository deep;

  setUp(() {
    progress = FakeProgressRepository();
    analysis = FakeAnalysisRepository();
    reviews = FakeGameReviewRepository();
    now = FakeNow(DateTime.utc(2026, 10, 6, 12));
    deep = EngineDeepAnalysisRepository(
      analysis: analysis,
      reviews: reviews,
      now: now,
    );
  });

  GameDetailsCubit open(int id) {
    final cubit = GameDetailsCubit(
      id,
      progress: progress,
      characters: FakeCharacterRepository(),
      analysis: analysis,
      reviews: reviews,
      deepAnalysis: deep,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('sair da tela no meio da análise a fundo não a interrompe', () async {
    final id = await progress.addAttempt(
      Attempt(
        positionId: 'basic.queen.0001',
        playedAt: DateTime.utc(2026, 10, 6, 12),
        outcome: AttemptOutcome.win,
        fulfilled: true,
        opponent: OpponentKind.maia,
        opponentLevel: 1000,
        startFen: start,
        moves: const ['g1g2', 'h8h7', 'g2g7'],
        userSide: Side.white,
      ),
    );
    final first = open(id);
    await first.load();
    await first.review(speed: ReviewSpeed.quick);
    expect(reviews.reviews[id]!.depth, 1);

    final hold = Completer<void>();
    analysis.hold = hold;
    addTearDown(() {
      if (!hold.isCompleted) hold.complete();
    });
    unawaited(first.review(speed: ReviewSpeed.deep));
    await settle();
    expect(first.state.reviewing, isTrue);

    // Sai da tela: o cubit da rota é descartado.
    await first.close();
    hold.complete();
    analysis.hold = null;
    await settle();
    await settle();

    final second = open(id);
    await second.load();
    await settle();
    expect(second.state.reviewing, isFalse);
    expect(
      second.state.review!.depth,
      GameDetailsCubit.reviewWeights[ReviewSpeed.deep],
    );
  });

  test('voltar à tela com a análise rodando retoma o progresso e o '
      'resultado chega', () async {
    final id = await progress.addAttempt(_game());
    final first = open(id);
    await first.load();
    await first.review(speed: ReviewSpeed.quick);
    final hold = Completer<void>();
    analysis.hold = hold;
    addTearDown(() {
      if (!hold.isCompleted) hold.complete();
    });
    unawaited(first.review(speed: ReviewSpeed.deep));
    await settle();
    await first.close();

    final second = open(id);
    await second.load();
    await settle();
    expect(second.state.reviewing, isTrue);
    expect(
      second.state.reviewWeight,
      GameDetailsCubit.reviewWeights[ReviewSpeed.deep],
    );
    hold.complete();
    analysis.hold = null;
    await settle();
    await settle();
    expect(second.state.reviewing, isFalse);
    expect(
      second.state.review!.depth,
      GameDetailsCubit.reviewWeights[ReviewSpeed.deep],
    );
    expect(reviews.reviews[id]!.depth, 3);
  });

  test('pedir de novo a mesma partida não duplica o trabalho', () async {
    final id = await progress.addAttempt(_game());
    final first = open(id);
    await first.load();
    await first.review(speed: ReviewSpeed.quick);
    final hold = Completer<void>();
    analysis.hold = hold;
    addTearDown(() {
      if (!hold.isCompleted) hold.complete();
    });
    unawaited(first.review(speed: ReviewSpeed.deep));
    await settle();
    await first.close();
    final second = open(id);
    await second.load();
    final before = analysis.requests.length;
    unawaited(second.review(speed: ReviewSpeed.deep));
    await settle();
    hold.complete();
    analysis.hold = null;
    await settle();
    await settle();
    // Uma análise só: uma posição por pedido, quatro posições.
    expect(analysis.requests.length - before + 0, lessThanOrEqualTo(4));
    expect(deep.job(id)!.startedAt, now());
  });
}

Attempt _game() => Attempt(
  positionId: 'basic.queen.0001',
  playedAt: DateTime.utc(2026, 10, 6, 12),
  outcome: AttemptOutcome.win,
  fulfilled: true,
  opponent: OpponentKind.maia,
  opponentLevel: 1000,
  startFen: '7k/8/5K2/8/8/8/8/6Q1 w - - 0 1',
  moves: const ['g1g2', 'h8h7', 'g2g7'],
  userSide: Side.white,
);
