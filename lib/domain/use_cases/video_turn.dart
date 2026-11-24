import '../models/lesson_video.dart';

/// Como terminou o lance do aluno na pergunta.
enum TurnResult {
  /// Lance da lista `certos`: ✓ e o vídeo segue da pergunta.
  right,

  /// Alternativa boa: fala curta própria e volta à linha principal depois
  /// das falas que são só do lance certo (Vídeo 29).
  alternative,

  /// Erro conhecido: ✗ na casa, a peça volta, dica falada; espera de novo.
  wrong,

  /// Peça fora de `pecas` ou lance fora da lista: ramo `fora`; espera de novo.
  outside,

  /// "Ver a resposta": toca o ramo da resposta e segue.
  revealed,
}

/// O que a tela faz com o lance: o resultado, o ramo a tocar (nulo = nenhum)
/// e a casa do ✗ (destino do lance errado).
class TurnOutcome {
  const TurnOutcome(this.result, {this.branch, this.wrongSquare});

  final TurnResult result;

  /// O ramo a tocar antes de seguir ou de voltar a esperar.
  final String? branch;

  /// A casa em que aparece o ✗ (erro ou lance fora).
  final String? wrongSquare;

  /// Depois do ramo o vídeo segue (certo, alternativa, resposta); senão
  /// volta a esperar o lance na mesma pergunta.
  bool get resumes =>
      result == TurnResult.right ||
      result == TurnResult.alternative ||
      result == TurnResult.revealed;

  /// Segue a partir das falas depois das do lance certo (alternativa boa).
  bool get skipsRightLines => result == TurnResult.alternative;
}

/// A vez do aluno numa pergunta do vídeo (L2; gaps Vídeo 25–30). Puro: o
/// view model cria um por pergunta, julga cada lance e toca o ramo.
class VideoTurn {
  VideoTurn(this.gate);

  final VideoGate gate;

  /// "Ver a resposta" aparece a partir deste erro (decisão 5a).
  static const revealAfterErrors = 2;

  int _errors = 0;

  /// Quantos lances errados (erro ou fora) nesta pergunta.
  int get errors => _errors;

  /// A pílula "Ver a resposta" aparece.
  bool get canReveal => gate.reveal != null && _errors >= revealAfterErrors;

  /// As casas das peças que o aluno pode mover.
  List<String> get movable => gate.pieces;

  /// Julga o lance [uci] (ex.: `e2e4`, `e7e8q`).
  TurnOutcome judge(String uci) {
    if (gate.right.contains(uci)) return const TurnOutcome(TurnResult.right);
    final to = uci.length >= 4 ? uci.substring(2, 4) : null;
    final from = uci.length >= 2 ? uci.substring(0, 2) : null;
    final known = gate.exits[uci];
    if (known != null && known.after == GateAfter.resume) {
      return TurnOutcome(TurnResult.alternative, branch: _orNull(known.branch));
    }
    _errors++;
    if (known != null) {
      return TurnOutcome(
        TurnResult.wrong,
        branch: _orNull(known.branch),
        wrongSquare: to,
      );
    }
    final pieceOk = from != null && gate.pieces.contains(from);
    return TurnOutcome(
      TurnResult.outside,
      branch: gate.outside,
      wrongSquare: pieceOk ? to : from,
    );
  }

  /// "Ver a resposta"; nulo se a pílula ainda não aparece.
  TurnOutcome? reveal() {
    if (!canReveal) return null;
    return TurnOutcome(TurnResult.revealed, branch: gate.reveal);
  }

  static String? _orNull(String branch) => branch.isEmpty ? null : branch;
}
