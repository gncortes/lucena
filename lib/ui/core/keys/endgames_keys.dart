import 'package:flutter/widgets.dart';

/// A trilha das aulas de finais.
abstract final class EndgamesKeys {
  /// O teste de nível (T52): a entrada, o próximo final e os selos.
  static const placementTest = Key('endgames.placementTest');
  static const nextEndgame = Key('endgames.nextEndgame');

  /// O filtro "Para você" / "Todos".
  static const filter = Key('endgames.filter');
  static const forYou = Key('endgames.filter.forYou');
  static const all = Key('endgames.filter.all');
  static const hideDone = Key('endgames.hideDone');
  static const forYouEmpty = Key('endgames.forYouEmpty');
  static Key badge(String lessonId) => Key('endgames.badge.$lessonId');

  static const screen = Key('endgames.screen');
  static const continueButton = Key('endgames.continue');
  static const overview = Key('endgames.overview');

  static Key module(String id) => Key('endgames.module.$id');
  static Key lesson(String id) => Key('endgames.lesson.$id');
  static Key lessonScore(String id) => Key('endgames.lesson.$id.score');
}

/// O resultado dos exercícios de uma aula de final.
abstract final class ExercisesDoneKeys {
  static const screen = Key('exercisesDone.screen');
  static const score = Key('exercisesDone.score');
  static const needMore = Key('exercisesDone.needMore');
  static const back = Key('exercisesDone.back');
  static Key grade(String name) => Key('exercisesDone.grade.$name');
  static const current = Key('exercisesDone.current');
}

/// Uma aula de final: a lição, os exercícios, a nota e o passo final.
abstract final class EndgameLessonKeys {
  /// T51: a tela da aula com as partes, o teste final e o "Continuar".
  static const list = Key('endgameLesson.list');
  static const progressLine = Key('endgameLesson.progressLine');
  static Key part(String id) => Key('endgameLesson.part.$id');
  static const finalTest = Key('endgameLesson.finalTest');
  static const finalTestSummary = Key('endgameLesson.finalTest.summary');
  static const testAdvice = Key('endgameLesson.finalTest.advice');
  static const testFeedback = Key('endgameLesson.finalTest.feedback');
  static const continueButton = Key('endgameLesson.continue');

  static const screen = Key('endgameLesson.screen');
  static const missing = Key('endgameLesson.missing');
  static const speech = Key('endgameLesson.speech');
  static const infoButton = Key('endgameLesson.info');
  static const lessonButton = Key('endgameLesson.lesson');
  static const lessonDone = Key('endgameLesson.lessonDone');
  static const exercises = Key('endgameLesson.exercises');
  static const score = Key('endgameLesson.score');
  static const passed = Key('endgameLesson.passed');
  static const failed = Key('endgameLesson.failed');
  static const redoButton = Key('endgameLesson.redo');
  static const finalStep = Key('endgameLesson.final');
  static const speedrunButton = Key('endgameLesson.speedrun');
  static const trainButton = Key('endgameLesson.train');
  static const nextLessonButton = Key('endgameLesson.nextLesson');

  /// Um exercício na lista e as estrelas ganhas nele.
  static Key exercise(String id) => Key('endgameLesson.exercise.$id');
  static Key exerciseStars(String id) =>
      Key('endgameLesson.exercise.$id.stars');

  /// O ritmo escolhido para o speedrun (`180+2`).
  static Key pace(String code) => Key('endgameLesson.pace.$code');
}

/// As informações de uma aula: referências, posições-base e história.
abstract final class EndgameInfoKeys {
  static const screen = Key('endgameInfo.screen');
  static const history = Key('endgameInfo.history');
  static Key reference(String id) => Key('endgameInfo.reference.$id');
  static Key keyPosition(String id) => Key('endgameInfo.key.$id');
}

/// Um exercício de uma aula de final.
abstract final class ExerciseKeys {
  static const screen = Key('exercise.screen');
  static const missing = Key('exercise.missing');
  static const board = Key('exercise.board');
  static const speech = Key('exercise.speech');
  static const scroll = Key('exercise.scroll');
  static const hintButton = Key('exercise.hint');
  static const stars = Key('exercise.stars');
  static const earned = Key('exercise.earned');
  static const solved = Key('exercise.solved');
  static const explainButton = Key('exercise.explain');
  static const resultButton = Key('exercise.result');
  static const nextButton = Key('exercise.next');
  static const counter = Key('exercise.counter');

  /// Sob o tabuleiro: o objetivo antes, as estrelas e a solução depois.
  static const goal = Key('exercise.goal');
  static const solution = Key('exercise.solution');

  /// O exercício aberto (`<aula>.<exercício>`).
  static Key open(String lessonId, String exerciseId) =>
      Key('exercise.open.$lessonId.$exerciseId');
}
