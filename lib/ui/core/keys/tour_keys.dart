import 'package:flutter/widgets.dart';

import '../../../domain/models/rating_level.dart';
import '../../tour/view_models/tour_cubit.dart';

abstract final class TourKeys {
  static const screen = Key('tour.screen');
  static const skipButton = Key('tour.skip');
  static const nextButton = Key('tour.next');
  static const backButton = Key('tour.back');
  static const startButton = Key('tour.start');
  static const startRung = Key('tour.startRung');
  static const progress = Key('tour.progress');
  static const stepCounter = Key('tour.stepCounter');
  static const viktor = Key('tour.viktor');
  static const speech = Key('tour.speech');

  /// O passo aberto.
  static Key step(TourStep step) => Key('tour.step.${step.name}');

  /// Uma faixa no passo do nível.
  static Key level(RatingLevel level) => Key('tour.level.${level.name}');
}
