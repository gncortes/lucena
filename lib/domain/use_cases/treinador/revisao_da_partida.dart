import 'package:dartchess/dartchess.dart';

import '../../models/attempt.dart';
import '../../models/game_review.dart';
import '../../models/imported_game.dart';
import '../../models/treinador/treinador.dart';
import '../game_rules.dart';
import '../review_rules.dart';
import 'lances_da_partida.dart';

/// A partida do Treinador na forma da análise de partida do app: os lances do
/// PGN e a revisão feita com as avaliações do servidor, na qualidade de lance
/// do app. A classe do servidor manda (é a mesma dos exercícios): grave é
/// erro grave, erro é erro, imprecisão é imprecisão; um lance "ok" nunca
/// aparece como falha.
abstract final class RevisaoDaPartida {
  /// [lance] é o meio-lance aberto (1 = o primeiro lance das brancas; 0 = o
  /// início). [peso] é o peso das anotações do servidor: com o maior da
  /// engine do aparelho, ela não troca a classe dele.
  static ImportedGame de(PartidaTreinador partida, {int? lance, int peso = 0}) {
    final lances = LancesDaPartida.de(partida.pgn);
    final inicio = LancesDaPartida.inicio(partida.pgn);
    final comentarios = <int, String>{
      for (final (i, l) in partida.lances.indexed)
        if (i < lances.length && (l.comentario ?? '').trim().isNotEmpty)
          i: l.comentario!.trim(),
    };
    return ImportedGame(
      startFen: inicio,
      moves: [for (final l in lances) l.uci],
      opponentName: partida.adversario.nome,
      userSide: partida.cor == CorPartida.pretas ? Side.black : Side.white,
      outcome: switch (partida.resultado) {
        Resultado.vitoria => AttemptOutcome.win,
        Resultado.empate => AttemptOutcome.draw,
        Resultado.derrota => AttemptOutcome.loss,
      },
      playedAt: partida.jogadaEm,
      review: _revisao(partida, inicio, [for (final l in lances) l.san], peso),
      comments: comentarios,
      selected: lance == null
          ? null
          : (lance - 1).clamp(-1, lances.length - 1).toInt(),
    );
  }

  /// A revisão com as avaliações do servidor. Nula se ele não mandou um
  /// lance analisado para cada lance do PGN (ou se eles não batem).
  static GameReview? _revisao(
    PartidaTreinador partida,
    String inicio,
    List<String> sans,
    int peso,
  ) {
    final start = GameRules.fromFen(inicio);
    final analisados = partida.lances;
    if (start == null || sans.isEmpty || analisados.length < sans.length) {
      return null;
    }
    final moves = <Move>[];
    final posicoes = <Position>[start];
    for (final (i, san) in sans.indexed) {
      if (_limpo(analisados[i].san) != _limpo(san)) return null;
      final move = posicoes.last.parseSan(san);
      if (move == null) return null;
      moves.add(move);
      posicoes.add(posicoes.last.play(move));
    }
    // As linhas de cada posição: a avaliação dela e o melhor lance nela (o
    // `melhor` do lance seguinte).
    final analyses = <List<EngineLine>?>[
      for (var k = 0; k <= sans.length; k++)
        _linha(
          k == 0 ? const EngineScore(centipawns: 0) : _nota(analisados[k - 1]),
          k < sans.length ? _uci(posicoes[k], analisados[k].melhor) : null,
        ),
    ];
    final calculada = ReviewRules.review(
      start: start,
      moves: moves,
      analyses: analyses,
      depth: peso,
    );
    final revisados = [
      for (final (i, move) in calculada.moves.indexed)
        ReviewedMove(
          before: move.before,
          after: move.after,
          quality: _qualidade(analisados[i].classe, move.quality),
          accuracy: move.accuracy,
          best: move.best,
          bestLine: move.bestLine,
          weight: peso,
        ),
    ];
    // A precisão do jogador é a do servidor (a mesma da lista de partidas).
    final precisao = partida.precisao;
    final brancas = partida.cor == CorPartida.brancas;
    return GameReview(
      moves: revisados,
      depth: peso,
      whiteAccuracy: brancas && precisao != null
          ? precisao
          : calculada.whiteAccuracy,
      blackAccuracy: !brancas && precisao != null
          ? precisao
          : calculada.blackAccuracy,
    );
  }

  static MoveQuality _qualidade(ClasseLance classe, MoveQuality calculada) =>
      switch (classe) {
        ClasseLance.grave => MoveQuality.blunder,
        ClasseLance.erro => MoveQuality.mistake,
        ClasseLance.imprecisao => MoveQuality.inaccuracy,
        ClasseLance.ok => calculada.isError ? MoveQuality.good : calculada,
      };

  static EngineScore? _nota(LanceAnalisado lance) => lance.mate != null
      ? EngineScore(mate: lance.mate)
      : lance.cp != null
      ? EngineScore(centipawns: lance.cp)
      : null;

  static List<EngineLine>? _linha(EngineScore? nota, String? melhor) =>
      nota == null
      ? null
      : [
          EngineLine(score: nota, moves: [?melhor]),
        ];

  static String? _uci(Position posicao, String? san) {
    if (san == null || san.isEmpty) return null;
    return posicao.parseSan(san)?.uci;
  }

  static String _limpo(String san) => san.replaceAll(RegExp(r'[+#!?]'), '');
}
