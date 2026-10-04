import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:lucena/data/repositories/opponent/opponent_repository.dart';
import 'package:lucena/domain/models/game_setup.dart';

import 'fake_now.dart';

/// Adversário previsível: dá mate quando há mate em um lance; se não, joga o
/// primeiro lance legal em ordem alfabética (UCI). Com [now], o relógio anda o
/// tempo que a máquina pensou.
///
/// [hold] segura as respostas até [release]: é a máquina "pensando" pelo tempo
/// que o teste quiser.
class FakeOpponentRepository implements OpponentRepository {
  FakeOpponentRepository({this.now});

  final FakeNow? now;

  /// Os pedidos recebidos, em ordem (FEN).
  final requests = <String>[];

  /// O tempo de pensar de cada pedido.
  final thinkTimes = <Duration>[];

  /// Quem foi chamado em cada pedido, com o nível (o do Maia) e quantas
  /// posições da partida vieram junto.
  final kinds = <OpponentKind>[];
  final levels = <int?>[];
  final histories = <List<Position>>[];

  Completer<void>? _gate;

  /// O próximo pedido falha, como um motor que travou.
  bool failNext = false;

  void hold() => _gate ??= Completer<void>();

  void release() {
    _gate?.complete();
    _gate = null;
  }

  @override
  Future<Move?> pickMove(
    Position position, {
    required Duration thinkTime,
    OpponentKind kind = OpponentKind.stockfish,
    int? level,
    List<Position> history = const [],
  }) async {
    requests.add(position.fen);
    thinkTimes.add(thinkTime);
    kinds.add(kind);
    levels.add(level);
    histories.add(history);
    final gate = _gate;
    if (gate != null) await gate.future;
    if (failNext) {
      failNext = false;
      throw StateError('o motor não respondeu');
    }
    now?.advance(thinkTime);
    return bestOf(position);
  }

  static Move? bestOf(Position position) {
    final moves = [
      for (final MapEntry(key: from, value: targets)
          in position.legalMoves.entries)
        for (final to in targets.squares) NormalMove(from: from, to: to),
    ];
    if (moves.isEmpty) return null;
    // Peão que chega na última fileira vira dama.
    Move complete(NormalMove move) {
      final isPawn = position.board.roleAt(move.from) == Role.pawn;
      return isPawn && SquareSet.backranks.has(move.to)
          ? move.withPromotion(Role.queen)
          : move;
    }

    final all = moves.map(complete).toList()
      ..sort((a, b) => a.uci.compareTo(b.uci));
    for (final move in all) {
      if (position.play(move).isCheckmate) return move;
    }
    return all.first;
  }
}
