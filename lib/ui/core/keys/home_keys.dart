import 'package:flutter/widgets.dart';

abstract final class HomeKeys {
  static const screen = Key('home.screen');
  static const mascot = Key('home.mascot');
  static const title = Key('home.title');
  static const tagline = Key('home.tagline');
  static const freeBoardButton = Key('home.freeBoard');
  static const journeyButton = Key('home.journey');
  static const speedrunButton = Key('home.speedrun');
  static const catalogButton = Key('home.catalog');
  static const schoolButton = Key('home.school');
  static const schoolCard = Key('home.schoolCard');
  static const schoolContinue = Key('home.schoolContinue');
  static const customPositionButton = Key('home.customPosition');
  static const settingsButton = Key('home.settings');
  static const version = Key('home.version');

  static const achievementsButton = Key('home.achievements');

  /// O cartão "onde estou": o degrau, o próximo desafio e o botão.
  static const whereCard = Key('home.where');
  static const whereTitle = Key('home.where.title');
  static const whereNext = Key('home.where.next');
  static const whereContinue = Key('home.where.continue');
  static const rating = Key('home.rating');
}
