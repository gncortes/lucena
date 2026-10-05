import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_end.freezed.dart';

enum GameEndReason {
  checkmate,
  stalemate,
  insufficientMaterial,

  /// A mesma posição apareceu três vezes: empate.
  repetition,

  /// Cinquenta lances de cada lado sem captura nem lance de peão: empate.
  fiftyMoves,

  /// O tempo de um lado acabou e o outro vence.
  timeout,

  /// O tempo de um lado acabou, mas o outro não tem material para dar mate:
  /// empate.
  timeoutVsInsufficientMaterial,

  /// O jogador desistiu.
  resign,
}

/// Como a partida terminou. [winner] nulo é empate.
@freezed
abstract class GameEnd with _$GameEnd {
  const factory GameEnd(GameEndReason reason, {Side? winner}) = _GameEnd;
}
