import 'package:freezed_annotation/freezed_annotation.dart';

import 'game_setup.dart';

part 'attempt.freezed.dart';

/// Como a partida terminou para o jogador.
enum AttemptOutcome {
  win,
  draw,
  loss;

  String get code => name;

  static AttemptOutcome fromCode(String code) =>
      values.asNameMap()[code] ?? loss;
}

/// Uma partida jogada numa posição do catálogo.
@freezed
abstract class Attempt with _$Attempt {
  const factory Attempt({
    required String positionId,
    required DateTime playedAt,
    required AttemptOutcome outcome,

    /// O objetivo da posição foi cumprido.
    required bool fulfilled,
    required OpponentKind opponent,
  }) = _Attempt;
}
