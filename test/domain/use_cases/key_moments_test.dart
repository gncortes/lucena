import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/game_review.dart';
import 'package:lucena/domain/use_cases/key_moments.dart';

ReviewedMove move(MoveQuality quality, int beforeCp, int afterCp) =>
    ReviewedMove(
      before: EngineScore(centipawns: beforeCp),
      after: EngineScore(centipawns: afterCp),
      quality: quality,
      accuracy: 50,
    );

GameReview review(List<ReviewedMove> moves) =>
    GameReview(moves: moves, whiteAccuracy: 70, blackAccuracy: 60, depth: 2);

void main() {
  test('escolhe os 3 erros que mais custaram, de qualquer lado, em ordem de '
      'partida', () {
    final r = review([
      move(MoveQuality.best, 0, 0),
      move(MoveQuality.blunder, 0, 300), // preta: perdeu muito
      move(MoveQuality.mistake, 300, 0), // branca: perdeu bastante
      move(MoveQuality.good, 0, 0),
      move(MoveQuality.mistake, 100, -300), // branca
      move(MoveQuality.blunder, -300, 500), // preta
    ]);
    final moments = KeyMoments.pick(r, firstIsWhite: true);
    expect(moments.length, 3);
    expect([for (final m in moments) m.index], orderedEquals([1, 4, 5]));
    expect(moments.first.byWhite, isFalse);
    expect(moments.every((m) => m.loss >= KeyMoments.minLoss), isTrue);
  });

  test('imprecisão e erro que custou pouco não viram momento', () {
    final r = review([
      move(MoveQuality.inaccuracy, 0, -50),
      move(MoveQuality.mistake, 0, 10),
    ]);
    expect(KeyMoments.pick(r, firstIsWhite: true), isEmpty);
  });

  test('o custo é do ponto de vista de quem jogou (pretas se firstIsWhite '
      'é falso começa nas pretas)', () {
    // A avaliação sobe para as brancas: erro grave só se quem jogou foi preta.
    final r = review([move(MoveQuality.blunder, 0, 300)]);
    expect(KeyMoments.pick(r, firstIsWhite: true), isEmpty);
    expect(KeyMoments.pick(r, firstIsWhite: false).single.byWhite, isFalse);
  });

  test('sem erro do jogador: userMadeNoError; com erro, não', () {
    final r = review([
      move(MoveQuality.best, 0, 0),
      move(MoveQuality.blunder, 0, 300),
      move(MoveQuality.good, 300, 300),
    ]);
    expect(
      KeyMoments.userMadeNoError(r, firstIsWhite: true, userIsWhite: true),
      isTrue,
    );
    expect(
      KeyMoments.userMadeNoError(r, firstIsWhite: true, userIsWhite: false),
      isFalse,
    );
  });

  test('tabela de qualidades junta ótimo com melhor e perdido com erro', () {
    final r = review([
      move(MoveQuality.great, 0, 0),
      move(MoveQuality.forced, 0, 0),
      move(MoveQuality.best, 0, 0),
      move(MoveQuality.miss, 0, 0),
      move(MoveQuality.mistake, 0, 0),
      move(MoveQuality.blunder, 0, 0),
    ]);
    final table = KeyMoments.qualityTable(r, white: true, firstIsWhite: true);
    expect(table[MoveQuality.best], 2);
    expect(table[MoveQuality.mistake], 1);
    expect(table[MoveQuality.blunder], 0);
    final black = KeyMoments.qualityTable(r, white: false, firstIsWhite: true);
    expect(black[MoveQuality.best], 0);
    expect(black[MoveQuality.mistake], 1);
    expect(black[MoveQuality.blunder], 1);
  });
}
