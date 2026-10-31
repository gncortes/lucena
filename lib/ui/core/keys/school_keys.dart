import 'package:flutter/widgets.dart';

abstract final class SchoolKeys {
  /// O teste de nível (T52): a entrada e o grupo das aulas dispensadas.
  static const placementTest = Key('school.placementTest');
  static const skippedGroup = Key('school.skippedGroup');
  static const reviewSkipped = Key('school.reviewSkipped');
  static Key skippedLesson(String id) => Key('school.skippedLesson.$id');

  static const screen = Key('school.screen');
  static const scroll = Key('school.scroll');
  static const continueButton = Key('school.continue');
  static const endgamesButton = Key('school.endgames');
  static const challengesButton = Key('school.challenges');

  /// Uma aula na trilha.
  static Key lesson(String id) => Key('school.lesson.$id');

  /// Um módulo na trilha.
  static Key module(String id) => Key('school.module.$id');
}

/// As chaves que sobraram da lição antiga: a faixa de variantes
/// (`variation_strip.dart`, usada pelo exercício e pela lista de lances).
abstract final class LessonKeys {
  static const variationStripList = Key('lesson.variation.strip.list');
  static const variationStripCurrent = Key('lesson.variation.strip.current');

  /// Os pontos "pensando" na folha do Viktor.
  static const sheetTyping = Key('lesson.sheet.typing');

  /// A variante citada na fala, lance a lance no tabuleiro.
  static Key variationMove(int ply) => Key('lesson.variation.move.$ply');
  static Key variationBranch(String id) => Key('lesson.variation.branch.$id');
  static Key variationBranchMove(String id, int ply) =>
      Key('lesson.variation.branch.$id.move.$ply');
  static Key variationResult(String id) =>
      Key('lesson.variation.branch.$id.result');

  /// Lances ocultos (T69): o botão do canto da faixa e os blocos.
  static const variationHiddenToggle = Key('lesson.variation.hiddenMoves');
  static Key variationHiddenBlock(int row) =>
      Key('lesson.variation.hidden.$row');
  static const variationHiddenComment = Key('lesson.variation.hidden.comment');
}

/// Os desafios das estrelas: a lista e um desafio.
abstract final class StarChallengeKeys {
  /// Às cegas: o nome da casa da estrela.
  static const starName = Key('starChallenge.starName');

  static const listScreen = Key('starChallenges.screen');
  static const screen = Key('starChallenge.screen');
  static const board = Key('starChallenge.board');

  /// O "Vai!" largo no rodapé, antes de começar.
  static const goButton = Key('starChallenge.go');

  /// O cartão do convite, sob o relógio, antes de começar.
  static const intro = Key('starChallenge.intro');
  static const obstacles = Key('starChallenge.obstacles');
  static const timer = Key('starChallenge.timer');

  /// O topo do bloco centrado: o relógio e o convite ou o resultado.
  static const blockTop = Key('starChallenge.blockTop');

  /// O total de pontos no painel embaixo do tabuleiro.
  static const collected = Key('starChallenge.collected');

  /// O painel de pontos embaixo do tabuleiro.
  static const scoreboard = Key('starChallenge.scoreboard');

  /// O nível e o modo no subtítulo da barra do app.
  static const levelChip = Key('starChallenge.levelChip');

  /// Quantas estrelas de uma cor (`bronze`, `silver`, `gold`) foram pegas.
  static Key kindCount(String kind) => Key('starChallenge.count.$kind');
  static const result = Key('starChallenge.result');
  static const earned = Key('starChallenge.earned');
  static const best = Key('starChallenge.best');

  /// O "Jogar de novo" no mesmo rodapé, no fim, no lugar do "Vai!".
  static const retryButton = Key('starChallenge.retry');
  static const saveProgress = Key('starChallenge.saveProgress');
  static const saveError = Key('starChallenge.saveError');
  static const retrySave = Key('starChallenge.retrySave');
  static const backButton = Key('starChallenge.back');

  /// Um desafio na lista (`<peça>.<nível>`).
  static Key challenge(String piece, String level) =>
      Key('starChallenges.$piece.$level');

  /// A estrela a pegar, na casa dela.
  static Key star(String square) => Key('starChallenge.star.$square');
}
