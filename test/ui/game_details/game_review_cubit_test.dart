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
    // A posição final (afogado) não vai para a engine: só a de início, na
    // avaliação rápida da abertura e de novo, mais funda, na revisão.
    expect(analysis.requests.toSet(), {start});
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
    // Não refaz a partida: no máximo aprofunda o lance que está na tela.
    expect(analysis.requests.length, lessThanOrEqualTo(1));
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

  test('em tempo real: o lance mostrado é avaliado ao abrir e ao passar '
      'para ele, sem revisar a partida', () async {
    analysis.answer[start] = [line('g1g7', mate: 1)];
    final id = await save(['g1g2', 'h8h7', 'g2g7']);
    final cubit = build(id);
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    // Abre no último lance (o mate): já anotado.
    expect(cubit.state.live[2], isNotNull);
    expect(cubit.state.review, isNull);

    cubit.select(0);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.shownReview, isNotNull);
    expect(cubit.state.shownReview!.best, 'g1g7');
    expect(cubit.state.annotating, isEmpty);
  });

  test(
    'a revisão anota lance a lance, mais funda que a avaliação rápida',
    () async {
      final id = await save(['g1g2', 'h8h7', 'g2g7']);
      final cubit = build(id);
      await cubit.load();
      await Future<void>.delayed(Duration.zero);
      final before = analysis.requests.length;

      final seen = <int>[];
      final listening = cubit.stream.listen((s) => seen.add(s.live.length));
      await cubit.review();
      await listening.cancel();

      expect(seen, containsAllInOrder([1, 2, 3]));
      expect(cubit.state.review!.moves, hasLength(3));
      // A revisão refaz, mais funda, só as posições que a avaliação na hora
      // ainda não tinha passado da profundidade dela; a final (mate) não vai
      // para a engine.
      expect(analysis.requests.length - before, inInclusiveRange(1, 3));

      // Com a revisão feita, a anotação do lance aparece na hora.
      cubit.first();
      cubit.next();
      expect(cubit.state.shownReview, isNotNull);
    },
  );

  test(
    'ficando no lance, a anotação vai até a profundidade mais funda',
    () async {
      // Qg2 deixa o mate em um e leva a um mate em três: imprecisão.
      final after = '7k/8/5K2/8/8/8/6Q1/8 b - - 1 1';
      analysis.answer[start] = [line('g1g7', mate: 1)];
      analysis.answer[after] = [line('h8h7', mate: 3)];
      final id = await save(['g1g2', 'h8h7']);
      final cubit = build(id);
      await cubit.load();
      cubit.select(0);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.liveDepths[0], GameDetailsCubit.liveDepths.last);
      expect(cubit.state.shownReview!.quality, MoveQuality.inaccuracy);
    },
  );

  test(
    'revisão rápida, média e profunda: a profundidade fica guardada',
    () async {
      final id = await save(['g1g2', 'h8h7', 'g2g7']);
      for (final speed in ReviewSpeed.values) {
        final cubit = build(id);
        await cubit.load();
        await cubit.review(speed: speed);
        expect(cubit.state.review!.depth, GameDetailsCubit.reviewDepths[speed]);
        expect(cubit.state.review!.whiteAccuracy, isNotNull);
      }
    },
  );
}
