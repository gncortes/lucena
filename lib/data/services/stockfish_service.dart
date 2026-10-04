import 'dart:async';

import 'package:multistockfish/multistockfish.dart';

/// Embrulha o Stockfish do aparelho (pacote `multistockfish`, versão "light":
/// a rede neural pequena vem dentro do app e o motor joga offline).
///
/// O motor é ligado no primeiro pedido e fica ligado. Os pedidos entram em
/// fila: um termina antes de o próximo começar.
class StockfishService {
  StockfishService();

  Stockfish? _engine;
  Future<void> _queue = Future.value();

  /// O melhor lance (UCI, `e2e4`) na posição [fen], pensando [moveTime]. Nulo
  /// se a posição não tem lance.
  Future<String?> bestMove(String fen, Duration moveTime) {
    final result = _queue.then((_) => _bestMove(fen, moveTime));
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<String?> _bestMove(String fen, Duration moveTime) async {
    final engine = await _ready();
    final answer = engine.stdout
        .firstWhere((line) => line.startsWith('bestmove'))
        .timeout(moveTime + const Duration(seconds: 10));
    engine.stdin = 'position fen $fen';
    engine.stdin = 'go movetime ${moveTime.inMilliseconds.clamp(1, 60000)}';
    final move = (await answer).split(' ')[1];
    return move == '(none)' ? null : move;
  }

  Future<Stockfish> _ready() async {
    final engine = _engine;
    if (engine != null && engine.state.value == StockfishState.ready) {
      return engine;
    }
    // Motor parado com erro: libera a vaga e liga outro.
    if (engine != null) {
      await engine.dispose();
      _engine = null;
    }
    final started = await Stockfish.create(flavor: StockfishFlavor.light);
    started.stdin = 'setoption name Threads value 1';
    return _engine = started;
  }

  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
  }
}
