import 'dart:math';

import 'package:dartchess/dartchess.dart';

import '../../../domain/models/game_setup.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/pick_human_move.dart';
import '../../../domain/use_cases/think_time_policy.dart';
import '../../services/maia_service.dart';
import 'opponent_repository.dart';

/// O Maia jogando como uma pessoa do nível pedido: sorteia o lance entre os
/// que as pessoas daquele rating fazem e leva um tempo de gente para jogar
/// (lance óbvio sai quase na hora; lance difícil demora mais).
class MaiaOpponentRepository implements OpponentRepository {
  /// [wait] espera o tempo de pensar que sobra depois da conta do modelo (os
  /// cenários de ponta a ponta trocam a espera por um avanço do relógio).
  MaiaOpponentRepository(
    this._maia, {
    required this._now,
    Random? random,
    Future<void> Function(Duration)? wait,
  }) : _random = random ?? Random(),
       _wait = wait ?? Future<void>.delayed;

  final MaiaService _maia;
  final Now _now;
  final Random _random;
  final Future<void> Function(Duration) _wait;

  @override
  Future<Move?> pickMove(
    Position position, {
    required Duration thinkTime,
    OpponentKind kind = OpponentKind.maia,
    int? level,
    List<Position> history = const [],
  }) async {
    final started = _now();
    final elo = MaiaLevels.nearest(level ?? MaiaLevels.min);
    final evaluation = await _maia.evaluate(
      history.isEmpty ? [position] : history,
      selfElo: elo,
      oppoElo: elo,
    );
    final uci = PickHumanMove.pick(
      evaluation.policy,
      temperature: MaiaLevels.temperature,
      roll: _random.nextDouble(),
    );
    if (uci == null) return null;

    final think = ThinkTimePolicy.human(
      budget: thinkTime,
      certainty: evaluation.policy[uci] ?? 0,
      roll: _random.nextDouble(),
    );
    final left = think - _now().difference(started);
    if (left > Duration.zero) await _wait(left);

    final move = Move.parse(uci);
    // O lance vem do modelo; o app só joga lance legal.
    return move != null && position.isLegal(move) ? move : null;
  }
}
