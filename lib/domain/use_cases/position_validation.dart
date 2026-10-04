import 'package:dartchess/dartchess.dart';

/// Por que uma posição não pode ser jogada.
enum PositionProblem {
  /// O texto não é um FEN.
  invalidFen,

  /// Não há peças no tabuleiro.
  empty,

  /// Falta o rei das brancas.
  missingWhiteKing,

  /// Falta o rei das pretas.
  missingBlackKing,

  /// Um lado tem mais de um rei.
  tooManyKings,

  /// O lado que não joga está em xeque.
  oppositeCheck,

  /// Xeque que nenhuma sequência de lances produz.
  impossibleCheck,

  /// Peão na primeira ou na última fileira.
  pawnsOnBackrank,

  /// A partida já acabou nessa posição (mate ou afogamento).
  alreadyOver,
}

/// Confere uma posição antes de jogar. As regras vêm do `dartchess`.
abstract final class PositionValidation {
  /// A posição descrita por [fen], ou o problema que impede jogá-la.
  static ({Position? position, PositionProblem? problem}) check(String fen) {
    final Setup setup;
    try {
      setup = Setup.parseFen(fen.trim());
    } on FenException {
      return (position: null, problem: PositionProblem.invalidFen);
    }
    final kings = setup.board.kings;
    final whiteKings = (kings & setup.board.white).size;
    final blackKings = (kings & setup.board.black).size;
    if (setup.board.occupied.isEmpty) {
      return (position: null, problem: PositionProblem.empty);
    }
    if (whiteKings > 1 || blackKings > 1) {
      return (position: null, problem: PositionProblem.tooManyKings);
    }
    if (whiteKings == 0) {
      return (position: null, problem: PositionProblem.missingWhiteKing);
    }
    if (blackKings == 0) {
      return (position: null, problem: PositionProblem.missingBlackKing);
    }
    final Position position;
    try {
      position = Chess.fromSetup(setup);
    } on PositionSetupException catch (error) {
      final problem = switch (error.cause) {
        IllegalSetupCause.oppositeCheck => PositionProblem.oppositeCheck,
        IllegalSetupCause.pawnsOnBackrank => PositionProblem.pawnsOnBackrank,
        IllegalSetupCause.empty => PositionProblem.empty,
        IllegalSetupCause.kings => PositionProblem.tooManyKings,
        IllegalSetupCause.impossibleCheck ||
        IllegalSetupCause.variant => PositionProblem.impossibleCheck,
      };
      return (position: null, problem: problem);
    }
    if (position.isGameOver) {
      return (position: null, problem: PositionProblem.alreadyOver);
    }
    return (position: position, problem: null);
  }
}
