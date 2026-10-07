import 'package:flutter/widgets.dart';

abstract final class JourneyKeys {
  /// Um desafio especial (às cegas) na tela do degrau.
  static Key special(String id) => Key('journey.special.$id');

  /// O cartão do Viktor reencontrando o ex-aluno, no degrau 2600.
  static const reunion = Key('journey.reunion');

  static const screen = Key('journey.screen');

  /// A frase do alto: a Jornada vem depois das aulas.
  static const intro = Key('journey.intro');
  static const rungScreen = Key('journey.rung.screen');
  static const challengeScreen = Key('journey.challenge.screen');

  /// O resumo do alto: onde o jogador está e o próximo degrau.
  static const current = Key('journey.current');
  static const next = Key('journey.next');
  static const continueButton = Key('journey.continue');

  /// Na tela de um adversário: o cabeçalho com o progresso e o próximo
  /// desafio em destaque, com o botão de jogar.
  static const rungHeader = Key('journey.rung.header');
  static const rungProgress = Key('journey.rung.progress');
  static const nextChallenge = Key('journey.rung.nextChallenge');
  static const nextChallengePlay = Key('journey.rung.nextChallenge.play');

  /// Na tela do desafio: o cartão do adversário.
  static const opponentCard = Key('journey.challenge.opponent');

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
