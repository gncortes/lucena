import 'package:flutter/widgets.dart';

import '../../../domain/models/rating_level.dart';

abstract final class PlacementKeys {
  static const screen = Key('placement.screen');

  /// Na abertura.
  static const start = Key('placement.start');
  static const resume = Key('placement.resume');
  static const restart = Key('placement.restart');
  static const chooseByHand = Key('placement.chooseByHand');

  /// Na pergunta.
  static const counter = Key('placement.counter');
  static const progress = Key('placement.progress');
  static const prompt = Key('placement.prompt');
  static const board = Key('placement.board');
  static const confirm = Key('placement.confirm');
  static const dontKnow = Key('placement.dontKnow');
  static Key option(String option) => Key('placement.option.$option');

  /// No resultado.
  static const result = Key('placement.result');
  static const level = Key('placement.level');
  static const ruler = Key('placement.ruler');
  static Key levelChoice(RatingLevel level) =>
      Key('placement.levelChoice.${level.name}');
  static Key node(String id) => Key('placement.node.$id');
  static Key step(int index) => Key('placement.step.$index');
  static const useLevel = Key('placement.useLevel');
  static const sources = Key('placement.sources');
}
