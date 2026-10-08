import 'package:flutter/widgets.dart';

/// Os detalhes de uma partida.
abstract final class GameDetailsKeys {
  static const screen = Key('gameDetails.screen');
  static const board = Key('gameDetails.board');
  static const opponent = Key('gameDetails.opponent');
  static const result = Key('gameDetails.result');
  static const notFound = Key('gameDetails.notFound');
  static const loading = Key('gameDetails.loading');

  /// O lance [index] na tabela e o tempo dele.
  static Key move(int index) => Key('gameDetails.move.$index');
  static Key moveTime(int index) => Key('gameDetails.move.$index.time');

  /// O símbolo da qualidade do lance [index] na tabela.
  static Key moveQuality(int index) => Key('gameDetails.move.$index.quality');

  /// A revisão: o botão, o progresso, o resumo e a precisão de cada lado.
  static const reviewButton = Key('gameDetails.review.button');
  static const reviewQuick = Key('gameDetails.review.quick');
  static const reviewDeep = Key('gameDetails.review.deep');
  static const reviewProgress = Key('gameDetails.review.progress');

  /// A história que o Viktor conta enquanto a revisão roda.
  static const story = Key('gameDetails.review.story');
  static const reviewSummary = Key('gameDetails.review.summary');
  static const accuracyWhite = Key('gameDetails.review.accuracy.white');
  static const accuracyBlack = Key('gameDetails.review.accuracy.black');

  /// A contagem de lances de uma qualidade ([quality] é o nome) de um lado.
  static Key count(String quality, {required bool white}) =>
      Key('gameDetails.review.count.$quality.${white ? 'white' : 'black'}');

  /// A explicação do lance mostrado e a barra de avaliação.
  static const explanation = Key('gameDetails.explanation');
  static const evalBar = Key('gameDetails.evalBar');

  /// A legenda dos símbolos, no fim, e a opção de mostrar a barra.
  static const legend = Key('gameDetails.legend');
  static const evalBarToggle = Key('gameDetails.more.evalBar');

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
