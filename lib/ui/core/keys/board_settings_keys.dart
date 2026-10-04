import 'package:flutter/widgets.dart';

import '../../../domain/models/board_settings.dart';

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
}
