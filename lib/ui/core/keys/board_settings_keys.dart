import 'package:flutter/widgets.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/clock_settings.dart';

abstract final class BoardSettingsKeys {
  static const appearanceScreen = Key('boardSettings.appearance.screen');

  /// O tabuleiro de amostra, que muda junto com as escolhas.
  static const preview = Key('boardSettings.appearance.preview');

  static Key colorsOption(BoardColors colors) =>
      Key('boardSettings.appearance.colors.${colors.code}');

  static Key piecesOption(PieceStyle pieces) =>
      Key('boardSettings.appearance.pieces.${pieces.code}');

  static const coordinatesSwitch = Key('boardSettings.appearance.coordinates');
  static const resetButton = Key('boardSettings.appearance.reset');

  static const behaviorScreen = Key('boardSettings.behavior.screen');
  static const moveMethodTile = Key('boardSettings.behavior.moveMethod');
  static const moveMethodValue = Key('boardSettings.behavior.moveMethod.value');

  static Key moveMethodOption(MoveMethod method) =>
      Key('boardSettings.behavior.moveMethod.${method.code}');

  static const legalMovesSwitch = Key('boardSettings.behavior.legalMoves');
  static const lastMoveSwitch = Key('boardSettings.behavior.lastMove');
  static const animationSwitch = Key('boardSettings.behavior.animation');
  static const premovesSwitch = Key('boardSettings.behavior.premoves');
  static const notationTile = Key('boardSettings.behavior.notation');
  static const notationValue = Key('boardSettings.behavior.notation.value');

  static Key notationOption(MoveNotation notation) =>
      Key('boardSettings.behavior.notation.${notation.code}');

  static const clockScreen = Key('boardSettings.clock.screen');
  static const clockPositionTile = Key('boardSettings.clock.position');
  static const clockPositionValue = Key('boardSettings.clock.position.value');

  static Key clockPositionOption(ClockPosition position) =>
      Key('boardSettings.clock.position.${position.code}');

  static const clockVibrationSwitch = Key('boardSettings.clock.vibration');

  /// O painel de opções aberto e o botão que confirma a opção marcada.
  static const choiceSheet = Key('boardSettings.choice.sheet');
  static const choiceConfirmButton = Key('boardSettings.choice.confirm');
}
