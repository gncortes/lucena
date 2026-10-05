import 'package:dartchess/dartchess.dart';

import '../../../domain/models/game_setup.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/use_cases/draw_rules.dart';
import '../evaluation/evaluation_repository.dart';
import '../maia/maia_repository.dart';

/// A resposta da máquina a uma proposta de empate.
abstract class DrawOfferRepository {
  /// A máquina ([kind], no nível [level]), jogando com [machine], aceita o
  /// empate em [position]?
  Future<bool> accepts(
    Position position, {
    required Side machine,
    required OpponentKind kind,
    int? level,
  });
}

/// O Maia decide pela própria previsão de resultado (como alguém do nível
/// dele vê a posição); o Stockfish, pela avaliação dele.
class DeviceDrawOfferRepository implements DrawOfferRepository {
  DeviceDrawOfferRepository({required this._maia, required this._evaluation});

  final MaiaRepository _maia;
  final EvaluationRepository _evaluation;

  @override
  Future<bool> accepts(
    Position position, {
    required Side machine,
    required OpponentKind kind,
    int? level,
  }) async {
    if (kind == OpponentKind.stockfish) {
      final evaluation = await _evaluation.evaluate(position, pov: machine);
      return evaluation != null && DrawRules.engineAccepts(evaluation.score);
    }
    final elo = MaiaLevels.nearest(level ?? MaiaLevels.min);
    final prediction = await _maia.predictMatch(
      position,
      selfElo: elo,
      oppoElo: elo,
    );
    final machineMoves = position.turn == machine;
    return DrawRules.maiaAccepts(
      win: machineMoves ? prediction.win : prediction.loss,
      draw: prediction.draw,
    );
  }
}
