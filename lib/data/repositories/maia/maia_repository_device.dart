import 'package:dartchess/dartchess.dart';

import '../../../domain/models/move_prediction.dart';
import '../../services/maia_service.dart';
import 'maia_repository.dart';

/// O Maia que roda no aparelho.
class DeviceMaiaRepository implements MaiaRepository {
  DeviceMaiaRepository(this._maia);

  final MaiaService _maia;

  @override
  Future<MovePrediction> predict(
    Position position, {
    required int level,
  }) async {
    final evaluation = await _maia.evaluate(
      [position],
      selfElo: level,
      oppoElo: level,
    );
    return MovePrediction(
      moves: evaluation.policy,
      win: evaluation.win,
      draw: evaluation.draw,
      loss: evaluation.loss,
      elapsed: evaluation.elapsed,
    );
  }
}
