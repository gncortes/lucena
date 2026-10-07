import 'package:freezed_annotation/freezed_annotation.dart';

import 'clock.dart';

part 'game_setup.freezed.dart';

/// Contra quem o jogador joga.
enum OpponentKind {
  /// O Maia joga o outro lado como uma pessoa do nível escolhido.
  maia,

  /// O Stockfish, na força máxima, joga o outro lado.
  stockfish,

  /// O próprio jogador move os dois lados (o tabuleiro livre).
  twoPlayers;

  static const fallback = OpponentKind.maia;

  /// Os adversários que o treino oferece. Treinar um final é jogar contra
  /// alguém: "dois jogadores" fica só no tabuleiro livre.
  static const training = [OpponentKind.maia, OpponentKind.stockfish];

  /// A máquina joga o outro lado.
  bool get isMachine => this != twoPlayers;

  /// Valor gravado nas preferências.
  String get code => name;

  static OpponentKind fromCode(String? code) =>
      values.asNameMap()[code] ?? fallback;

  /// O adversário gravado na configuração do treino. Um valor que o treino
  /// não oferece mais ("dois jogadores", de versões antigas) vira o padrão.
  static OpponentKind trainingFromCode(String? code) {
    final kind = fromCode(code);
    return training.contains(kind) ? kind : fallback;
  }
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

    /// O nível do Maia. Nulo: o sugerido pelo rating do perfil.
    int? maiaLevel,

    /// Às cegas: os lances falados, digitados ou tocados, sem ver as peças.
    @Default(false) bool blind,
  }) = _GameSetup;

  static const defaultTime = TimeControl(initial: Duration(minutes: 5));
}
