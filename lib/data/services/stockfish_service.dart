import 'dart:async';

import 'package:multistockfish/multistockfish.dart';

/// Embrulha o Stockfish do aparelho (pacote `multistockfish`, versão "light":
/// a rede neural pequena vem dentro do app e o motor joga offline).
///
/// O motor é ligado no primeiro pedido e fica ligado. Os pedidos entram em
/// fila: um termina antes de o próximo começar; os urgentes (o que o jogador
/// está olhando) passam na frente dos outros que ainda não começaram, e os
/// interrompíveis (os longos) ficam entre os urgentes e os comuns. Um pedido
/// interrompível que está rodando para quando chega outro urgente ou
/// interrompível: quem pediu recebe [AnalysisStopped] e pode pedir de novo.
class StockfishService {
  StockfishService();

  Stockfish? _engine;
  final _waiting = <({int priority, Future<void> Function() run})>[];
  bool _running = false;

  /// O pedido rodando pode ser parado, e já foi.
  bool _preemptible = false;
  bool _stopped = false;

  /// Põe [job] na fila e devolve o resultado dele.
  Future<T> _enqueue<T>(
    Future<T> Function() job, {
    bool urgent = false,
    bool preemptible = false,
  }) {
    final done = Completer<T>();
    // 0: urgente; 1: interrompível; 2: comum.
    final priority = urgent && !preemptible ? 0 : (preemptible ? 1 : 2);
    final entry = (
      priority: priority,
      run: () async {
        _preemptible = preemptible;
        _stopped = false;
        try {
          done.complete(await job());
        } on Object catch (error, stack) {
          done.completeError(error, stack);
        } finally {
          _preemptible = false;
        }
      },
    );
    // Depois dos de prioridade igual ou maior, antes dos outros.
    final index = _waiting.indexWhere((waiting) => waiting.priority > priority);
    _waiting.insert(index < 0 ? _waiting.length : index, entry);
    if (_running && _preemptible && priority <= 1 && !_stopped) {
      _stopped = true;
      _engine?.stdin = 'stop';
    }
    unawaited(_drain());
    return done.future;
  }

  Future<void> _drain() async {
    if (_running) return;
    _running = true;
    try {
      while (_waiting.isNotEmpty) {
        await _waiting.removeAt(0).run();
      }
    } finally {
      _running = false;
    }
  }

  /// O melhor lance (UCI, `e2e4`) na posição [fen], pensando [moveTime]. Nulo
  /// se a posição não tem lance.
  Future<String?> bestMove(String fen, Duration moveTime) {
    return _enqueue(() => _bestMove(fen, moveTime));
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
    return _enqueue(() => _evaluate(fen, depth));
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

  /// As [lines] melhores linhas em [fen], até a profundidade [depth] (ou até
  /// [time], o que vier antes): para cada uma, a avaliação do ponto de vista
  /// de quem joga, os lances (UCI) e a profundidade alcançada. Lista vazia se
  /// a posição não tem lance. Se [preemptible], outro pedido pode parar este
  /// no meio ([AnalysisStopped]).
  Future<List<({int? centipawns, int? mate, List<String> moves, int depth})>>
  analyse(
    String fen, {
    required int depth,
    int lines = 1,
    bool urgent = false,
    Duration? time,
    bool preemptible = false,
  }) {
    return _enqueue(
      () => _analyse(fen, depth, lines, time),
      urgent: urgent,
      preemptible: preemptible,
    );
  }

  Future<List<({int? centipawns, int? mate, List<String> moves, int depth})>>
  _analyse(String fen, int depth, int lines, Duration? time) async {
    final engine = await _ready();
    final found =
        <int, ({int? centipawns, int? mate, List<String> moves, int depth})>{};
    final done = Completer<void>();
    final listening = engine.stdout.listen((line) {
      if (parseInfo(line) case (final index, final result)?) {
        found[index] = result;
      }
      if (line.startsWith('bestmove') && !done.isCompleted) done.complete();
    });
    try {
      engine.stdin = 'setoption name MultiPV value $lines';
      engine.stdin = 'position fen $fen';
      engine.stdin = time == null
          ? 'go depth $depth'
          : 'go depth $depth movetime ${time.inMilliseconds}';
      // Parado antes de começar a pensar.
      if (_stopped) engine.stdin = 'stop';
      await done.future.timeout(
        (time ?? Duration.zero) + const Duration(seconds: 30),
      );
    } finally {
      await listening.cancel();
      engine.stdin = 'setoption name MultiPV value 1';
    }
    if (_stopped) throw const AnalysisStopped();
    return [for (final index in found.keys.toList()..sort()) found[index]!];
  }

  /// Lê uma linha `info` com avaliação e lances: o número da linha
  /// (`multipv`, 1 se não vier) e a linha. Nula para as outras.
  static (int, ({int? centipawns, int? mate, List<String> moves, int depth}))?
  parseInfo(String line) {
    if (line.contains('lowerbound') || line.contains('upperbound')) return null;
    final info = _info.firstMatch(line);
    if (info == null) return null;
    final value = int.parse(info.group(3)!);
    return (
      int.parse(info.group(1) ?? '1'),
      (
        centipawns: info.group(2) == 'cp' ? value : null,
        mate: info.group(2) == 'mate' ? value : null,
        moves: info.group(4)!.trim().split(' '),
        depth: int.tryParse(_depth.firstMatch(line)?.group(1) ?? '') ?? 0,
      ),
    );
  }

  static final _depth = RegExp(r'^info depth (\d+)');

  // `info depth 14 ... multipv 2 score cp -35 ... pv e2e4 e7e5 ...`
  static final _info = RegExp(
    r'^info .*?(?:multipv (\d+) .*?)?score (cp|mate) (-?\d+).* pv ((?:\S+ ?)+)$',
  );

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

/// Uma análise interrompível parou no meio porque chegou um pedido mais
/// importante.
class AnalysisStopped implements Exception {
  const AnalysisStopped();
}
