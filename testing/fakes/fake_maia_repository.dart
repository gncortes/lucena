import 'package:dartchess/dartchess.dart';
import 'package:lucena/data/repositories/maia/maia_repository.dart';
import 'package:lucena/domain/models/move_prediction.dart';

/// Maia de mentira: devolve a previsão combinada para cada nível e guarda os
/// pedidos.
class FakeMaiaRepository implements MaiaRepository {
  FakeMaiaRepository({Map<int, MovePrediction>? byLevel})
    : byLevel = byLevel ?? {};

  /// A previsão de cada nível; nível sem previsão usa [fallback].
  final Map<int, MovePrediction> byLevel;

  static const fallback = MovePrediction(
    moves: {'a1a4': 0.6, 'a1d1': 0.4},
    win: 0.8,
    draw: 0.2,
    loss: 0,
    elapsed: Duration(milliseconds: 120),
  );

  /// Os pedidos recebidos: posição (FEN) e nível.
  final requests = <(String, int)>[];

  /// O próximo pedido falha, como um modelo que não carregou.
  bool failNext = false;

  /// O tempo de conta dos próximos pedidos, em ordem; acabando, vale o da
  /// previsão combinada.
  final elapsed = <Duration>[];

  @override
  Future<MovePrediction> predict(
    Position position, {
    required int level,
  }) async {
    requests.add((position.fen, level));
    if (failNext) {
      failNext = false;
      throw StateError('o modelo não respondeu');
    }
    final prediction = byLevel[level] ?? fallback;
    if (elapsed.isEmpty) return prediction;
    return MovePrediction(
      moves: prediction.moves,
      win: prediction.win,
      draw: prediction.draw,
      loss: prediction.loss,
      elapsed: elapsed.removeAt(0),
    );
  }

  /// Os pedidos de partida entre dois ratings: posição, quem joga e oponente.
  final matches = <(String, int, int)>[];

  @override
  Future<MovePrediction> predictMatch(
    Position position, {
    required int selfElo,
    required int oppoElo,
  }) async {
    matches.add((position.fen, selfElo, oppoElo));
    return byLevel[selfElo] ?? fallback;
  }
}
