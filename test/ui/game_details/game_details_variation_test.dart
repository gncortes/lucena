import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/game_details/view_models/game_details_cubit.dart';

import '../../../testing/fakes/fake_analysis_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_game_review_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';

void main() {
  late FakeProgressRepository progress;
  late FakeAnalysisRepository analysis;
  late FakeGameReviewRepository reviews;

  setUp(() {
    progress = FakeProgressRepository();
    analysis = FakeAnalysisRepository();
    reviews = FakeGameReviewRepository();
  });

  // 1. e4 e5 2. Nf3.
  Future<GameDetailsCubit> load({bool engine = false}) async {
    final id = await progress.addAttempt(
      Attempt(
        positionId: 'basic.queen.0001',
        playedAt: DateTime.utc(2026, 10, 5, 12),
        outcome: AttemptOutcome.win,
        fulfilled: true,
        opponent: OpponentKind.maia,
        opponentLevel: 1000,
        startFen: GameRules.initial.fen,
        moves: const ['e2e4', 'e7e5', 'g1f3'],
        userSide: Side.white,
      ),
    );
    final cubit = GameDetailsCubit(
      id,
      progress: progress,
      characters: FakeCharacterRepository(),
      analysis: engine ? analysis : null,
      reviews: reviews,
    );
    addTearDown(cubit.close);
    await cubit.load();
    return cubit;
  }

  Move uci(String move) => Move.parse(move)!;

  /// Deixa a engine de mentira terminar o que já foi pedido.
  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('um lance novo numa posição da partida abre a variante', () async {
    final cubit = await load();
    cubit.select(0);

    cubit.play(uci('c7c5'));

    final state = cubit.state;
    expect(state.inVariation, isTrue);
    expect(state.variationFrom, 0);
    expect(state.variation.map((m) => m.san), ['c5']);
    expect(state.variationPly, 0);
    expect(state.shownMove, uci('c7c5'));
    expect(state.shownPosition, state.variation.single.position);
    expect(state.shownBefore, state.moves.first.position);
    // A partida não muda.
    expect(state.moves.map((m) => m.san), ['e4', 'e5', 'Nf3']);
    expect(state.shownReview, isNull);
  });

  test('o lance seguinte da partida só anda nela', () async {
    final cubit = await load();
    cubit.select(0);

    cubit.play(uci('e7e5'));

    expect(cubit.state.inVariation, isFalse);
    expect(cubit.state.shownIndex, 1);
    expect(cubit.state.variation, isEmpty);
  });

  test('lance ilegal não muda nada', () async {
    final cubit = await load();
    cubit.select(0);
    final before = cubit.state;

    cubit.play(uci('e2e4'));
    cubit.play(uci('a7a3'));

    expect(cubit.state, same(before));
  });

  test('a variante continua, navega e volta para a partida', () async {
    final cubit = await load();
    cubit.select(0);
    cubit
      ..play(uci('c7c5'))
      ..play(uci('g1f3'))
      ..play(uci('d7d6'));
    expect(cubit.state.variation.map((m) => m.san), ['c5', 'Nf3', 'd6']);
    expect(cubit.state.atEnd, isTrue);

    cubit.previous();
    expect(cubit.state.variationPly, 1);
    cubit.selectVariation(0);
    cubit.previous();
    // Do primeiro lance dela, volta para a posição de onde ela sai.
    expect(cubit.state.inVariation, isFalse);
    expect(cubit.state.shownIndex, 0);

    cubit.selectVariation(2);
    expect(cubit.state.shownPosition, cubit.state.variation.last.position);
    // Tocar num lance da partida volta para ela (a variante fica na lista).
    cubit.select(2);
    expect(cubit.state.inVariation, isFalse);
    expect(cubit.state.shownIndex, 2);
    expect(cubit.state.variation, hasLength(3));

    cubit.selectVariation(1);
    cubit.last();
    expect(cubit.state.inVariation, isFalse);
    expect(cubit.state.shownIndex, 2);
    cubit.selectVariation(1);
    cubit.first();
    expect(cubit.state.inVariation, isFalse);
    expect(cubit.state.shownIndex, -1);
  });

  test('um lance no meio da variante corta o resto; numa posição da partida, '
      'troca a variante', () async {
    final cubit = await load();
    cubit.select(0);
    cubit
      ..play(uci('c7c5'))
      ..play(uci('g1f3'))
      ..play(uci('d7d6'));

    // O mesmo lance seguinte só anda.
    cubit.selectVariation(0);
    cubit.play(uci('g1f3'));
    expect(cubit.state.variation, hasLength(3));
    expect(cubit.state.variationPly, 1);

    cubit.selectVariation(0);
    cubit.play(uci('b1c3'));
    expect(cubit.state.variation.map((m) => m.san), ['c5', 'Nc3']);
    expect(cubit.state.variationPly, 1);

    cubit.select(1);
    cubit.play(uci('d2d4'));
    expect(cubit.state.variationFrom, 1);
    expect(cubit.state.variation.map((m) => m.san), ['d4']);
  });

  test('a engine acompanha a variante, sem mexer nas anotações nem na '
      'revisão guardada', () async {
    final cubit = await load(engine: true);
    await settle();
    await cubit.toggleEngine();
    cubit.select(0);
    await settle();
    final live = cubit.state.live;

    cubit.play(uci('c7c5'));
    await settle();

    final fen = cubit.state.variation.single.position.fen;
    expect(analysis.requests, contains(fen));
    expect(cubit.state.shownLines, isNotEmpty);
    expect(cubit.state.shownLines, cubit.state.variationLines[fen]);
    expect(cubit.state.shownDepth, GameDetailsCubit.engineDepth);
    expect(cubit.state.shownScore, isNotNull);
    expect(cubit.state.live.keys, live.keys);
    expect(cubit.state.review, isNull);
    expect(await reviews.load(1), isNull);
  });
}
