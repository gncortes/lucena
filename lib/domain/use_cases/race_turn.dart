import 'package:dartchess/dartchess.dart';

import '../models/race.dart';

/// O que um lance do jogador foi, comparado com a sequência mais rápida.
enum RaceMoveKind {
  /// Mantém a distância ótima até o objetivo: vale.
  optimal,

  /// Ainda ganha, mas leva mais lances: conta como erro.
  slower,

  /// Empata ou perde.
  wrong,
}

/// A vez do jogador dentro de um problema em sequência: a posição, o nó da
/// árvore com os lances ótimos e o que vem depois de cada um.
class RaceTurn {
  const RaceTurn({
    required this.problem,
    required this.node,
    required this.fen,
    this.step = 0,
  });

  factory RaceTurn.start(RaceProblem problem) =>
      RaceTurn(problem: problem, node: problem.tree, fen: problem.fen);

  final RaceProblem problem;
  final RaceNode node;
  final String fen;

  /// Quantos lances o jogador já fez no problema.
  final int step;

  RaceMoveKind judge(String move) =>
      node.moves.containsKey(move) || node.alternatives.contains(move)
      ? RaceMoveKind.optimal
      : node.slower.contains(move)
      ? RaceMoveKind.slower
      : RaceMoveKind.wrong;

  /// A posição depois de [move] (a defesa ainda não respondeu).
  String fenAfter(String move) => _play(fen, move);

  /// A resposta da defesa a [move] (ótimo). Nula se o lance encerra o problema.
  String? replyTo(String move) => node.moves[move]?.reply;

  /// Se [move] (ótimo) fecha o problema: mate ou fim da linha.
  bool ends(String move) =>
      node.alternatives.contains(move) || (node.moves[move]?.isEnd ?? false);

  /// A vez seguinte, depois de [move] e da resposta da defesa. Nula se o lance
  /// encerra o problema.
  RaceTurn? after(String move) {
    final branch = node.moves[move];
    final next = branch?.next;
    final reply = branch?.reply;
    if (next == null || reply == null) return null;
    return RaceTurn(
      problem: problem,
      node: next,
      fen: _play(_play(fen, move), reply),
      step: step + 1,
    );
  }

  /// O erro de [move] nesta posição, com o que era o mais rápido.
  RaceAnswer mistake(String move) => RaceAnswer(
    problemId: problem.id,
    level: problem.level,
    theme: problem.theme,
    move: move,
    correct: false,
    fen: fen,
    best: node.best,
    distance: node.distance,
    slower: judge(move) == RaceMoveKind.slower,
  );

  /// O acerto do problema (o último lance da sequência).
  RaceAnswer solved(String move) => RaceAnswer(
    problemId: problem.id,
    level: problem.level,
    theme: problem.theme,
    move: move,
    correct: true,
  );

  static String _play(String fen, String uci) {
    final position = Chess.fromSetup(Setup.parseFen(fen));
    return position.play(Move.parse(uci)!).fen;
  }
}
