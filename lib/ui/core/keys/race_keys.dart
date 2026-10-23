import 'package:flutter/widgets.dart';

import '../../../domain/models/race.dart';

/// As keys da Corrida de problemas (E1.31).
abstract final class RaceKeys {
  static const screen = Key('race.screen');
  static const introView = Key('race.intro');
  static const gameView = Key('race.game');
  static const resultView = Key('race.result');
  static const reviewView = Key('race.review');

  /// Abertura: o chip de cada tema (nulo: todos os finais), o recorde, o
  /// botão de começar.
  static Key themeChip(RaceTheme? theme) =>
      Key('race.theme.${theme?.name ?? 'all'}');

  /// Abertura: o seletor de duração (E1.33) e cada opção.
  static const duration = Key('race.duration');
  static Key durationOption(RaceDuration duration) =>
      Key('race.duration.${duration.minutes}');
  static const recordCard = Key('race.record');
  static const start = Key('race.start');
  static const empty = Key('race.empty');

  /// Corrida: o tabuleiro, o placar (contador ou ícone), o relógio, as
  /// chances e a saída.
  static const board = Key('race.board');
  static const scoreboard = Key('race.scoreboard');
  static const count = Key('race.count');
  static const feedbackCorrect = Key('race.feedback.correct');
  static const feedbackWrong = Key('race.feedback.wrong');
  static const clock = Key('race.clock');
  static const clockTime = Key('race.clock.time');
  static const chances = Key('race.chances');
  static Key chance(int index, {required bool lost}) =>
      Key('race.chance.$index.${lost ? 'lost' : 'kept'}');
  static const exit = Key('race.exit');

  /// Resultado.
  static const resultTitle = Key('race.result.title');
  static const resultCorrects = Key('race.result.corrects');
  static const newRecord = Key('race.result.newRecord');
  static const statErrors = Key('race.result.stat.errors');
  static const statHardest = Key('race.result.stat.hardest');
  static const statPace = Key('race.result.stat.pace');
  static Key problemTile(int index) => Key('race.result.problem.$index');
  static const again = Key('race.result.again');
  static const reviewMistakes = Key('race.result.review');
  static const close = Key('race.result.close');

  /// Revisão dos erros.
  static const reviewTitle = Key('race.review.title');
  static const reviewPlayed = Key('race.review.played');
  static const reviewRight = Key('race.review.right');
  static const reviewMeta = Key('race.review.meta');
  static const reviewNext = Key('race.review.next');

  /// A folha "Aquecer antes?".
  static const offerSheet = Key('race.offer.sheet');
  static const offerWarm = Key('race.offer.warm');
  static const offerSkip = Key('race.offer.skip');
  static const offerNever = Key('race.offer.never');
  static Key offerBoard(int index) => Key('race.offer.board.$index');

  /// O aquecimento.
  static const warmUpScreen = Key('race.warmUp.screen');
  static const warmUpProgress = Key('race.warmUp.progress');
  static const warmUpClose = Key('race.warmUp.close');
  static const warmUpSkip = Key('race.warmUp.skip');
  static const warmUpDone = Key('race.warmUp.done');
  static const warmUpDoneBody = Key('race.warmUp.done.body');
  static const warmUpPlay = Key('race.warmUp.play');
  static Key warmUpResult(int index) => Key('race.warmUp.result.$index');

  /// O item "Problemas" em Todos os modos fica em `AllModesKeys.item`.
  static const allModesItem = 'race';
}
