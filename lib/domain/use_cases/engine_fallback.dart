import 'package:dartchess/dartchess.dart';

import 'position_assessment.dart';

/// O que o motor achou do lance do aluno fora dos dados da aula.
enum EngineVerdict {
  /// O resultado do objetivo se mantém: é outro lance correto.
  keeps,

  /// O resultado se perde: o motor jogou a melhor resposta ([EngineAnswer.reply]).
  loses,

  /// O motor travou, caiu ou deu exceção: o lance é desfeito (crit. 8e).
  failed,
}

class EngineAnswer {
  const EngineAnswer(this.verdict, [this.reply]);

  final EngineVerdict verdict;

  /// A resposta do motor, só em [EngineVerdict.loses].
  final Move? reply;
}

/// Lance fora dos dados: o Stockfish responde (T70, crit. 8; vale também para
/// o 9c e o 15). Dart puro: o motor entra por funções, que o view model liga
/// aos repositórios (`EvaluationRepository`, `OpponentRepository`).
class EngineFallback {
  const EngineFallback({required this.evaluate, required this.bestMove});

  /// A avaliação de [Position] do ponto de vista do lado dado.
  final Future<Evaluation?> Function(Position position, Side pov) evaluate;

  /// A melhor resposta do motor (tempo curto fixo, ex. 500 ms).
  final Future<Move?> Function(Position position) bestMove;

  /// Lição de vencer: a posição ainda é ganha a partir daqui (em centipeões).
  static const winThreshold = PositionAssessment.bigAdvantage ~/ 2;

  /// Lição de empatar: a posição ainda não está perdida (centipeões).
  static const holdThreshold = -PositionAssessment.better ~/ 2;

  /// O motor avalia [after] (a posição depois do lance do aluno [student]).
  /// [mustWin]: lição de vencer; senão, de segurar o empate. Com [replyOnKeep]
  /// (a demonstração, crit. "ponto 2c"), o motor também responde quando o
  /// resultado se mantém.
  Future<EngineAnswer> respond(
    Position after, {
    required Side student,
    required bool mustWin,
    bool replyOnKeep = false,
  }) async {
    try {
      final evaluation = await evaluate(after, student);
      if (evaluation == null) return const EngineAnswer(EngineVerdict.failed);
      final keeps = mustWin
          ? evaluation.score >= winThreshold
          : evaluation.score >= holdThreshold;
      if (keeps && !replyOnKeep) {
        return const EngineAnswer(EngineVerdict.keeps);
      }
      final reply = await bestMove(after);
      if (reply == null || !after.isLegal(reply)) {
        return const EngineAnswer(EngineVerdict.failed);
      }
      return EngineAnswer(
        keeps ? EngineVerdict.keeps : EngineVerdict.loses,
        reply,
      );
    } catch (_) {
      return const EngineAnswer(EngineVerdict.failed);
    }
  }
}
