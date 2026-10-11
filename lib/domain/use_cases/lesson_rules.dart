import 'package:dartchess/dartchess.dart';

import '../models/lesson.dart';
import 'game_rules.dart';

/// Como terminou a posição de um [PlayStep].
enum PlayResult {
  /// Continua.
  ongoing,

  /// O objetivo foi cumprido.
  success,

  /// O rei sem lances e sem xeque: empate por afogamento.
  stalemate,

  /// Outro empate (material insuficiente, repetição, 50 lances).
  draw,

  /// O aluno levou mate.
  lost,
}

/// As regras dos passos das aulas, em cima do `dartchess`.
abstract final class LessonRules {
  /// O enunciado do passo de pensar como abertura da explicação: o
  /// contexto fica, saem as frases de pergunta e a que diz quem joga (o
  /// aluno já viu os dois). Vazio se não sobra nada.
  static String thinkContext(String text) => [
    for (final match in _sentence.allMatches(text))
      if (match.group(0)!.trim() case final sentence
          when sentence.isNotEmpty &&
              !_question.hasMatch(sentence) &&
              !saysWhoMoves(sentence))
        sentence,
  ].join(' ');

  static final _sentence = RegExp(r'.+?(?:[.!?](?=\s|$)|$)\s*', dotAll: true);
  static final _question = RegExp(r'\?\s*$');

  /// A fala já diz quem joga ("Brancas jogam", "Você joga de pretas",
  /// "White to move"...): o enunciado do passo de pensar não repete (T60).
  /// As falas das aulas são em português e inglês.
  static bool saysWhoMoves(String text) => _whoMoves.hasMatch(text);

  static final _whoMoves = RegExp(
    r'(brancas|pretas)\s+jog|jog\w*\s+(as|com as|de|das)\s+(brancas|pretas)|'
    r'vez\s+das\s+(brancas|pretas)|'
    r'(white|black)\s+(to\s+(move|play)|plays|moves|is to move)|'
    r"play(s|ing)?\s+(as\s+|with\s+)?(white|black)|(white|black)'s\s+(move|turn)",
    caseSensitive: false,
  );

  /// O tabuleiro das estrelas: só as peças do aluno, sem reis do outro lado
  /// e sem peão (o peão se aprende com o rei em jogo, num [MoveStep]).
  static Board starsBoard(String fen) => Board.parseFen(fen.split(' ').first);

  /// Os destinos de cada peça do lado [side] no tabuleiro das estrelas: os
  /// ataques dela (sem pular por cima de peça, sem cair numa peça amiga).
  static Map<Square, Set<Square>> starsMoves(Board board, Side side) {
    final own = board.bySide(side);
    return {
      for (final square in own.squares)
        if (board.pieceAt(square) case final piece?
            when piece.role != Role.pawn)
          square: attacks(
            piece,
            square,
            board.occupied,
          ).diff(own).squares.toSet(),
    };
  }

  /// O tabuleiro depois de levar a peça de [from] para [to]. Nulo se ela não
  /// chega lá.
  static Board? moveStar(Board board, Side side, Square from, Square to) {
    if (!(starsMoves(board, side)[from]?.contains(to) ?? false)) return null;
    final piece = board.pieceAt(from)!;
    return board.removePieceAt(from).setPieceAt(to, piece);
  }

  /// O FEN completo do tabuleiro das estrelas, com [side] na vez.
  static String starsFen(Board board, Side side) =>
      '${board.fen} ${side == Side.white ? 'w' : 'b'} - - 0 1';

  /// O lance [uci] é um dos aceitos na vez [turn] de [step].
  static bool accepts(MoveStep step, int turn, String uci) {
    if (turn < 0 || turn >= step.line.length) return false;
    return step.line[turn].accept.contains(uci);
  }

  /// O lance aceito [uci] na vez [turn] encerra a linha de [step]: é a última
  /// vez, ou é outro lance aceito que não o ensinado (o primeiro). A resposta
  /// combinada e as vezes seguintes valem só para o lance ensinado; depois de
  /// outro lance bom, a linha acaba ali, cumprida.
  static bool endsLine(MoveStep step, int turn, String uci) =>
      turn + 1 >= step.line.length || step.line[turn].accept.first != uci;

  /// Quantos lances o aluno precisa segurar para o empate contar, num passo
  /// de jogar com objetivo de empatar.
  static const holdMoves = 20;

  /// O resultado de [position] num [PlayStep] de objetivo [goal], com o aluno
  /// jogando de [student]. [lastMove] é o último lance jogado (a promoção
  /// conta no lance em que acontece).
  static PlayResult resultOf(
    Position position, {
    required PlayGoal goal,
    required Side student,
    Move? lastMove,
    int repetitions = 1,
    int studentMoves = 0,
  }) {
    final end = GameRules.endOf(position, repetitions: repetitions);
    if (position.isCheckmate) {
      return position.turn == student ? PlayResult.lost : PlayResult.success;
    }
    if (goal == PlayGoal.draw) {
      // Empatar: qualquer fim empatado vale, e também quando os peões saem
      // do tabuleiro (só peças, o empate da teoria) ou o aluno segura
      // [holdMoves] lances sem perder.
      final pawnless = position.board.pawns.isEmpty;
      return end != null ||
              position.isStalemate ||
              pawnless ||
              studentMoves >= holdMoves
          ? PlayResult.success
          : PlayResult.ongoing;
    }
    if (position.isStalemate) return PlayResult.stalemate;
    if (end != null) return PlayResult.draw;
    if (goal == PlayGoal.promote &&
        position.turn != student &&
        lastMove is NormalMove &&
        lastMove.promotion != null) {
      return PlayResult.success;
    }
    return PlayResult.ongoing;
  }
}
