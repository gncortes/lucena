import 'package:dartchess/dartchess.dart' show Side;

import 'attempt.dart';
import 'game_review.dart';

/// Uma partida de fora do app (a do Treinador, jogada no Lichess ou no
/// Chess.com) aberta na mesma análise das partidas do app: a posição de
/// início, os lances e, se já veio analisada, a revisão e os comentários de
/// cada lance.
class ImportedGame {
  const ImportedGame({
    required this.startFen,
    required this.moves,
    required this.opponentName,
    this.userSide,
    this.outcome,
    this.playedAt,
    this.review,
    this.comments = const {},
    this.selected,
  });

  final String startFen;

  /// Os lances, em UCI.
  final List<String> moves;

  final String opponentName;
  final Side? userSide;
  final AttemptOutcome? outcome;
  final DateTime? playedAt;

  /// A revisão que veio pronta (um [ReviewedMove] por lance). Nula: a engine
  /// do aparelho anota os lances conforme o jogador passa por eles.
  final GameReview? review;

  /// O comentário do treinador por lance (índice em [moves]).
  final Map<int, String> comments;

  /// O lance aberto (índice em [moves]; -1: o início). Nulo: o início.
  final int? selected;
}
