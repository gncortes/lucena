import 'dart:math';

import 'package:dartchess/dartchess.dart';

import '../../../domain/models/clock.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/models/pace.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/pick_human_move.dart';
import '../../../domain/use_cases/think_time_policy.dart';
import '../../services/maia_service.dart';
import '../pace/pace_repository.dart';
import 'opponent_repository.dart';

/// O Maia jogando como uma pessoa do nível pedido: sorteia o lance entre os
/// que as pessoas daquele rating fazem e leva um tempo de gente para jogar
/// (lance óbvio sai quase na hora; lance difícil demora mais). O jeito de
/// decidir muda com o ritmo da partida ([PaceRepository]).
class MaiaOpponentRepository implements OpponentRepository {
  /// [wait] espera o tempo de pensar que sobra depois da conta do modelo (os
  /// cenários de ponta a ponta trocam a espera por um avanço do relógio).
  MaiaOpponentRepository(
    this._maia, {
    required this._now,
    this._pace,
    Random? random,
    Future<void> Function(Duration)? wait,
  }) : _random = random ?? Random(),
       _wait = wait ?? Future<void>.delayed;

  final MaiaService _maia;
  final PaceRepository? _pace;
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
    TimeControl? time,
  }) async {
    final started = _now();
    // O ritmo muda como ele decide, não a força: no bullet fica nos lances
    // naturais (temperatura menor) e pensa menos.
    final profile =
        (await _pace?.table())?.profileFor(time) ?? PaceProfile.standard;
    final elo = MaiaLevels.nearest(level ?? MaiaLevels.min);
    final evaluation = await _maia.evaluate(
      history.isEmpty ? [position] : history,
      selfElo: elo,
      oppoElo: elo,
    );
    final uci = PickHumanMove.pick(
      evaluation.policy,
      temperature: profile.temperature,
      roll: _random.nextDouble(),
    );
    if (uci == null) return null;

    final think =
        ThinkTimePolicy.human(
          budget: thinkTime,
          certainty: evaluation.policy[uci] ?? 0,
          roll: _random.nextDouble(),
        ) *
        profile.thinkScale;
    final left = think - _now().difference(started);
    if (left > Duration.zero) await _wait(left);

    final move = Move.parse(uci);
    // O lance vem do modelo; o app só joga lance legal.
    return move != null && position.isLegal(move) ? move : null;
  }
}
