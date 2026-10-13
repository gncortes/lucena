import 'package:flutter/widgets.dart';

/// O cartão do rating, os números do jogador e as partidas do Histórico (aba
/// Partidas).
abstract final class RatingKeys {
  static const screen = Key('rating.screen');
  static const value = Key('rating.value');
  static const delta = Key('rating.delta');
  static const games = Key('rating.games');
  static const chart = Key('rating.chart');

  /// O aviso de período sem partidas.
  static const chartEmpty = Key('rating.chart.empty');

  /// O rating mais alto.
  static const highest = Key('rating.highest');

  /// O ⓘ da barra do topo e a explicação do rating no painel que ele abre.
  static const help = Key('rating.help');
  static const helpText = Key('rating.help.text');

  static const emptyHistory = Key('rating.history.empty');
  static const emptyHistoryAction = Key('rating.history.empty.action');
  static const loading = Key('rating.loading');

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
