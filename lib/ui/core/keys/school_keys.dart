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
  /// T60, modo exercício: a faixa do enunciado em cima, o cronômetro do
  /// passo e o rodapé das ações.
  static const prompt = Key('lesson.prompt');
  static const stepTimer = Key('lesson.step.timer');
  static const footer = Key('lesson.footer');

  /// O esmaecer de 24 dp no topo do rodapé (fundo sólido abaixo dele).
  static const footerFade = Key('lesson.footer.fade');

  /// O convite para jogar no Lichess e o botão que abre o site.
  static const lichessInvite = Key('lesson.lichessInvite');
  static const lichessButton = Key('lesson.lichessButton');

  /// O link do passo para a partida ou o estudo de onde vem a posição.
  static const referenceLink = Key('lesson.referenceLink');

  /// O confete do fim da aula.
  static const celebration = Key('lesson.celebration');

  /// Na formatura: o primeiro jogo com relógio e o que é o "+10".
  static const clockGameButton = Key('lesson.clockGame');
  static const clockHelp = Key('lesson.clockHelp');

  static const screen = Key('lesson.screen');
  static const missing = Key('lesson.missing');
  static const board = Key('lesson.board');
  static const speech = Key('lesson.speech');
  static const viktorSheet = Key('lesson.viktorSheet');
  static const scroll = Key('lesson.scroll');

  /// Volta ao passo anterior, para rever.
  static const backButton = Key('lesson.back');
  static const progress = Key('lesson.progress');
  static const stepCounter = Key('lesson.stepCounter');

  /// Sob o tabuleiro: o título da aula e o que fazer no passo.
  static const title = Key('lesson.title');
  static const guide = Key('lesson.guide');
  static const nextButton = Key('lesson.next');

  /// "Ver solução" do rodapé da explicação do erro (T65 §3).
  static const seeSolution = Key('lesson.seeSolution');

  /// O rodapé de duas linhas da Solução vista (T65 §4).
  static const solutionFooter = Key('lesson.solutionFooter');
  static const hintButton = Key('lesson.hint');

  /// T51: o passo de pensar, a demonstração e o fim de uma parte.
  static const appBarTitle = Key('lesson.appBar.title');
  static const appBarClose = Key('lesson.appBar.close');
  static const place = Key('lesson.appBar.place');
  static const thinkReset = Key('lesson.think.reset');
  static const moreHintButton = Key('lesson.think.moreHint');
  static const demoBack = Key('lesson.demo.back');
  static const demoForward = Key('lesson.demo.forward');
  static const demoRing = Key('lesson.demo.ring');
  static const variationStrip = Key('lesson.variation.strip');
  static const variationStripScroll = Key('lesson.variation.strip.scroll');
  static const variationStripList = Key('lesson.variation.strip.list');
  static const variationStripCurrent = Key('lesson.variation.strip.current');
  static const demoReplay = Key('lesson.demo.replay');
  static const demoPause = Key('lesson.demo.pause');

  /// T70: a linha de cima do rodapé da demo fora do roteiro, e os pontos
  /// "pensando" na folha do Viktor.
  static const demoBackToScript = Key('lesson.demo.backToScript');
  static const sheetTyping = Key('lesson.sheet.typing');
  static const engineErrorSnack = Key('lesson.engine.error');

  /// A variante citada na fala, lance a lance no tabuleiro.
  static const variationShow = Key('lesson.variation.show');
  static const variationExit = Key('lesson.variation.exit');
  static const variationBack = Key('lesson.variation.back');
  static const variationForward = Key('lesson.variation.forward');
  static const variationSheet = Key('lesson.variation.sheet');
  static const variationSheetClose = Key('lesson.variation.sheet.close');
  static Key variationMove(int ply) => Key('lesson.variation.move.$ply');
  static Key variationBranch(String id) => Key('lesson.variation.branch.$id');
  static Key variationBranchMove(String id, int ply) =>
      Key('lesson.variation.branch.$id.move.$ply');
  static Key variationResult(String id) =>
      Key('lesson.variation.branch.$id.result');

  /// O selo de linha errada: junto ao tabuleiro e nos controles.
  static const wrongLine = Key('lesson.wrongLine.board');
  static const wrongLineControls = Key('lesson.wrongLine.controls');

  /// Depois de um lance errado previsto: rever o ponto da lição.
  static const reviewPoint = Key('lesson.reviewPoint');
  static const partFinished = Key('lesson.part.finished');
  static const nextPartButton = Key('lesson.part.next');
  static const reviewPartButton = Key('lesson.part.review');
  static const closeSheet = Key('lesson.sheet.close');

  /// A folha da apresentação B (modal sobre o tabuleiro) e o X dela.
  static const presentation = Key('lesson.presentation');
  static const presentationClose = Key('lesson.presentation.close');
  static const marksToggle = Key('lesson.marks');

  /// Lances ocultos (T69): o botão do cabeçalho e o do canto da faixa.
  static const hiddenMovesToggle = Key('lesson.hiddenMoves');
  static const variationHiddenToggle = Key('lesson.variation.hiddenMoves');
  static Key variationHiddenBlock(int row) =>
      Key('lesson.variation.hidden.$row');
  static const variationHiddenComment = Key('lesson.variation.hidden.comment');
  static const partSummary = Key('lesson.part.summary');
  static const allPartsDone = Key('lesson.part.allDone');
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

  // --- T70: fluxo da lição (contrato `T70-estados-licao-contrato.md`) ---

  /// O "Ver resposta" do rodapé do erro (botão cheio).
  static const showAnswerButton = Key('lesson.branch.showAnswer');

  /// "Ver enunciado completo" / "Ocultar enunciado" (um link só).
  static const fullStatementLink = Key('lesson.fullStatement');

  /// Prático: "Voltar" (desfaz o par), "Continuar" (refaz / próxima parte).
  static const practiceBack = Key('lesson.practice.back');
  static const practiceContinue = Key('lesson.practice.continue');

  /// Convite: "Voltar" ao último passo de aprendizado.
  static const practiceInviteBack = Key('lesson.practice.inviteBack');
  static const practiceHintLead = Key('lesson.practice.hintLead');
  static Key alreadySeen(String uci) => Key('lesson.alreadySeen.$uci');
  static const lessonExitButton = Key('lesson.footer.exit');
  static const correctTitle = Key('lesson.correct.title');
  static Key failedAlternative(String uci) =>
      Key('lesson.failedAlternative.$uci');
  static const showAnswerLink = Key('lesson.showAnswer');
  static const fullExplanationLink = Key('lesson.fullExplanation');
  static const yourTurnLine = Key('lesson.sheet.yourTurn');
  static const wrongMoveNotice = Key('lesson.wrongMove.notice');
  static const practiceInvite = Key('lesson.practice.invite');
  static const practiceButton = Key('lesson.practice.start');
  static const practiceSpeech = Key('lesson.practice.speech');
  static const practiceBoard = Key('lesson.practice.board');
  static const practiceViktor = Key('lesson.practice.viktor');
  static const practiceTyping = Key('lesson.practice.typing');
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
  static const backButton = Key('starChallenge.back');

  /// Um desafio na lista (`<peça>.<nível>`).
  static Key challenge(String piece, String level) =>
      Key('starChallenges.$piece.$level');

  /// A estrela a pegar, na casa dela.
  static Key star(String square) => Key('starChallenge.star.$square');
}
