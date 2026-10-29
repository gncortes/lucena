import 'package:flutter/widgets.dart';

abstract final class HomeKeys {
  static const courseCard = Key('home.courseCard');
  static const screen = Key('home.screen');
  static const title = Key('home.title');
  static const settingsButton = Key('home.settings');

  /// Os atalhos dos caminhos.
  static const journeyButton = Key('home.journey');
  static const speedrunButton = Key('home.speedrun');
  static const catalogButton = Key('home.catalog');
  static const raceButton = Key('home.race');
  static const schoolButton = Key('home.school');
  static const endgamesButton = Key('home.endgames');
  static const forYouButton = Key('home.forYou');

  /// O cartão "Novo modo desbloqueado" (às cegas).
  static const unlockedCard = Key('home.unlocked');
  static const unlockedClose = Key('home.unlocked.close');
  static const unlockedAction = Key('home.unlocked.action');

  /// O cartão azul do alto (T83), o título e o botão dele.
  static const goalCard = Key('home.goalCard');
  static const goalTitle = Key('home.goalCard.title');
  static const goalAction = Key('home.goalCard.action');

  /// O lugar do app, a barra e a miniatura do cartão azul (T83).
  static const heroLabel = Key('home.goalCard.label');
  static const heroProgress = Key('home.goalCard.progress');
  static const heroBoard = Key('home.goalCard.board');

  /// A seção "Atalhos" (T83): o título, o "Ver mais" e o atalho das
  /// Estrelas.
  static const shortcutsTitle = Key('home.shortcuts.title');
  static const shortcutsSeeMore = Key('home.shortcuts.seeMore');
  static const starsButton = Key('home.stars');

  /// O título de "Finais em destaque".
  static const featuredTitle = Key('home.featured.title');

  /// O rating no alto, ao lado do nome do app.
  static const playerCard = Key('home.player');
  static const rating = Key('home.rating');
  static const ratingValue = Key('home.rating.value');
  static const ratingPending = Key('home.ratingPending');
}
