import 'package:dartchess/dartchess.dart';

import '../../models/attempt.dart';
import '../../models/game_review.dart';
import '../../models/imported_game.dart';
import '../../models/coach/coach.dart';
import '../game_rules.dart';
import '../review_rules.dart';
import 'game_moves.dart';

/// A partida do Treinador na forma da análise de partida do app: os lances do
/// PGN e a revisão feita com as avaliações do servidor, na qualidade de lance
/// do app. A classe do servidor manda (é a mesma dos exercícios): grave é
/// erro grave, erro é erro, imprecisão é imprecisão; um lance "ok" nunca
/// aparece como falha.
abstract final class CoachGameReview {
  /// [chessMove] é o meio-lance aberto (1 = o primeiro lance das brancas; 0 = o
  /// início). [weight] é o peso das anotações do servidor: com o maior da
  /// engine do aparelho, ela não troca a classe dele.
  static ImportedGame of(CoachGame game, {int? chessMove, int weight = 0}) {
    final moves = GameMoves.of(game.pgn);
    final startFen = GameMoves.start(game.pgn);
    final comments = <int, String>{
      for (final (i, l) in game.moves.indexed)
        if (i < moves.length && (l.comment ?? '').trim().isNotEmpty)
          i: l.comment!.trim(),
    };
    return ImportedGame(
      startFen: startFen,
      moves: [for (final l in moves) l.uci],
      opponentName: game.opponent.name,
      userSide: game.color == GameColor.black ? Side.black : Side.white,
      outcome: switch (game.result) {
        GameResult.win => AttemptOutcome.win,
        GameResult.draw => AttemptOutcome.draw,
        GameResult.loss => AttemptOutcome.loss,
      },
      playedAt: game.moveAt,
      review: _review(game, startFen, [for (final l in moves) l.san], weight),
      comments: comments,
      selected: chessMove == null
          ? null
          : (chessMove - 1).clamp(-1, moves.length - 1).toInt(),
    );
  }

  /// A revisão com as avaliações do servidor. Nula se ele não mandou um
  /// lance analisado para cada lance do PGN (ou se eles não batem).
  static GameReview? _review(
    CoachGame game,
    String startFen,
    List<String> sans,
    int weight,
  ) {
    final start = GameRules.fromFen(startFen);
    final analyzed = game.moves;
    if (start == null || sans.isEmpty || analyzed.length < sans.length) {
      return null;
    }
    final moves = <Move>[];
    final positions = <Position>[start];
    for (final (i, san) in sans.indexed) {
      if (_clean(analyzed[i].san) != _clean(san)) return null;
      final move = positions.last.parseSan(san);
      if (move == null) return null;
      moves.add(move);
      positions.add(positions.last.play(move));
    }
    // As linhas de cada posição: a avaliação dela e o melhor lance nela (o
    // `melhor` do lance seguinte).
    final analyses = <List<EngineLine>?>[
      for (var k = 0; k <= sans.length; k++)
        _line(
          k == 0 ? const EngineScore(centipawns: 0) : _note(analyzed[k - 1]),
          k < sans.length ? _uci(positions[k], analyzed[k].best) : null,
        ),
    ];
    final computed = ReviewRules.review(
      start: start,
      moves: moves,
      analyses: analyses,
      depth: weight,
    );
    final reviewed = [
      for (final (i, move) in computed.moves.indexed)
        ReviewedMove(
          before: move.before,
          after: move.after,
          quality: _quality(analyzed[i].moveClass, move.quality),
          accuracy: move.accuracy,
          best: move.best,
          bestLine: move.bestLine,
          weight: weight,
        ),
    ];
    // A precisão do jogador é a do servidor (a mesma da lista de partidas).
    final accuracy = game.accuracy;
    final white = game.color == GameColor.white;
    return GameReview(
      moves: reviewed,
      depth: weight,
      whiteAccuracy: white && accuracy != null
          ? accuracy
          : computed.whiteAccuracy,
      blackAccuracy: !white && accuracy != null
          ? accuracy
          : computed.blackAccuracy,
    );
  }

  static MoveQuality _quality(MoveClass moveClass, MoveQuality computed) =>
      switch (moveClass) {
        MoveClass.blunder => MoveQuality.blunder,
        MoveClass.error => MoveQuality.mistake,
        MoveClass.inaccuracy => MoveQuality.inaccuracy,
        MoveClass.ok => computed.isError ? MoveQuality.good : computed,
      };

  static EngineScore? _note(AnalyzedMove chessMove) => chessMove.mate != null
      ? EngineScore(mate: chessMove.mate)
      : chessMove.cp != null
      ? EngineScore(centipawns: chessMove.cp)
      : null;

  static List<EngineLine>? _line(EngineScore? note, String? best) =>
      note == null
      ? null
      : [
          EngineLine(score: note, moves: [?best]),
        ];

  static String? _uci(Position position, String? san) {
    if (san == null || san.isEmpty) return null;
    return position.parseSan(san)?.uci;
  }

  static String _clean(String san) => san.replaceAll(RegExp(r'[+#!?]'), '');
}
