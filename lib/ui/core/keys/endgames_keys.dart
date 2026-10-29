import 'package:flutter/widgets.dart';

/// A trilha das aulas de finais.
abstract final class EndgamesKeys {
  static Key reviewTag(String lessonId) => Key('endgames.reviewTag.$lessonId');

  /// Os filtros da lista (tipo, dificuldade, situação, ordem): o botão, o
  /// modal com as opções, os chips ativos e o estado vazio. As opções e os
  /// chips usam o código da opção (`kind.rook`, `level.casual`,
  /// `status.open`, `sort.easiest`).
  static const filtersButton = Key('endgames.filters.button');
  static const filtersSheet = Key('endgames.filters.sheet');
  static Key filterOption(String code) => Key('endgames.filters.option.$code');
  static Key filterChip(String code) => Key('endgames.filters.chip.$code');
  static const filtersClear = Key('endgames.filters.clear');
  static const filtersSheetClear = Key('endgames.filters.sheet.clear');
  static const filtersApply = Key('endgames.filters.apply');
  static const filtersEmpty = Key('endgames.filters.empty');
  static const filtersEmptyClear = Key('endgames.filters.empty.clear');
  static Key level(String name) => Key('endgames.level.$name');

  static const screen = Key('endgames.screen');
  static const continueButton = Key('endgames.continue');

  static Key module(String id) => Key('endgames.module.$id');
  static Key lesson(String id) => Key('endgames.lesson.$id');

  /// A medalha da nota no cartão do capítulo (GradeMedal M2).
  static Key medal(String id) => Key('endgames.lesson.$id.medal');
}

/// A introdução aos exercícios de uma aula de final.
abstract final class ExercisesIntroKeys {
  static const screen = Key('exercisesIntro.screen');
  static const legend = Key('exercisesIntro.legend');
  static const after = Key('exercisesIntro.after');
  static const tiers = Key('exercisesIntro.tiers');
  static const start = Key('exercisesIntro.start');
}

/// O resultado dos exercícios de uma aula de final.
abstract final class ExercisesDoneKeys {
  static const screen = Key('exercisesDone.screen');
  static const score = Key('exercisesDone.score');
  static const needMore = Key('exercisesDone.needMore');
  static const back = Key('exercisesDone.back');
  static const close = Key('exercisesDone.close');
  static const practice = Key('exercisesDone.practice');
  static const redo = Key('exercisesDone.redo');
  static const retrySpeech = Key('exercisesDone.retrySpeech');
  static const reviewLesson = Key('exercisesDone.reviewLesson');
  static const current = Key('exercisesDone.current');
  static const diploma = Key('exercisesDone.diploma');
  static const shareCard = Key('exercisesDone.shareCard');
  static const diplomaName = Key('exercisesDone.diploma.name');
  static const share = Key('exercisesDone.share');
}

/// Um capítulo de finais: as lições e os exercícios práticos.
abstract final class EndgameLessonKeys {
  /// O aviso de capítulo ainda em revisão (abaixo da nota A) ou reprovado.
  static const inReview = Key('endgameLesson.inReview');
  static const reviewFailed = Key('endgameLesson.reviewFailed');

  /// T82: a lista do capítulo, as lições, a linha dos exercícios práticos e
  /// o botão fixo.
  static const list = Key('endgameLesson.list');
  static Key part(String id) => Key('endgameLesson.part.$id');
  static const exercises = Key('endgameLesson.exercises');
  static const continueButton = Key('endgameLesson.continue');
  static const screen = Key('endgameLesson.screen');
  static const missing = Key('endgameLesson.missing');
  static const infoButton = Key('endgameLesson.info');
}

/// As informações de uma aula: referências, posições-base e história.
abstract final class EndgameInfoKeys {
  static const screen = Key('endgameInfo.screen');
  static const history = Key('endgameInfo.history');
  static Key reference(String id) => Key('endgameInfo.reference.$id');
  static Key referenceSource(String id) =>
      Key('endgameInfo.reference.$id.source');
  static Key keyPosition(String id) => Key('endgameInfo.key.$id');
  static Key keyPositionLink(String id) => Key('endgameInfo.keyLink.$id');
}

/// Um exercício de uma aula de final.
abstract final class ExerciseKeys {
  static const screen = Key('exercise.screen');
  static const missing = Key('exercise.missing');
  static const board = Key('exercise.board');
  static const speech = Key('exercise.speech');
  static const hintButton = Key('exercise.hint');
  static const stars = Key('exercise.stars');
  static const solved = Key('exercise.solved');

  /// O selo "Correto!" que surge sob o tabuleiro ao resolver.
  static const correct = Key('exercise.correct');

  static const resultButton = Key('exercise.result');
  static const backButton = Key('exercise.back');
  static const locked = Key('exercise.locked');
  static const lichessButton = Key('exercise.lichess');
  static const nextButton = Key('exercise.next');
  static const counter = Key('exercise.counter');

  /// O cronômetro do exercício (T60).
  static const timer = Key('exercise.timer');

  /// A página que rola inteira (balão, tabuleiro e lista) e o rodapé fixo.
  static const page = Key('exercise.page');
  static const footer = Key('exercise.footer');

  /// "Ver solução": aparece quando o exercício já não pontua.
  static const showSolution = Key('exercise.showSolution');

  /// Ao lado do som, com a lista completa: cobrir ou mostrar os lances que
  /// o aluno ainda não viu (T69).
  static const hiddenMovesToggle = Key('exercise.hiddenMovesToggle');

  /// O exercício aberto (`<aula>.<exercício>`).
  static Key open(String lessonId, String exerciseId) =>
      Key('exercise.open.$lessonId.$exerciseId');
}
