import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_review.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/game_details/view_models/game_details_cubit.dart';

import '../../../testing/fakes/fake_analysis_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_game_review_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';

void main() {
  late FakeProgressRepository progress;
  late FakeAnalysisRepository analysis;
  late FakeGameReviewRepository reviews;

  // Dama e rei contra rei: Qg7 é mate; Qg6 afoga.
  const start = '7k/8/5K2/8/8/8/8/6Q1 w - - 0 1';
  // Depois de Qg2: o mate em um ficou para trás.
  const afterQg2 = '7k/8/5K2/8/8/8/6Q1/8 b - - 1 1';
  final heaviest = GameDetailsCubit.budgets.length - 1;

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

  GameDetailsCubit build(int id, {bool previouslyReviewed = true}) {
    if (previouslyReviewed) {
      reviews.reviews.putIfAbsent(
        id,
        () => GameReview(
          moves: [
            for (final _ in progress.attempts[id - 1].moves)
              const ReviewedMove(
                before: EngineScore(centipawns: 0),
                after: EngineScore(centipawns: 0),
                quality: MoveQuality.best,
                accuracy: 100,
              ),
          ],
        ),
      );
    }
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

  /// Deixa a engine de mentira terminar o que já foi pedido.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test(
    'C12f: abrir sem análise inicia Rápida e grava precisão sem bloquear load',
    () async {
      final id = await save(['g1g2', 'h8h7', 'g2g7']);
      analysis.hold = Completer<void>();
      final gate = analysis.hold!;
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      final cubit = build(id, previouslyReviewed: false);
      final states = <GameDetailsState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);
      await cubit.load();
      expect(cubit.state.ready, isTrue);
      expect(cubit.state.reviewing, isTrue);
      expect(
        cubit.state.reviewWeight,
        GameDetailsCubit.reviewWeights[ReviewSpeed.quick],
      );
      expect(analysis.preemptible, [
        (start, GameDetailsCubit.budgets[1].depth),
      ]);
      expect(reviews.reviews[id], isNull);
      analysis.hold = null;
      gate.complete();
      await settle();
      expect(cubit.state.reviewing, isFalse);
      expect(cubit.state.review!.depth, 1);
      expect(cubit.state.review!.whiteAccuracy, isNotNull);
      expect(reviews.reviews[id], isNotNull);
      expect(
        states.map((state) => state.reviewProgress),
        containsAllInOrder([1 / 3, 2 / 3, 1]),
      );
    },
  );

  test(
    'C12f: load concorrente, retomada e toque Rápida não duplicam job',
    () async {
      final id = await save(['g1g2', 'h8h7', 'g2g7']);
      analysis.hold = Completer<void>();
      final gate = analysis.hold!;
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      final cubit = build(id, previouslyReviewed: false);
      await Future.wait([cubit.load(), cubit.load()]);
      expect(analysis.requests, [start]);
      await cubit.load();
      await cubit.review(speed: ReviewSpeed.quick);
      expect(analysis.requests, [start]);
      expect(cubit.state.reviewing, isTrue);
      analysis.hold = null;
      gate.complete();
      await settle();
      final count = analysis.requests.length;
      final saved = cubit.state.review;
      await cubit.load();
      await settle();
      expect(analysis.requests.length, count);
      expect(cubit.state.review, same(saved));
    },
  );

  test('C12f: análise salva não recalcula ao abrir ou reabrir', () async {
    final id = await save(['g1g2', 'h8h7', 'g2g7']);
    final saved = GameReview(
      moves: [
        for (var i = 0; i < 3; i++)
          const ReviewedMove(
            before: EngineScore(centipawns: 0),
            after: EngineScore(centipawns: 0),
            quality: MoveQuality.good,
            accuracy: 100,
            weight: 1,
          ),
      ],
      depth: 1,
    );
    reviews.reviews[id] = saved;
    final first = build(id, previouslyReviewed: false);
    await first.load();
    await first.load();
    final again = build(id, previouslyReviewed: false);
    await again.load();
    await settle();
    expect(first.state.review, same(saved));
    expect(again.state.review, same(saved));
    expect(first.state.reviewing, isFalse);
    expect(again.state.reviewing, isFalse);
    expect(analysis.requests, isEmpty);
  });

  test(
    'C12f: falha da engine libera a UI e permite tentar de novo manualmente',
    () async {
      analysis = _FailOnceAnalysis();
      final id = await save(['g1g2', 'h8h7', 'g2g7']);
      final cubit = build(id, previouslyReviewed: false);
      await cubit.load();
      await settle();
      expect(cubit.state.ready, isTrue);
      expect(cubit.state.reviewing, isFalse);
      expect(cubit.state.annotating, isEmpty);
      expect(cubit.state.review, isNull);
      expect(reviews.reviews[id], isNull);
      final calls = (analysis as _FailOnceAnalysis).calls;
      await cubit.load();
      await settle();
      expect((analysis as _FailOnceAnalysis).calls, calls);
      await cubit.review(speed: ReviewSpeed.quick);
      await settle();
      expect(cubit.state.reviewing, isFalse);
      expect(reviews.reviews[id], isNotNull);
    },
  );

  test('a revisão anda com o tabuleiro, anota lance a lance com o peso dela '
      'e guarda', () async {
    analysis.answer[start] = [line('g1g7', mate: 1)];
    final id = await save(['g1g2', 'h8h7', 'g2g7']);
    final cubit = build(id);
    await cubit.load();
    // Abre no início; a tela do último lance é a que já tinha anotação.
    cubit.last();
    await settle();
    expect(cubit.state.review, isNotNull);

    final shown = <int>[];
    final progress = <double>[];
    final unscored = <int>[];
    final listening = cubit.stream.listen((s) {
      if (shown.lastOrNull != s.shownIndex) shown.add(s.shownIndex);
      progress.add(s.reviewProgress);
      // O tabuleiro só chega no lance com a avaliação dele na barra.
      if (s.reviewing && s.shownScore == null) unscored.add(s.shownIndex);
    });
    await cubit.review();
    await settle();
    await listening.cancel();

    expect(shown, containsAllInOrder([-1, 0, 1, 2]));
    expect(unscored, isEmpty);
    expect(progress, containsAllInOrder([1 / 3, 2 / 3, 1.0]));
    expect(cubit.state.reviewing, isFalse);
    final review = cubit.state.review!;
    expect(review.moves[0].weight, 2);
    expect(review.moves[1].weight, 2);
    // O último lance, aberto na tela, já tinha anotação mais pesada.
    expect(review.moves[2].weight, heaviest);
    expect(review.depth, 2);
    expect(review.moves[0].best, 'g1g7');
    expect(review.whiteAccuracy, isNotNull);
    expect(reviews.reviews[id], same(review));
    // A barra recebe a avaliação de cada posição assim que a engine termina.
    expect(cubit.state.barScores.keys, containsAll([-1, 0, 1, 2]));
  });

  test('passando por todos os lances, sem revisar, a precisão aparece e fica '
      'guardada', () async {
    analysis.answer[start] = [line('g1g7', mate: 1), line('f6f7', mate: 2)];
    final id = await save(['g1g6']);
    final cubit = build(id);
    await cubit.load();
    cubit.last();
    await settle();

    final review = cubit.state.review!;
    expect(review.moves.single.quality, MoveQuality.blunder);
    expect(review.moves.single.best, 'g1g7');
    expect(review.whiteAccuracy, isNotNull);
    expect(reviews.reviews[id], same(review));
    // A posição final (afogado) não vai para a engine.
    expect(analysis.requests.toSet(), {start});
  });

  test('a revisão guardada volta ao reabrir, sem chamar a engine', () async {
    analysis.answer[start] = [line('g1g7', mate: 1)];
    final id = await save(['g1g7']);
    final first = build(id);
    await first.load();
    first.last();
    await settle();
    await first.review();
    analysis.requests.clear();

    final again = build(id);
    await again.load();
    again.last();
    await settle();
    expect(again.state.review!.moves.single.quality, MoveQuality.best);
    expect(again.state.live[0]!.weight, heaviest);
    expect(analysis.requests, isEmpty);
  });

  test('navegar: início, voltar, avançar e fim', () async {
    final id = await save(['g1g2', 'h8h7', 'g2g7']);
    final cubit = build(id);
    await cubit.load();
    // Abre na posição de início.
    expect(cubit.state.shownIndex, -1);
    expect(cubit.state.atStart, isTrue);
    cubit.last();
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

  for (final on in [true, false]) {
    test('a engine (e a barra) abre como ficou gravada: '
        '${on ? 'ligada' : 'desligada'}', () async {
      final id = await save(['g1g2', 'h8h7']);
      build(id);
      final cubit = GameDetailsCubit(
        id,
        progress: progress,
        characters: FakeCharacterRepository(),
        analysis: analysis,
        reviews: reviews,
        settings: FakeSettingsRepository(AppSettings(evalBar: on)),
      );
      addTearDown(cubit.close);
      await cubit.load();
      await settle();
      expect(cubit.state.engine, on);
      // Ligada, as linhas da posição de início já saem ao abrir.
      expect(cubit.state.engineLines.containsKey(-1), on);
    });
  }

  test('setEngine liga e desliga só quando muda', () async {
    final id = await save(['g1g2', 'h8h7']);
    final cubit = build(id);
    await cubit.load();
    await cubit.setEngine(on: true);
    expect(cubit.state.engine, isTrue);
    final count = analysis.requests.length;
    await cubit.setEngine(on: true);
    expect(analysis.requests.length, count);
    await cubit.setEngine(on: false);
    expect(cubit.state.engine, isFalse);
  });

  test('a engine ligada calcula as linhas da posição mostrada', () async {
    final id = await save(['g1g2', 'h8h7']);
    final cubit = build(id);
    await cubit.load();
    cubit.last();

    await cubit.setEngine(on: !cubit.state.engine);
    expect(cubit.state.engine, isTrue);
    expect(cubit.state.shownLines, hasLength(3));

    cubit.first();
    await settle();
    expect(cubit.state.engineLines.keys, containsAll([-1, 1]));
    expect(analysis.requests, contains(start));

    await cubit.setEngine(on: !cubit.state.engine);
    expect(cubit.state.engine, isFalse);
  });

  test('em tempo real: o lance mostrado é avaliado ao abrir e ao passar '
      'para ele, sem revisar a partida', () async {
    analysis.answer[start] = [line('g1g7', mate: 1)];
    final id = await save(['g1g2', 'h8h7', 'g2g7']);
    final cubit = build(id);
    await cubit.load();
    // Abre no início; indo ao último lance (o mate), ele é anotado na hora.
    expect(cubit.state.shownIndex, -1);
    cubit.last();
    await settle();
    expect(cubit.state.live[2], isNotNull);
    expect(cubit.state.review, isNotNull);

    cubit.select(0);
    await settle();
    expect(cubit.state.shownReview, isNotNull);
    expect(cubit.state.shownReview!.best, 'g1g7');
    expect(cubit.state.annotating, isEmpty);
  });

  test('ficando no lance, a engine sobe os pesos e a anotação mais pesada '
      'troca a mais leve', () async {
    // Raso, Qg2 parece o melhor; fundo, a engine vê o mate em um que ficou
    // para trás: imprecisão.
    final shallow = GameDetailsCubit.budgets.first.depth;
    analysis.answerAt[(start, shallow)] = [line('g1g2', mate: 3)];
    analysis.answerAt[(afterQg2, shallow)] = [line('h8h7', mate: 2)];
    analysis.answer[start] = [line('g1g7', mate: 1)];
    analysis.answer[afterQg2] = [line('h8h7', mate: 3)];
    final id = await save(['g1g2', 'h8h7']);
    final cubit = build(id);
    await cubit.load();
    await settle();

    final qualities = <MoveQuality>[];
    final listening = cubit.stream.listen((s) {
      final quality = s.live[0]?.quality;
      if (quality != null && qualities.lastOrNull != quality) {
        qualities.add(quality);
      }
    });
    cubit.select(0);
    await settle();
    await listening.cancel();

    expect(qualities, [MoveQuality.best, MoveQuality.inaccuracy]);
    expect(cubit.state.live[0]!.weight, heaviest);
    // Os pesos acima do instantâneo são interrompíveis, um por orçamento.
    expect(analysis.preemptible.where((r) => r.$1 == start).map((r) => r.$2), [
      for (final budget in GameDetailsCubit.budgets.skip(1)) budget.depth,
    ]);

    // A revisão (mais leve) não troca a anotação de quem ficou no lance.
    await cubit.review(speed: ReviewSpeed.quick);
    expect(cubit.state.live[0]!.weight, heaviest);
    expect(cubit.state.live[0]!.quality, MoveQuality.inaccuracy);
  });

  test('saindo do lance no meio da conta longa, a engine para', () async {
    final id = await save(['g1g2', 'h8h7', 'g2g7']);
    final cubit = build(id);
    await cubit.load();
    await settle();

    analysis.interrupt = 1;
    cubit.select(0);
    await settle();
    // Só o instantâneo: a conta do peso 1 foi interrompida.
    expect(cubit.state.live[0]!.weight, 0);
    expect(cubit.state.annotating, isEmpty);
  });

  test('a revisão interrompida pede de novo e termina', () async {
    final id = await save(['g1g2', 'h8h7', 'g2g7']);
    final cubit = build(id);
    await cubit.load();
    await settle();

    analysis.interrupt = 2;
    await cubit.review();
    expect(cubit.state.review, isNotNull);
    expect(cubit.state.live[0]!.weight, 2);
    expect(cubit.state.live[1]!.weight, 2);
  });

  test('revisão rápida, média e profunda: o peso de cada uma', () async {
    final id = await save(['g1g2', 'h8h7', 'g2g7']);
    for (final speed in ReviewSpeed.values) {
      reviews = FakeGameReviewRepository();
      final cubit = build(id);
      await cubit.load();
      await settle();
      await cubit.review(speed: speed);
      final weight = GameDetailsCubit.reviewWeights[speed]!;
      expect(cubit.state.review!.depth, weight);
      expect(cubit.state.live[0]!.weight, weight);
      expect(cubit.state.review!.whiteAccuracy, isNotNull);
    }
  });

  test(
    'mexendo no tabuleiro durante a revisão, ele para de acompanhar',
    () async {
      final id = await save(['g1g2', 'h8h7', 'g2g7']);
      final cubit = build(id);
      await cubit.load();
      await settle();

      final running = cubit.review();
      cubit.select(-1);
      await running;
      expect(cubit.state.shownIndex, -1);
      expect(cubit.state.review, isNotNull);
    },
  );
}

class _FailOnceAnalysis extends FakeAnalysisRepository {
  int calls = 0;
  @override
  Future<List<EngineLine>> analyse(
    Position position, {
    required int depth,
    int lines = 1,
    bool urgent = false,
    Duration? time,
    bool preemptible = false,
  }) {
    if (calls++ == 0) return Future.error(StateError('engine unavailable'));
    return super.analyse(
      position,
      depth: depth,
      lines: lines,
      urgent: urgent,
      time: time,
      preemptible: preemptible,
    );
  }
}
