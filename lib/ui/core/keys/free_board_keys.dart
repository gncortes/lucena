import 'package:dartchess/dartchess.dart';
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

  /// O relógio de um lado e o tempo escrito nele.
  static Key clock(Side side) => Key('freeBoard.clock.${side.name}');
  static Key clockTime(Side side) => Key('freeBoard.clock.${side.name}.time');

  /// Botão que abre o painel do relógio, e o painel.
  static const clockButton = Key('freeBoard.clock.open');
  static const clockSheet = Key('freeBoard.clock.sheet');
  static const clockEnabledSwitch = Key('freeBoard.clock.sheet.enabled');
  static const clockSameSwitch = Key('freeBoard.clock.sheet.same');
  static const clockStartButton = Key('freeBoard.clock.sheet.start');

  /// Opção de minutos de um lado no painel. Com o mesmo tempo para os dois,
  /// vale a das brancas.
  static Key clockMinutes(Side side, int minutes) =>
      Key('freeBoard.clock.sheet.${side.name}.minutes.$minutes');

  /// Opção de incremento, em segundos, de um lado no painel.
  static Key clockIncrement(Side side, int seconds) =>
      Key('freeBoard.clock.sheet.${side.name}.increment.$seconds');

  /// Botão da barra superior, sempre visível.
  static const newGameButton = Key('freeBoard.newGame');

  static const endPanel = Key('freeBoard.end');
  static const endReason = Key('freeBoard.end.reason');
  static const endResult = Key('freeBoard.end.result');
  static const endNewGameButton = Key('freeBoard.end.newGame');
}
