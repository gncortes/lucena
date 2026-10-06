import 'package:flutter/widgets.dart';

abstract final class HomeKeys {
  static const screen = Key('home.screen');
  static const title = Key('home.title');
  static const freeBoardButton = Key('home.freeBoard');
  static const journeyButton = Key('home.journey');
  static const speedrunButton = Key('home.speedrun');
  static const catalogButton = Key('home.catalog');
  static const schoolButton = Key('home.school');
  static const endgamesButton = Key('home.endgames');
  static const schoolCard = Key('home.schoolCard');
  static const schoolContinue = Key('home.schoolContinue');

  /// O cartão da aula de final em andamento.
  static const endgameCard = Key('home.endgameCard');
  static const endgameTitle = Key('home.endgameCard.title');
  static const endgameWhere = Key('home.endgameCard.where');
  static const endgameContinue = Key('home.endgameContinue');
  static const customPositionButton = Key('home.customPosition');
  static const settingsButton = Key('home.settings');

  /// O título dos caminhos ("O que você quer fazer?").
  static const pathsTitle = Key('home.paths.title');

  static const achievementsButton = Key('home.achievements');

  /// O cartão "onde estou": o degrau, o próximo desafio e o botão.
  static const whereCard = Key('home.where');
  static const whereTitle = Key('home.where.title');
  static const whereNext = Key('home.where.next');
  static const whereContinue = Key('home.where.continue');
  static const rating = Key('home.rating');
  static const ratingValue = Key('home.rating.value');

  /// O painel do jogador.
  static const playerCard = Key('home.player');
  static const hello = Key('home.hello');
  static const whereBoard = Key('home.where.board');
}
