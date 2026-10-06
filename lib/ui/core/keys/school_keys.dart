import 'package:flutter/widgets.dart';

abstract final class SchoolKeys {
  static const screen = Key('school.screen');
  static const continueButton = Key('school.continue');
  static const graduated = Key('school.graduated');
  static const endgamesButton = Key('school.endgames');
  static const challengesButton = Key('school.challenges');

  /// Uma aula na trilha.
  static Key lesson(String id) => Key('school.lesson.$id');

  /// Um módulo na trilha.
  static Key module(String id) => Key('school.module.$id');
}

abstract final class LessonKeys {
  static const screen = Key('lesson.screen');
  static const missing = Key('lesson.missing');
  static const board = Key('lesson.board');
  static const speech = Key('lesson.speech');
  static const progress = Key('lesson.progress');
  static const stepCounter = Key('lesson.stepCounter');

  /// Sob o tabuleiro: o título da aula e o que fazer no passo.
  static const title = Key('lesson.title');
  static const guide = Key('lesson.guide');
  static const nextButton = Key('lesson.next');
  static const hintButton = Key('lesson.hint');
  static const retryButton = Key('lesson.retry');
  static const finished = Key('lesson.finished');
  static const nextLessonButton = Key('lesson.nextLesson');
  static const trailButton = Key('lesson.trail');
  static const journeyButton = Key('lesson.journey');

  /// No fim da lição de uma aula de final: volta para a aula e os exercícios.
  static const exercisesButton = Key('lesson.exercises');

  /// O passo aberto (`<aula>.<passo>`).
  static Key step(String lessonId, String stepId) =>
      Key('lesson.step.$lessonId.$stepId');

  /// Uma estrela que falta pegar.
  static Key star(String square) => Key('lesson.star.$square');
}

/// Os desafios das estrelas: a lista e um desafio.
abstract final class StarChallengeKeys {
  static const listScreen = Key('starChallenges.screen');
  static const screen = Key('starChallenge.screen');
  static const board = Key('starChallenge.board');
  static const goButton = Key('starChallenge.go');
  static const obstacles = Key('starChallenge.obstacles');
  static const timer = Key('starChallenge.timer');
  static const collected = Key('starChallenge.collected');
  static const result = Key('starChallenge.result');
  static const earned = Key('starChallenge.earned');
  static const best = Key('starChallenge.best');
  static const retryButton = Key('starChallenge.retry');
  static const backButton = Key('starChallenge.back');

  /// Um desafio na lista (`<peça>.<nível>`).
  static Key challenge(String piece, String level) =>
      Key('starChallenges.$piece.$level');

  /// A estrela a pegar, na casa dela.
  static Key star(String square) => Key('starChallenge.star.$square');
}
