import 'package:flutter/widgets.dart';

/// A tela de detalhes do rating: o número, os números do jogador, o gráfico
/// e o histórico.
abstract final class RatingKeys {
  static const screen = Key('rating.screen');
  static const value = Key('rating.value');
  static const delta = Key('rating.delta');
  static const games = Key('rating.games');
  static const chart = Key('rating.chart');

  /// Os números do progresso (partidas, vitórias, dias seguidos...).
  static const stats = Key('rating.stats');
  static Key stat(int index) => Key('rating.stat.$index');

  /// O período do gráfico (`week`, `month`, `quarter`, `year`, `all`) e o
  /// aviso de período sem partidas.
  static Key period(String period) => Key('rating.period.$period');
  static const chartEmpty = Key('rating.chart.empty');

  /// O rating mais alto e a barra de vitórias, empates e derrotas.
  static const highest = Key('rating.highest');
  static const results = Key('rating.results');

  /// A barra empilhada e cada parte dela (`win`, `draw`, `loss`), com a
  /// contagem e a porcentagem embaixo.
  static const resultsBar = Key('rating.results.bar');
  static Key resultsPart(String outcome) => Key('rating.results.$outcome');

  /// O seletor segmentado dos períodos do gráfico.
  static const periods = Key('rating.periods');

  /// O ⓘ da barra do topo e a explicação do rating no painel que ele abre.
  static const help = Key('rating.help');
  static const helpText = Key('rating.help.text');

  /// O cabeçalho do histórico de partidas (título e total).
  static const historyHeader = Key('rating.history.header');

  static const emptyHistory = Key('rating.history.empty');
  static const emptyHistoryAction = Key('rating.history.empty.action');
  static const loading = Key('rating.loading');

  /// Quantas partidas há no histórico.
  static const gamesCount = Key('rating.history.count');

  /// Uma partida do histórico, da mais recente (0) para a mais antiga: o
  /// adversário, o resultado e, nas que contaram, o rating depois dela e
  /// quanto ela mudou.
  static Key entryOpponent(int index) => Key('rating.history.$index.opponent');
  static Key entryResult(int index) => Key('rating.history.$index.result');
  static Key entry(int index) => Key('rating.history.$index');
  static Key entryRating(int index) => Key('rating.history.$index.rating');
  static Key entryChange(int index) => Key('rating.history.$index.change');

  /// A precisão do jogador na partida, se ela já foi revisada.
  static Key entryAccuracy(int index) => Key('rating.history.$index.accuracy');

  /// A partida em destaque no histórico (a que a conclusão abriu): o fundo
  /// tingido da linha dela.
  static const entryHighlighted = Key('rating.history.highlighted');
}
