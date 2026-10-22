import 'package:flutter/widgets.dart';

import '../../../domain/models/level_source.dart';
import '../../level/view_models/level_cubit.dart';

/// "Seu nível" e a conta opcional, que vêm depois do tour.
abstract final class LevelKeys {
  static const screen = Key('level.screen');
  static const viktor = Key('level.viktor');
  static const speech = Key('level.speech');
  static const continueButton = Key('level.continue');
  static const back = Key('level.back');

  /// Um dos cinco cartões.
  static Key option(LevelChoice choice) => Key('level.option.${choice.name}');

  /// "Lichess conectado" (também com rating provisório).
  static const lichessScreen = Key('level.lichess');
  static const lichessUse = Key('level.lichess.use');
  static const lichessTest = Key('level.lichess.test');
  static const lichessUseDefault = Key('level.lichess.useDefault');

  /// "Rating do Chess.com".
  static const chessScreen = Key('level.chess');
  static const chessField = Key('level.chess.field');
  static const chessUse = Key('level.chess.use');

  /// "Prefiro fazer o teste" no Lichess e no Chess.com.
  static const preferTest = Key('level.preferTest');

  /// "Informar o rating".
  static const ratingScreen = Key('level.rating');
  static const ratingField = Key('level.rating.field');
  static Key ratingSource(RatingOrigin origin) =>
      Key('level.rating.source.${origin.name}');
  static const ratingUse = Key('level.rating.use');
}
