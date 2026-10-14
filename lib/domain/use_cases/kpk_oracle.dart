import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';

import '../models/kpk_outcome.dart';
import 'game_rules.dart';

/// Diz o resultado de uma posição de rei e peão contra rei (T70). O lado do
/// peão ganha ou empata; quem chama sabe de que lado está.
abstract interface class KpkOracle {
  KpkOutcome evaluate(Position position);
}

extension KpkOracleFen on KpkOracle {
  /// Como [KpkOracle.evaluate], por FEN. FEN inválido: fora da tabela.
  KpkOutcome evaluateFen(String fen) {
    final position = GameRules.fromFen(fen);
    return position == null ? KpkOutcome.outside : evaluate(position);
  }
}

/// A tabela `assets/tablebase/kpk.bin`: 196 608 bytes, índice
/// (coluna 0–3, fileira 2–7, rei branco, rei preto, vez), 1 byte por posição
/// (DTM em meios-lances para vitória, 0 empate, 255 ilegal). O peão fica
/// sempre branco e nas colunas a–d: as outras posições são espelhadas.
class KpkTableOracle implements KpkOracle {
  KpkTableOracle(this._bytes) {
    if (_bytes.length != size) {
      throw ArgumentError('kpk.bin deve ter $size bytes, tem ${_bytes.length}');
    }
  }

  static const size = 4 * 6 * 64 * 64 * 2;

  final Uint8List _bytes;

  /// O índice da posição já normalizada (peão branco em a–d).
  static int index({
    required int column,
    required int pawnRank,
    required int whiteKing,
    required int blackKing,
    required int turn,
  }) =>
      ((((column * 6 + (pawnRank - 1)) * 64 + whiteKing) * 64 + blackKing) *
          2) +
      turn;

  @override
  KpkOutcome evaluate(Position position) {
    final board = position.board;
    final occupied = board.occupied;
    final pawns = board.pawns;
    final whiteKing = board.kingOf(Side.white);
    final blackKing = board.kingOf(Side.black);
    if (whiteKing == null || blackKing == null) return KpkOutcome.outside;
    if (pawns.isEmpty) {
      if (occupied.size == 2) return KpkOutcome.draw;
      if (occupied.size == 3 && board.queens.size == 1) {
        return _promoted(position, board.queens.first!);
      }
      return KpkOutcome.outside;
    }
    if (pawns.size != 1 || occupied.size != 3) return KpkOutcome.outside;

    var pawn = pawns.first!.value;
    var white = whiteKing.value;
    var black = blackKing.value;
    var turn = position.turn == Side.white ? 0 : 1;
    if (board.sideAt(pawns.first!) == Side.black) {
      // Espelho vertical e cores trocadas.
      pawn ^= 56;
      final flippedWhite = black ^ 56;
      black = white ^ 56;
      white = flippedWhite;
      turn ^= 1;
    }
    if ((pawn & 7) >= 4) {
      pawn ^= 7;
      white ^= 7;
      black ^= 7;
    }
    final rank = pawn >> 3;
    if (rank < 1 || rank > 6) return KpkOutcome.outside;
    final byte =
        _bytes[index(
          column: pawn & 7,
          pawnRank: rank,
          whiteKing: white,
          blackKing: black,
          turn: turn,
        )];
    if (byte == 255) return KpkOutcome.outside;
    return byte == 0 ? KpkOutcome.draw : KpkOutcome.win(byte);
  }

  /// O peão coroou numa dama: ganha, a não ser que o rei sem dama possa
  /// capturá-la agora ou fique afogado.
  KpkOutcome _promoted(Position position, Square queen) {
    if (position.isStalemate) return KpkOutcome.draw;
    final queenSide = position.board.sideAt(queen);
    if (queenSide != position.turn) {
      for (final MapEntry(:value) in position.legalMoves.entries) {
        if (value.has(queen)) return KpkOutcome.draw;
      }
    }
    return const KpkOutcome.win(0);
  }
}
