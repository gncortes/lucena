import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';

import '../../../domain/models/endgame_position.dart';

abstract final class CustomPositionKeys {
  static const screen = Key('custom.screen');

  /// O painel da paleta e das opções, embaixo do tabuleiro.
  static const panel = Key('custom.panel');
  static const editor = Key('custom.editor');
  static const fenField = Key('custom.fen');
  static const pasteButton = Key('custom.paste');
  static const clearButton = Key('custom.clear');

  /// Peça da paleta (`custom.palette.white.queen`).
  static Key palette(Piece piece) =>
      Key('custom.palette.${piece.color.name}.${piece.role.name}');
  static const moveTool = Key('custom.tool.move');
  static const eraseTool = Key('custom.tool.erase');

  static Key turn(Side side) => Key('custom.turn.${side.name}');
  static Key goal(PositionGoal goal) => Key('custom.goal.${goal.code}');
  static const error = Key('custom.error');
  static const continueButton = Key('custom.continue');
}
