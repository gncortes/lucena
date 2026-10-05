import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';

import '../../../domain/models/character.dart';

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

  /// Desistir (só no treino) e o painel que confirma.
  static const resignButton = Key('freeBoard.resign');
  static const resignSheet = Key('freeBoard.resign.sheet');
  static const resignConfirmButton = Key('freeBoard.resign.confirm');

  /// A máquina está pensando.
  static const machineThinking = Key('freeBoard.machineThinking');

  /// O resultado do treino no painel do fim: objetivo cumprido ou não.
  static const endGoal = Key('freeBoard.end.goal');

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

  /// O personagem acima do tabuleiro: a fileira, o retrato (pela emoção), o
  /// nome e o balão com a fala (pelo id da fala).
  static const characterBar = Key('freeBoard.character');
  static const characterName = Key('freeBoard.character.name');
  static const speechBubble = Key('freeBoard.character.bubble');
  static Key characterAvatar(Emotion emotion) =>
      Key('freeBoard.character.avatar.${emotion.name}');
  static Key speechText(String lineId) =>
      Key('freeBoard.character.line.$lineId');

  /// O que a partida terminada mudou: o rating e as mensagens.
  static const report = Key('freeBoard.report');
  static const ratingChange = Key('freeBoard.report.rating');
  static Key feedback(int index) => Key('freeBoard.report.feedback.$index');
}
