import 'package:flutter/widgets.dart';

abstract final class HomeKeys {
  static const screen = Key('home.screen');
  static const title = Key('home.title');
  static const freeBoardButton = Key('home.freeBoard');
  static const journeyButton = Key('home.journey');
  static const speedrunButton = Key('home.speedrun');
  static const catalogButton = Key('home.catalog');
  static const raceButton = Key('home.race');
  static const schoolButton = Key('home.school');
  static const endgamesButton = Key('home.endgames');
  static const forYouButton = Key('home.forYou');
  static const schoolCard = Key('home.schoolCard');
  static const schoolContinue = Key('home.schoolContinue');

  /// O cartão da aula de final em andamento.
  static const endgameCard = Key('home.endgameCard');
  static const endgameTitle = Key('home.endgameCard.title');
  static const endgameWhere = Key('home.endgameCard.where');

  /// A miniatura do exercício da vez, no cartão da aula de final.
  static const endgameBoard = Key('home.endgameCard.board');
  static const endgameContinue = Key('home.endgameContinue');
  static const customPositionButton = Key('home.customPosition');
  static const settingsButton = Key('home.settings');

  /// O título dos caminhos ("O que você quer fazer?").
  static const pathsTitle = Key('home.paths.title');

  /// "Personalizar", ao lado do título dos caminhos.
  static const customizeButton = Key('home.paths.customize');

  /// "Outros modos": os caminhos fora do destaque, recolhidos.
  static const otherModes = Key('home.paths.other');

  /// O cartão "Novo modo desbloqueado" (às cegas).
  static const unlockedCard = Key('home.unlocked');
  static const unlockedClose = Key('home.unlocked.close');
  static const unlockedAction = Key('home.unlocked.action');

  /// O aviso único de que dá para escolher os caminhos.
  static const layoutNotice = Key('home.layoutNotice');
  static const layoutNoticeCustomize = Key('home.layoutNotice.customize');
  static const layoutNoticeClose = Key('home.layoutNotice.close');

  /// "Todos os modos", no alto.
  static const allModesButton = Key('home.allModes');

  static const achievementsButton = Key('home.achievements');

  /// O cartão "onde estou": o degrau, o próximo desafio e o botão.
  static const whereCard = Key('home.where');

  /// O cartão grande "Seu objetivo" (E1.11), o botão e o título dele.
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

  /// "Continuar de onde parou": o que está em andamento fora do objetivo.
  static const resumeCard = Key('home.resumeCard');
  static const resumeTitle = Key('home.resumeCard.title');
  static const whereTitle = Key('home.where.title');
  static const whereNext = Key('home.where.next');
  static const whereContinue = Key('home.where.continue');
  static const rating = Key('home.rating');
  static const ratingValue = Key('home.rating.value');

  /// O painel do jogador.
  static const playerCard = Key('home.player');
  static const ratingLabel = Key('home.ratingLabel');
  static const ratingPending = Key('home.ratingPending');
  static const whereBoard = Key('home.where.board');
}
