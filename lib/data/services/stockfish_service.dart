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

  /// A avaliação de [fen] em [depth] lances, do ponto de vista de quem joga:
  /// centipeões ou mate em N (negativo: quem joga leva o mate). Nula se a
  /// posição já acabou.
  Future<({int? centipawns, int? mate})?> evaluate(
    String fen, {
    required int depth,
  }) {
    final result = _queue.then((_) => _evaluate(fen, depth));
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<({int? centipawns, int? mate})?> _evaluate(
    String fen,
    int depth,
  ) async {
    final engine = await _ready();
    ({int? centipawns, int? mate})? score;
    final done = Completer<void>();
    final listening = engine.stdout.listen((line) {
      final match = _score.firstMatch(line);
      if (match != null) {
        final value = int.parse(match.group(2)!);
        score = match.group(1) == 'mate'
            ? (centipawns: null, mate: value)
            : (centipawns: value, mate: null);
      }
      if (line.startsWith('bestmove') && !done.isCompleted) done.complete();
    });
    try {
      engine.stdin = 'position fen $fen';
      engine.stdin = 'go depth $depth';
      await done.future.timeout(const Duration(seconds: 10));
    } finally {
      await listening.cancel();
    }
    return score;
  }

  static final _score = RegExp(r' score (cp|mate) (-?\d+)');

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
