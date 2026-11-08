import 'package:flutter/widgets.dart';

import '../../../domain/models/rating_level.dart';

abstract final class PlacementKeys {
  static const screen = Key('placement.screen');

  /// Na abertura.
  static const start = Key('placement.start');
  static const footer = Key('placement.footer');
  static const resume = Key('placement.resume');
  static const stoppedCard = Key('placement.stoppedCard');
  static const stoppedAt = Key('placement.stoppedAt');
  static const answersSaved = Key('placement.answersSaved');
  static const preferRating = Key('placement.preferRating');
  static const restart = Key('placement.restart');

  /// Na pergunta.
  static const counter = Key('placement.counter');
  static const progress = Key('placement.progress');
  static const prompt = Key('placement.prompt');
  static const board = Key('placement.board');
  static const confirm = Key('placement.confirm');

  /// O início da régua do resultado, quando o nível fica abaixo de 1000.
  static const rulerStart = Key('placement.rulerStart');
  static const dontKnow = Key('placement.dontKnow');

  /// "Faltam N casas": quantas casas ainda marcar na pergunta de casas.
  static const squaresLeft = Key('placement.squaresLeft');

  /// O rodapé com as respostas, embaixo do tabuleiro.
  static const answers = Key('placement.answers');
  static Key option(String option) => Key('placement.option.$option');

  /// No resultado.
  static const result = Key('placement.result');
  static const resultHeader = Key('placement.resultHeader');
  static const level = Key('placement.level');
  static const ruler = Key('placement.ruler');
  static Key levelChoice(RatingLevel level) =>
      Key('placement.levelChoice.${level.name}');
  static Key node(String id) => Key('placement.node.$id');
  static Key step(int index) => Key('placement.step.$index');
  static const useLevel = Key('placement.useLevel');
  static const sources = Key('placement.sources');
}
