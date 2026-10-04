import 'package:flutter/widgets.dart';

abstract final class FreeBoardKeys {
  static const screen = Key('freeBoard.screen');
  static const board = Key('freeBoard.board');

  /// De quem é a vez, enquanto a partida continua.
  static const turn = Key('freeBoard.turn');

  static const moveList = Key('freeBoard.moves');
  static const noMoves = Key('freeBoard.moves.empty');

  /// O lance de índice [index] na lista (0 é o primeiro da partida).
  static Key move(int index) => Key('freeBoard.moves.$index');

  static const flipButton = Key('freeBoard.flip');

  /// Botão da barra superior, sempre visível.
  static const newGameButton = Key('freeBoard.newGame');

  static const endPanel = Key('freeBoard.end');
  static const endReason = Key('freeBoard.end.reason');
  static const endResult = Key('freeBoard.end.result');
  static const endNewGameButton = Key('freeBoard.end.newGame');
}
