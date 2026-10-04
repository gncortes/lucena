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
    return byLevel[level] ?? fallback;
  }
}
