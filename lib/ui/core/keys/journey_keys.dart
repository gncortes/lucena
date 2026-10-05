import 'package:flutter/widgets.dart';

abstract final class JourneyKeys {
  /// O cartão do Viktor reencontrando o ex-aluno, no degrau 2600.
  static const reunion = Key('journey.reunion');

  static const screen = Key('journey.screen');
  static const rungScreen = Key('journey.rung.screen');
  static const challengeScreen = Key('journey.challenge.screen');

  /// O resumo do alto: onde o jogador está e o próximo degrau.
  static const current = Key('journey.current');
  static const next = Key('journey.next');

  static Key rung(String id) => Key('journey.rung.$id');
  static Key rungLocked(String id) => Key('journey.rung.$id.locked');
  static Key rungCompleted(String id) => Key('journey.rung.$id.completed');

  /// O aviso do que falta para liberar um degrau.
  static const lockedMessage = Key('journey.lockedMessage');

  /// Um desafio, pelo id da posição dentro do degrau.
  static Key challenge(String position) => Key('journey.challenge.$position');
  static Key challengeDone(String position) =>
      Key('journey.challenge.$position.done');

  static const play = Key('journey.play');

  /// O histórico: o título de cada mês e cada partida, na ordem da tela.
  static Key month(int index) => Key('journey.history.month.$index');
  static Key attempt(int index) => Key('journey.history.attempt.$index');
  static const emptyHistory = Key('journey.history.empty');
}
