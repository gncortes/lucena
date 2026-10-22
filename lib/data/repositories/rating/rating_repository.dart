import 'package:dartchess/dartchess.dart';

import '../../../domain/models/attempt.dart';
import '../../../domain/models/player_rating.dart';

/// O rating do jogador: separado da Jornada e do speedrun, muda a cada
/// partida contra o Maia ou o Stockfish.
abstract class RatingRepository {
  /// O rating atual. Sem partida que conte, o da faixa do perfil.
  Future<PlayerRating> current();

  /// O rating de antes da primeira partida: o da faixa do perfil.
  Future<PlayerRating> start();

  /// O rating no instante [at]: o da última linha até ele; antes de qualquer
  /// partida, o do início.
  Future<PlayerRating> at(DateTime at);

  /// O rating depois de cada partida que contou e de cada bônus de speedrun
  /// ([RatingEntry.isBonus]), da mais antiga para a mais recente.
  Future<List<RatingEntry>> history();

  /// Os bônus de speedrun já pagos, do mais antigo para o mais recente.
  Future<List<SpeedrunBonus>> speedrunBonuses();

  /// Soma [points] ao rating atual como o bônus da conclusão da tentativa
  /// [attemptId]. Nulo se ela já tinha o seu: o bônus é pago uma vez só.
  Future<SpeedrunBonus?> addSpeedrunBonus({
    required int attemptId,
    required int points,
  });

  /// O rating veio da conta (E1.13) e é maior que o daqui: vira o atual,
  /// sem partida nem bônus. Menor ou igual, nada muda.
  Future<void> restore(PlayerRating rating);

  /// Conta a partida [game], gravada com o id [gameId], em que o jogador
  /// jogou com [userSide]; [drawGoal]: o objetivo era empatar. Devolve o
  /// rating novo; nulo se ela não conta.
  Future<RatingEntry?> rate(
    Attempt game, {
    required Side userSide,
    required bool drawGoal,
    int? gameId,
  });
}
