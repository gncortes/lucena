import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_review.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/game_details/view_models/game_details_cubit.dart';

import '../../../testing/fakes/fake_analysis_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_game_review_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';

void main() {
  late FakeProgressRepository progress;
  late FakeAnalysisRepository analysis;
  late FakeGameReviewRepository reviews;

  // Dama e rei contra rei: Qg7 é mate; Qg6 afoga.
  const start = '7k/8/5K2/8/8/8/8/6Q1 w - - 0 1';

  setUp(() {
    progress = FakeProgressRepository();
    analysis = FakeAnalysisRepository();
    reviews = FakeGameReviewRepository();
  });

  Future<int> save(List<String> moves) => progress.addAttempt(
    Attempt(
      positionId: 'basic.queen.0001',
      playedAt: DateTime.utc(2026, 10, 6, 12),
      outcome: AttemptOutcome.win,
      fulfilled: true,
      opponent: OpponentKind.maia,
      opponentLevel: 1000,
      startFen: start,
      moves: moves,
      userSide: Side.white,
    ),
  );

  GameDetailsCubit build(int id) {
    final cubit = GameDetailsCubit(
      id,
      progress: progress,
      characters: FakeCharacterRepository(),
      analysis: analysis,
      reviews: reviews,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  EngineLine line(String uci, {int? cp, int? mate}) => EngineLine(
    score: EngineScore(centipawns: cp, mate: mate),
    moves: [uci],
  );

  test('revisar: analisa cada posição, anota o lance e guarda', () async {
    analysis.answer[start] = [line('g1g7', mate: 1), line('f6f7', mate: 2)];
    final id = await save(['g1g6']);
    final cubit = build(id);
    await cubit.load();
    expect(cubit.state.review, isNull);

    final progress = <double>[];
    final listening = cubit.stream.listen(
      (s) => progress.add(s.reviewProgress),
    );
    await cubit.review();
    await listening.cancel();

    final review = cubit.state.review!;
    expect(cubit.state.reviewing, isFalse);
    expect(review.moves.single.quality, MoveQuality.blunder);
    expect(review.moves.single.best, 'g1g7');
    expect(progress, contains(0.5));
    expect(cubit.state.reviewProgress, 1);
    // A posição final (afogado) não vai para a engine.
    expect(analysis.requests, [start]);
    expect(reviews.reviews[id], same(review));
  });

  test('a revisão guardada volta ao reabrir, sem chamar a engine', () async {
    analysis.answer[start] = [line('g1g7', mate: 1)];
    final id = await save(['g1g7']);
    final first = build(id);
    await first.load();
    await first.review();
    analysis.requests.clear();

    final again = build(id);
    await again.load();
    expect(again.state.review!.moves.single.quality, MoveQuality.best);
    expect(analysis.requests, isEmpty);
  });

  test('navegar: início, voltar, avançar e fim', () async {
    final id = await save(['g1g2', 'h8h7', 'g2g7']);
    final cubit = build(id);
    await cubit.load();
    expect(cubit.state.shownIndex, 2);
    expect(cubit.state.atEnd, isTrue);

    cubit.previous();
    expect(cubit.state.shownIndex, 1);
    cubit.first();
    expect(cubit.state.shownIndex, -1);
    expect(cubit.state.atStart, isTrue);
    cubit.previous();
    expect(cubit.state.shownIndex, -1);
    cubit.next();
    expect(cubit.state.shownIndex, 0);
    cubit.last();
    expect(cubit.state.shownIndex, 2);
  });

  test('a engine ligada calcula as linhas da posição mostrada', () async {
    final id = await save(['g1g2', 'h8h7']);
    final cubit = build(id);
    await cubit.load();

    await cubit.toggleEngine();
    expect(cubit.state.engine, isTrue);
    expect(cubit.state.shownLines, hasLength(3));

    cubit.first();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.engineLines.keys, containsAll([-1, 1]));
    expect(analysis.requests.last, startsWith('7k/8/5K2/8/8/8/8/6Q1'));

    await cubit.toggleEngine();
    expect(cubit.state.engine, isFalse);
  });
}
