import 'dart:math';

import 'package:dartchess/dartchess.dart';

import '../models/star_challenge.dart';
import 'lesson_rules.dart';

/// As regras do desafio das estrelas: a peça branca anda sozinha num
/// tabuleiro com peões pretos parados no caminho; a cada estrela pega, outra
/// aparece a um ou mais lances de distância.
abstract final class StarChallengeRules {
  static const side = Side.white;

  /// O tabuleiro do começo: a peça numa casa ao acaso (o peão na segunda
  /// fileira) e os peões do nível espalhados, sem prender a peça.
  static Board start(
    ChallengePiece piece,
    ChallengeLevel level,
    Random random,
  ) {
    for (var attempt = 0; attempt < 50; attempt++) {
      var board = Board.empty;
      final square = piece == ChallengePiece.pawn
          ? Square.fromCoords(File.values[random.nextInt(8)], Rank.second)
          : Square.values[random.nextInt(64)];
      board = board.setPieceAt(square, Piece(color: side, role: piece.role));
      var placed = 0;
      var tries = 0;
      while (placed < level.obstacles && tries++ < 100) {
        final candidate = Square.values[random.nextInt(64)];
        if (board.pieceAt(candidate) != null) continue;
        board = board.setPieceAt(candidate, Piece.blackPawn);
        placed++;
      }
      if (movesOf(board, square).isNotEmpty) return board;
    }
    // Sem peões, a peça sempre anda.
    return start(piece, ChallengeLevel.easy, random);
  }

  /// A casa da peça do aluno.
  static Square? pieceSquare(Board board) {
    final own = board.bySide(side);
    return own.isEmpty ? null : own.first;
  }

  /// Para onde a peça em [square] pode ir: as casas que ela ataca, vazias
  /// (os peões pretos são paredes); o peão anda para a frente, uma casa (ou
  /// duas, da segunda fileira).
  static Set<Square> movesOf(Board board, Square square) {
    final piece = board.pieceAt(square);
    if (piece == null) return const {};
    if (piece.role == Role.pawn) {
      final moves = <Square>{};
      final one = square.offset(8);
      if (one == null || board.pieceAt(one) != null) return moves;
      moves.add(one);
      if (square.rank == Rank.second) {
        final two = one.offset(8);
        if (two != null && board.pieceAt(two) == null) moves.add(two);
      }
      return moves;
    }
    final targets = LessonRules.starsMoves(board, side)[square] ?? const {};
    return {
      for (final to in targets)
        if (board.pieceAt(to) == null) to,
    };
  }

  /// Os lances válidos para o tabuleiro (a peça e seus destinos).
  static Map<Square, Set<Square>> validMoves(Board board) {
    final square = pieceSquare(board);
    if (square == null) return const {};
    return {square: movesOf(board, square)};
  }

  /// A próxima estrela: uma casa a entre [ChallengeLevel.minMoves] e
  /// [ChallengeLevel.maxMoves] lances da peça, ao acaso. Sem casa a essa
  /// distância, qualquer alcançável; sem nenhuma, nula.
  static Square? nextStar(
    Board board,
    Square from,
    ChallengeLevel level,
    Random random,
  ) {
    final distances = distancesFrom(board, from, level.maxMoves);
    final preferred = [
      for (final MapEntry(:key, :value) in distances.entries)
        if (value >= level.minMoves) key,
    ];
    final candidates = preferred.isNotEmpty
        ? preferred
        : distances.keys.toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.value.compareTo(b.value));
    return candidates[random.nextInt(candidates.length)];
  }

  /// A distância em lances, a partir de [from], de cada casa alcançável em
  /// até [limit] lances (sem a própria casa).
  static Map<Square, int> distancesFrom(Board board, Square from, int limit) {
    final piece = board.pieceAt(from);
    if (piece == null) return const {};
    final result = <Square, int>{};
    var frontier = [from];
    for (var depth = 1; depth <= limit && frontier.isNotEmpty; depth++) {
      final next = <Square>[];
      for (final square in frontier) {
        final moved = board.removePieceAt(from).setPieceAt(square, piece);
        for (final to in movesOf(moved, square)) {
          if (to == from || result.containsKey(to)) continue;
          result[to] = depth;
          next.add(to);
        }
      }
      frontier = next;
    }
    return result;
  }

  /// O tabuleiro depois de levar a peça de [from] a [to]. Nulo se ela não
  /// chega lá.
  static Board? move(Board board, Square from, Square to) {
    if (!movesOf(board, from).contains(to)) return null;
    final piece = board.pieceAt(from)!;
    return board.removePieceAt(from).setPieceAt(to, piece);
  }

  /// O peão que chegou ao fim (ou ficou preso) volta à segunda fileira, numa
  /// casa livre ao acaso; as outras peças ficam onde estão.
  static Board respawnIfStuck(Board board, Random random) {
    final square = pieceSquare(board);
    if (square == null) return board;
    final piece = board.pieceAt(square)!;
    if (movesOf(board, square).isNotEmpty) return board;
    if (piece.role != Role.pawn) return board;
    final free = [
      for (final file in File.values)
        if (board.pieceAt(Square.fromCoords(file, Rank.second)) == null &&
            board.pieceAt(Square.fromCoords(file, Rank.third)) == null)
          Square.fromCoords(file, Rank.second),
    ];
    if (free.isEmpty) return board;
    return board
        .removePieceAt(square)
        .setPieceAt(free[random.nextInt(free.length)], piece);
  }

  /// A nota (0 a 3 estrelas) pelas estrelas pegas no nível.
  static int earned(ChallengeLevel level, int collected) {
    var earned = 0;
    for (final threshold in level.thresholds) {
      if (collected >= threshold) earned++;
    }
    return earned;
  }

  /// O FEN do tabuleiro, com as brancas na vez.
  static String fen(Board board) => LessonRules.starsFen(board, side);
}
