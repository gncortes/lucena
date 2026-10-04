import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'clock.dart';

part 'game_snapshot.freezed.dart';

/// A partida em andamento como é gravada no aparelho: o bastante para
/// continuar de onde parou depois de o app ser fechado.
@freezed
abstract class GameSnapshot with _$GameSnapshot {
  const factory GameSnapshot({
    /// A posição em que a partida começou (FEN).
    required String startFen,

    /// Os lances jogados, em UCI (`e2e4`, `a7a8n`).
    @Default(<String>[]) List<String> moves,

    /// O lado que aparece embaixo no tabuleiro.
    @Default(Side.white) Side orientation,

    /// O lado que o jogador move. Nulo: ele move os dois.
    Side? playerSide,

    /// O relógio, em instantes. Nulo: partida sem relógio.
    ClockState? clock,

    /// Se a tela da partida estava aberta quando isto foi gravado. Falso
    /// quando o jogador saiu da partida por conta própria.
    @Default(true) bool onScreen,
  }) = _GameSnapshot;
}
