import 'package:flutter/widgets.dart';

abstract final class SchoolKeys {
  /// O teste de nível (T52): a entrada e o grupo das aulas dispensadas.
  static const placementTest = Key('school.placementTest');
  static const skippedGroup = Key('school.skippedGroup');
  static const reviewSkipped = Key('school.reviewSkipped');

  static const screen = Key('school.screen');
  static const continueButton = Key('school.continue');
  static const graduated = Key('school.graduated');
  static const diploma = Key('school.graduation.diploma');
  static const diplomaName = Key('school.graduation.diplomaName');
  static const graduationSummary = Key('school.graduation.summary');
  static const graduationCard = Key('school.graduation.card');
  static const graduationShare = Key('school.graduation.share');
  static const endgamesButton = Key('school.endgames');
  static const challengesButton = Key('school.challenges');

  /// Uma aula na trilha.
  static Key lesson(String id) => Key('school.lesson.$id');

  /// Um módulo na trilha.
  static Key module(String id) => Key('school.module.$id');
}

abstract final class LessonKeys {
  /// Antes da primeira aula com passo de pensar: quanto tempo pensar.
  static const thinkChooser = Key('lesson.thinkChooser');
  static Key thinkChoice(int minutes) => Key('lesson.thinkChoice.$minutes');

  /// O convite para jogar no Lichess e o botão que abre o site.
  static const lichessInvite = Key('lesson.lichessInvite');
  static const lichessButton = Key('lesson.lichessButton');

  /// O confete do fim da aula.
  static const celebration = Key('lesson.celebration');

  /// Na formatura: o primeiro jogo com relógio e o que é o "+10".
  static const clockGameButton = Key('lesson.clockGame');
  static const clockHelp = Key('lesson.clockHelp');

  static const screen = Key('lesson.screen');
  static const missing = Key('lesson.missing');
  static const board = Key('lesson.board');
  static const speech = Key('lesson.speech');
  static const scroll = Key('lesson.scroll');

  /// Volta ao passo anterior, para rever.
  static const backButton = Key('lesson.back');
  static const progress = Key('lesson.progress');
  static const stepCounter = Key('lesson.stepCounter');

  /// Sob o tabuleiro: o título da aula e o que fazer no passo.
  static const title = Key('lesson.title');
  static const guide = Key('lesson.guide');
  static const nextButton = Key('lesson.next');
  static const hintButton = Key('lesson.hint');

  /// T51: o passo de pensar, a demonstração e o fim de uma parte.
  static const thinkClock = Key('lesson.think.clock');
  static const appBarTitle = Key('lesson.appBar.title');
  static const place = Key('lesson.appBar.place');
  static const thinkReset = Key('lesson.think.reset');
  static const thinkSkip = Key('lesson.think.skip');
  static const moreHintButton = Key('lesson.think.moreHint');
  static const demoBack = Key('lesson.demo.back');
  static const demoForward = Key('lesson.demo.forward');
  static const demoReplay = Key('lesson.demo.replay');
  static const partFinished = Key('lesson.part.finished');
  static const nextPartButton = Key('lesson.part.next');
  static const reviewPartButton = Key('lesson.part.review');
  static const closeSheet = Key('lesson.sheet.close');
  static const partSummary = Key('lesson.part.summary');
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
  /// Às cegas: o nome da casa da estrela.
  static const starName = Key('starChallenge.starName');

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
