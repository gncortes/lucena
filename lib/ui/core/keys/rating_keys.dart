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

  /// O período do gráfico: as últimas [games] partidas ou todas.
  static Key period(int? games) => Key('rating.period.${games ?? 'all'}');

  static const emptyHistory = Key('rating.history.empty');

  /// Uma partida do histórico, da mais recente (0) para a mais antiga, o
  /// rating depois dela e quanto ela mudou.
  static Key entry(int index) => Key('rating.history.$index');
  static Key entryRating(int index) => Key('rating.history.$index.rating');
  static Key entryChange(int index) => Key('rating.history.$index.change');
}
