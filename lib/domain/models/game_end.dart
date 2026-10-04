import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_end.freezed.dart';

enum GameEndReason {
  checkmate,
  stalemate,
  insufficientMaterial,

  /// O tempo de um lado acabou e o outro vence.
  timeout,

  /// O tempo de um lado acabou, mas o outro não tem material para dar mate:
  /// empate.
  timeoutVsInsufficientMaterial,
}

/// Como a partida terminou. [winner] nulo é empate.
@freezed
abstract class GameEnd with _$GameEnd {
  const factory GameEnd(GameEndReason reason, {Side? winner}) = _GameEnd;
}
