import 'package:freezed_annotation/freezed_annotation.dart';

import 'clock.dart';

part 'game_setup.freezed.dart';

/// Contra quem o jogador joga.
enum OpponentKind {
  /// O Stockfish, na força máxima, joga o outro lado.
  stockfish,

  /// O próprio jogador move os dois lados.
  twoPlayers;

  static const fallback = OpponentKind.stockfish;

  /// A máquina joga o outro lado.
  bool get isMachine => this != twoPlayers;

  /// Valor gravado nas preferências.
  String get code => name;

  static OpponentKind fromCode(String? code) =>
      values.asNameMap()[code] ?? fallback;
}

/// A configuração de uma partida de treino. A última usada fica gravada e
/// volta na próxima.
@freezed
abstract class GameSetup with _$GameSetup {
  const factory GameSetup({
    @Default(true) bool clock,

    /// O tempo do jogador.
    @Default(GameSetup.defaultTime) TimeControl userTime,

    /// O tempo do adversário (a máquina, quando houver).
    @Default(GameSetup.defaultTime) TimeControl opponentTime,
    @Default(OpponentKind.fallback) OpponentKind opponent,
  }) = _GameSetup;

  static const defaultTime = TimeControl(initial: Duration(minutes: 5));
}
