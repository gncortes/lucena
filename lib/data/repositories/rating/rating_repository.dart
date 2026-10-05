import 'package:dartchess/dartchess.dart';

import '../../../domain/models/attempt.dart';
import '../../../domain/models/player_rating.dart';

/// O rating do jogador: separado da Jornada e do speedrun, muda a cada
/// partida contra o Maia ou o Stockfish.
abstract class RatingRepository {
  /// O rating atual. Sem partida que conte, o da faixa do perfil.
  Future<PlayerRating> current();

  /// O rating depois de cada partida que contou, da mais antiga para a mais
  /// recente.
  Future<List<RatingEntry>> history();

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
