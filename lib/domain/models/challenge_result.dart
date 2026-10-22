import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'attempt.dart';
import 'challenge_link.dart';

part 'challenge_result.freezed.dart';

/// Como foi o desafio que veio de um link, para mandar de volta: o que
/// aparece na imagem e no texto de "Compartilhar".
@freezed
abstract class ChallengeResult with _$ChallengeResult {
  const factory ChallengeResult({
    /// O desafio jogado: o link que a imagem leva.
    required ChallengeLink link,
    required AttemptOutcome outcome,

    /// Quantos lances o jogador fez.
    required int moves,

    /// Quanto sobrou no relógio dele. Nulo: partida sem relógio.
    Duration? remaining,

    /// A peça que deu o mate. Nulo: o jogador não deu mate.
    Role? matingPiece,

    /// A posição final, para o tabuleiro pequeno da imagem.
    required String finalFen,

    /// O último lance da partida, em destaque na miniatura.
    Move? lastMove,
  }) = _ChallengeResult;

  const ChallengeResult._();

  /// O jogador venceu.
  bool get won => outcome == AttemptOutcome.win;

  /// Quantos lances o jogador fez, dados [plies] meios-lances jogados e se
  /// ele joga primeiro na posição.
  static int movesOf({required int plies, required bool userFirst}) =>
      userFirst ? (plies + 1) ~/ 2 : plies ~/ 2;

  /// O relógio como aparece no texto: `4:52`.
  static String clockText(Duration time) {
    final seconds = time.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
