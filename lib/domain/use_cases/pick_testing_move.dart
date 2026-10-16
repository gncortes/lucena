import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import '../models/game_review.dart';

/// As melhores linhas do motor em [position], do ponto de vista das brancas
/// (como o `AnalysisRepository`), em [lines] linhas. Vazia se o motor não
/// respondeu.
typedef AnalyseLines = Future<List<EngineLine>> Function(
  Position position, {
  required int lines,
  required bool deep,
});

/// A escolha do adversário da prática quando o resultado é o empate: entre
/// os lances que mantêm a posição empatada, o que dá mais trabalho a um
/// humano, em vez de qualquer um (um rei indo e voltando não ensina a
/// defender).
///
/// Ordem: (1) o lance que deixa menos respostas do aluno que seguram o
/// empate (a armadilha); (2) o que leva o jogo adiante (peão que avança,
/// captura, xeque, rei ou peça que se aproxima das casas-chave); (3) a ordem
/// do motor. Determinístico. Se o adversário ganha, perde ou há mate, devolve
/// o melhor lance do motor, como sempre. Dart puro.
class PickTestingMove {
  const PickTestingMove(this._analyse);

  final AnalyseLines _analyse;

  /// Até esta nota (centipeões, de quem joga) a posição é empate.
  static const drawBand = 60;

  /// Quanto um lance pode valer menos que o melhor e ainda ser candidato.
  static const slack = 30;

  /// Quantos candidatos entram na conta das respostas do aluno.
  static const maxCandidates = 5;

  /// Quantas linhas do aluno o motor mostra por candidato.
  static const replyLines = 6;

  /// Só vale em finais: até esta quantidade de peças no tabuleiro.
  static const maxPieces = 10;

  /// O lance (UCI) da prática em [position]. Nulo se a posição tem peças
  /// demais para um final ou o motor não respondeu (quem chama joga o melhor
  /// lance de sempre). Fora do empate, é o melhor lance do motor.
  Future<String?> pick(Position position) async {
    if (position.board.occupied.size > maxPieces) return null;
    final root = await _analyse(position, lines: 8, deep: true);
    if (root.isEmpty || root.first.moves.isEmpty) return null;
    final best = _own(root.first.score, position.turn);
    if (best == null || best.abs() > drawBand) return root.first.moves.first;

    final candidates = <({String uci, int rank})>[];
    for (var i = 0; i < root.length; i++) {
      final line = root[i];
      final own = _own(line.score, position.turn);
      if (line.moves.isEmpty || own == null) continue;
      if (own.abs() > drawBand || best - own > slack) continue;
      candidates.add((uci: line.moves.first, rank: i));
      if (candidates.length == maxCandidates) break;
    }
    if (candidates.length < 2) return root.first.moves.first;

    final scored = <({String uci, int saved, int progress, int rank})>[];
    for (final candidate in candidates) {
      final move = Move.parse(candidate.uci);
      if (move == null || !position.isLegal(move)) continue;
      final next = position.play(move);
      final saved = await _savingReplies(next);
      if (saved == null) return root.first.moves.first;
      scored.add((
        uci: candidate.uci,
        saved: saved,
        progress: _progress(position, move),
        rank: candidate.rank,
      ));
    }
    if (scored.isEmpty) return root.first.moves.first;
    scored.sort((a, b) {
      final bySaved = a.saved.compareTo(b.saved);
      if (bySaved != 0) return bySaved;
      final byProgress = b.progress.compareTo(a.progress);
      return byProgress != 0 ? byProgress : a.rank.compareTo(b.rank);
    });
    return scored.first.uci;
  }

  /// Quantas respostas de quem joga em [position] seguram o empate; nulo se o
  /// motor não respondeu. Posição sem lance (mate ou afogamento): 0.
  Future<int?> _savingReplies(Position position) async {
    if (position.isGameOver) return 0;
    final lines = await _analyse(position, lines: replyLines, deep: false);
    if (lines.isEmpty) return null;
    var saved = 0;
    for (final line in lines) {
      final own = _own(line.score, position.turn);
      // O aluno segura o empate se a nota dele não cai da faixa do empate.
      if (own != null && own >= -drawBand) saved++;
    }
    return saved;
  }

  /// A nota de [score] para [side], em centipeões; nula se há mate.
  static int? _own(EngineScore score, Side side) {
    if (score.mate != null || score.mated != null) return null;
    final white = score.centipawns ?? 0;
    return side == Side.white ? white : -white;
  }

  /// Quanto [move] leva o jogo adiante, na ordem: promoção, captura, peão que
  /// avança, xeque e a aproximação do alvo (a casa à frente do peão mais
  /// avançado para o rei; o rei inimigo para as outras peças). Recuar dá
  /// nota negativa.
  static int _progress(Position position, Move move) {
    if (move is! NormalMove) return 0;
    final side = position.turn;
    final board = position.board;
    final piece = board.pieceAt(move.from);
    if (piece == null) return 0;
    var score = 0;
    if (move.promotion != null) score += 20;
    if (board.pieceAt(move.to) != null) score += 8;
    if (position.play(move).isCheck) score += 2;
    if (piece.role == Role.pawn) {
      final advance = side == Side.white
          ? move.to.rank.value
          : 7 - move.to.rank.value;
      return score + 6 + advance;
    }
    final target = _target(position, side, piece.role);
    if (target != null) {
      score += 2 * (_distance(move.from, target) - _distance(move.to, target));
    }
    return score;
  }

  static Square? _target(Position position, Side side, Role role) {
    final board = position.board;
    if (role == Role.king) {
      Square? front;
      var far = -1;
      for (final square in board.piecesOf(side, Role.pawn).squares) {
        final steps = side == Side.white
            ? square.rank.value
            : 7 - square.rank.value;
        final next = steps + 1;
        if (steps > far && next <= 7) {
          far = steps;
          front = Square.fromCoords(
            square.file,
            Rank.values[side == Side.white ? next : 7 - next],
          );
        }
      }
      if (front != null) return front;
    }
    return board.kingOf(side.opposite);
  }

  static int _distance(Square a, Square b) => math.max(
    (a.file.value - b.file.value).abs(),
    (a.rank.value - b.rank.value).abs(),
  );
}
