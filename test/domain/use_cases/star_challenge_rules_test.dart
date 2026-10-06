import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/domain/use_cases/star_challenge_rules.dart';

void main() {
  test('o começo: a peça e os peões do nível, com lance possível', () {
    for (final piece in ChallengePiece.values) {
      for (final level in ChallengeLevel.values) {
        final board = StarChallengeRules.start(piece, level, Random(1));
        final square = StarChallengeRules.pieceSquare(board)!;
        expect(board.pieceAt(square)!.role, piece.role);
        expect(board.bySide(Side.black).size, level.obstacles);
        expect(StarChallengeRules.movesOf(board, square), isNotEmpty);
        if (piece == ChallengePiece.pawn) expect(square.rank, Rank.second);
      }
    }
  });

  test('a peça anda nas casas vazias; o peão preto é parede', () {
    final board = Board.parseFen('8/8/8/8/8/8/8/R2p4');
    final moves = StarChallengeRules.movesOf(board, Square.a1);
    expect(moves, contains(Square.c1));
    expect(moves, isNot(contains(Square.d1)));
    expect(moves, isNot(contains(Square.e1)));
    expect(moves, contains(Square.a8));
  });

  test('o peão anda uma casa (duas da segunda fileira), sem capturar', () {
    final board = Board.parseFen('8/8/8/8/8/1p6/P7/8');
    expect(StarChallengeRules.movesOf(board, Square.a2), {
      Square.a3,
      Square.a4,
    });
    final blocked = Board.parseFen('8/8/8/8/8/p7/P7/8');
    expect(StarChallengeRules.movesOf(blocked, Square.a2), isEmpty);
  });

  test('a distância em lances e a próxima estrela no alcance do nível', () {
    final board = Board.parseFen('8/8/8/8/8/8/8/N7');
    final distances = StarChallengeRules.distancesFrom(board, Square.a1, 2);
    expect(distances[Square.b3], 1);
    expect(distances[Square.c2], 1);
    expect(distances[Square.a3], 2);
    expect(distances.containsKey(Square.a1), isFalse);
    final random = Random(3);
    for (var i = 0; i < 20; i++) {
      final star = StarChallengeRules.nextStar(
        board,
        Square.a1,
        ChallengeLevel.easy,
        random,
      )!;
      expect(distances[star], 1);
    }
    for (var i = 0; i < 20; i++) {
      final star = StarChallengeRules.nextStar(
        board,
        Square.a1,
        ChallengeLevel.hard,
        random,
      )!;
      expect(distances[star] ?? 3, greaterThanOrEqualTo(2));
    }
  });

  test('o peão no fim (ou preso) volta à segunda fileira', () {
    final done = Board.parseFen('P7/8/8/8/8/8/8/8');
    final back = StarChallengeRules.respawnIfStuck(done, Random(1));
    expect(StarChallengeRules.pieceSquare(back)!.rank, Rank.second);
    final rook = Board.parseFen('R7/8/8/8/8/8/8/8');
    expect(StarChallengeRules.respawnIfStuck(rook, Random(1)), rook);
  });

  test('a nota pelos pontos', () {
    // O nível vale tantas estrelas quanto a dificuldade.
    expect(ChallengeLevel.easy.stars, 1);
    expect(ChallengeLevel.medium.stars, 2);
    expect(ChallengeLevel.hard.stars, 3);
    expect(StarChallengeRules.earned(ChallengeLevel.easy, 0), 0);
    expect(StarChallengeRules.earned(ChallengeLevel.easy, 15), 1);
    expect(StarChallengeRules.earned(ChallengeLevel.easy, 40), 1);
    expect(StarChallengeRules.earned(ChallengeLevel.medium, 24), 2);
    expect(StarChallengeRules.earned(ChallengeLevel.hard, 18), 2);
    expect(StarChallengeRules.earned(ChallengeLevel.hard, 27), 3);
  });

  test('os tipos de estrela: valor, prazo por nível e sorteio', () {
    expect(StarKind.gold.points, 3);
    expect(StarKind.silver.points, 2);
    expect(StarKind.bronze.points, 1);
    expect(
      ChallengeLevel.easy.starLifetime(StarKind.bronze),
      const Duration(seconds: 6),
    );
    expect(
      ChallengeLevel.easy.starLifetime(StarKind.gold),
      const Duration(seconds: 3),
    );
    expect(
      ChallengeLevel.hard.starLifetime(StarKind.gold),
      lessThan(ChallengeLevel.easy.starLifetime(StarKind.gold)),
    );
    final random = Random(11);
    final kinds = {
      for (var i = 0; i < 200; i++) StarChallengeRules.pickKind(random),
    };
    expect(kinds, StarKind.values.toSet());
  });

  test('o progresso vai e volta do JSON', () {
    const progress = StarChallengeProgress();
    final saved = progress
        .withBest(ChallengePiece.rook, ChallengeLevel.easy, 12)
        .withBest(ChallengePiece.rook, ChallengeLevel.easy, 15);
    final back = StarChallengeProgress.fromJson(saved.toJson());
    expect(back.bestOf(ChallengePiece.rook, ChallengeLevel.easy), 15);
    expect(back.bestOf(ChallengePiece.king, ChallengeLevel.hard), isNull);
  });
}
