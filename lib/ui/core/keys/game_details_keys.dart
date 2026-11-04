import 'package:flutter/widgets.dart';

/// Os detalhes de uma partida.
abstract final class GameDetailsKeys {
  static const screen = Key('gameDetails.screen');
  static const board = Key('gameDetails.board');

  /// As abas Resumo, Lances e Motor, e a lista da aba aberta (que rola).
  static const tabSummary = Key('gameDetails.tab.summary');
  static const tabMoves = Key('gameDetails.tab.moves');
  static const tabEngine = Key('gameDetails.tab.engine');
  static const panel = Key('gameDetails.panel');
  static const opponent = Key('gameDetails.opponent');
  static const result = Key('gameDetails.result');

  /// O placar no fim da lista de lances (1–0, 0–1, ½–½).
  static const score = Key('gameDetails.score');
  static const notFound = Key('gameDetails.notFound');
  static const loading = Key('gameDetails.loading');

  /// O lance [index] na tabela e o tempo dele.
  static Key move(int index) => Key('gameDetails.move.$index');
  static Key moveTime(int index) => Key('gameDetails.move.$index.time');

  /// O símbolo da qualidade do lance [index] na tabela.
  static Key moveQuality(int index) => Key('gameDetails.move.$index.quality');

  /// A variante feita no tabuleiro, na tabela, e o lance [ply] dela.
  static const variation = Key('gameDetails.variation');
  static Key variationMove(int ply) => Key('gameDetails.variation.$ply');

  /// A revisão: o botão, o progresso, o resumo e a precisão de cada lado.
  static const pieceBadge = Key('gameDetails.board.pieceBadge');
  static const oldAnalysis = Key('gameDetails.review.oldAnalysis');
  static const oldAnalysisButton = Key('gameDetails.review.oldAnalysisButton');

  /// O cartão do nível da análise, o botão de analisar a fundo, a nota da
  /// análise rápida e a folha de profundidade com as duas opções e o botão.
  static const levelCard = Key('gameDetails.level.card');
  static const levelDeepen = Key('gameDetails.level.deepen');
  static const levelNote = Key('gameDetails.level.note');
  static const depthSheet = Key('gameDetails.depth.sheet');
  static const depthSheetClose = Key('gameDetails.depth.sheet.close');
  static const depthMedium = Key('gameDetails.depth.medium');
  static const depthDeep = Key('gameDetails.depth.deep');
  static const depthConfirm = Key('gameDetails.depth.confirm');
  static const reviewProgress = Key('gameDetails.review.progress');

  /// A história que o Viktor conta enquanto a revisão roda.
  static const story = Key('gameDetails.review.story');

  /// O ✕ no balão da história, que a fecha.
  static const reviewSummary = Key('gameDetails.review.summary');
  static const accuracyWhite = Key('gameDetails.review.accuracy.white');
  static const accuracyBlack = Key('gameDetails.review.accuracy.black');

  /// A contagem de lances de uma qualidade ([quality] é o nome) de um lado.
  static Key count(String quality, {required bool white}) =>
      Key('gameDetails.review.count.$quality.${white ? 'white' : 'black'}');

  /// A explicação do lance mostrado e a barra de avaliação (só com a
  /// engine ligada).
  static const explanation = Key('gameDetails.explanation');
  static const evalBar = Key('gameDetails.evalBar');

  /// A legenda dos símbolos, no fim.
  static const legend = Key('gameDetails.legend');

  /// A navegação entre os lances.
  static const first = Key('gameDetails.nav.first');
  static const previous = Key('gameDetails.nav.previous');
  static const next = Key('gameDetails.nav.next');
  static const last = Key('gameDetails.nav.last');

  /// A engine: o botão e as linhas.
  static const engineButton = Key('gameDetails.engine.button');
  static const engineLines = Key('gameDetails.engine.lines');
  static Key engineLine(int index) => Key('gameDetails.engine.line.$index');

  /// O menu: abrir fora e copiar.
  static const moreButton = Key('gameDetails.more');
  static const openLichess = Key('gameDetails.more.lichess');
  static const openChessCom = Key('gameDetails.more.chessCom');
  static const copyFen = Key('gameDetails.more.fen');
  static const copyPgn = Key('gameDetails.more.pgn');
}
