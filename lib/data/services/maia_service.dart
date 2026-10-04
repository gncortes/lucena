import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';

import 'maia/maia_model.dart';
import 'maia/maia_weights.dart';

export 'maia/maia_model.dart' show MaiaEvaluation;

/// Embrulha o Maia-3 do aparelho: o modelo vem dentro do app e roda offline,
/// num isolate à parte para a tela não travar enquanto ele calcula.
///
/// O isolate é ligado no primeiro pedido e fica ligado, com o modelo
/// carregado. Os pedidos são atendidos um de cada vez, na ordem.
class MaiaService {
  /// [loadWeights] entrega o arquivo de pesos (`assets/models/maia3-5m.bin`).
  MaiaService(this._loadWeights);

  /// Onde o modelo fica dentro do app.
  static const weightsAsset = 'assets/models/maia3-5m.bin';

  final Future<Uint8List> Function() _loadWeights;

  Future<_Worker>? _worker;

  /// O que o Maia prevê para a última posição de [history] (da mais antiga
  /// para a atual). [selfElo] é o rating de quem joga e [oppoElo] o do
  /// oponente.
  Future<MaiaEvaluation> evaluate(
    List<Position> history, {
    required int selfElo,
    required int oppoElo,
  }) async {
    final starting = _worker ??= _Worker.start(_loadWeights);
    final _Worker worker;
    try {
      worker = await starting;
    } on Object {
      // Não ligou (arquivo ausente, por exemplo): o próximo pedido tenta de
      // novo.
      if (identical(_worker, starting)) _worker = null;
      rethrow;
    }
    try {
      return await worker.evaluate(
        [for (final position in _recent(history)) position.fen],
        selfElo,
        oppoElo,
      );
    } on _WorkerStopped {
      if (identical(_worker, starting)) _worker = null;
      rethrow;
    }
  }

  // O modelo só usa as últimas posições: as outras nem saem daqui.
  static List<Position> _recent(List<Position> history) =>
      history.length > _maxHistory
      ? history.sublist(history.length - _maxHistory)
      : history;

  static const _maxHistory = 8;

  Future<void> dispose() async {
    final worker = _worker;
    _worker = null;
    if (worker != null) (await worker).stop();
  }
}

/// O isolate em que o modelo roda, visto do lado do app.
class _Worker {
  _Worker._(this._isolate, this._requests, this._responses);

  static Future<_Worker> start(Future<Uint8List> Function() loadWeights) async {
    final weights = await loadWeights();
    final responses = ReceivePort();
    final isolate = await Isolate.spawn(_run, (
      responses.sendPort,
      TransferableTypedData.fromList([weights]),
    ), onExit: responses.sendPort);
    final ready = Completer<SendPort>();
    _Worker? worker;
    responses.listen((message) {
      if (message is SendPort) {
        ready.complete(message);
      } else if (message == null) {
        // O isolate terminou (parado ou com erro).
        if (ready.isCompleted) {
          worker?._stopped();
        } else {
          responses.close();
          ready.completeError(const _WorkerStopped());
        }
      } else {
        worker?._answered(message as _Response);
      }
    });
    final requests = await ready.future;
    return worker = _Worker._(isolate, requests, responses);
  }

  final Isolate _isolate;
  final SendPort _requests;
  final ReceivePort _responses;
  final _pending = <int, Completer<MaiaEvaluation>>{};
  int _nextId = 0;
  bool _alive = true;

  Future<MaiaEvaluation> evaluate(List<String> fens, int selfElo, int oppoElo) {
    if (!_alive) return Future.error(const _WorkerStopped());
    final id = _nextId++;
    final completer = _pending[id] = Completer<MaiaEvaluation>();
    _requests.send((id, fens, selfElo, oppoElo));
    return completer.future;
  }

  void stop() {
    _isolate.kill(priority: Isolate.immediate);
    _stopped();
  }

  void _answered(_Response response) {
    final (id, moves, probabilities, values, micros, error) = response;
    final completer = _pending.remove(id);
    if (completer == null) return;
    if (error != null) {
      completer.completeError(StateError(error));
      return;
    }
    completer.complete(
      MaiaEvaluation(
        policy: {
          for (var i = 0; i < moves.length; i++) moves[i]: probabilities[i],
        },
        win: values[0],
        draw: values[1],
        loss: values[2],
        ponder: values[3],
        elapsed: Duration(microseconds: micros),
      ),
    );
  }

  void _stopped() {
    if (!_alive) return;
    _alive = false;
    _responses.close();
    for (final completer in _pending.values) {
      completer.completeError(const _WorkerStopped());
    }
    _pending.clear();
  }

  // Dentro do isolate: carrega o modelo e responde aos pedidos.
  static void _run((SendPort, TransferableTypedData) start) {
    final (responses, weights) = start;
    final model = MaiaModel(
      MaiaWeights.parse(weights.materialize().asUint8List()),
    );
    final requests = ReceivePort();
    responses.send(requests.sendPort);
    requests.listen((message) {
      final (id, fens, selfElo, oppoElo) = message as _Request;
      try {
        final watch = Stopwatch()..start();
        final evaluation = model.evaluate(
          [for (final fen in fens) Chess.fromSetup(Setup.parseFen(fen))],
          selfElo: selfElo,
          oppoElo: oppoElo,
        );
        final _Response response = (
          id,
          evaluation.policy.keys.toList(),
          evaluation.policy.values.toList(),
          [evaluation.win, evaluation.draw, evaluation.loss, evaluation.ponder],
          watch.elapsedMicroseconds,
          null,
        );
        responses.send(response);
      } on Object catch (error) {
        final _Response response = (
          id,
          const [],
          const [],
          const [],
          0,
          '$error',
        );
        responses.send(response);
      }
    });
  }
}

/// Pedido: número, posições (FEN), rating de quem joga e do oponente.
typedef _Request = (int, List<String>, int, int);

/// Resposta: número do pedido, lances, probabilidades, [vitória, empate,
/// derrota, tempo], microssegundos da conta e o erro, se houve.
typedef _Response = (
  int,
  List<String>,
  List<double>,
  List<double>,
  int,
  String?,
);

class _WorkerStopped implements Exception {
  const _WorkerStopped();

  @override
  String toString() => 'The Maia isolate stopped';
}
