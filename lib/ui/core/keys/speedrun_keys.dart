import 'package:flutter/widgets.dart';

abstract final class SpeedrunKeys {
  static const listScreen = Key('speedrun.list.screen');
  static const screen = Key('speedrun.screen');

  /// O cartão do bônus de rating: a oferta (antes de concluir) e o ganho.
  static const ratingBonusOffer = Key('speedrun.ratingBonus.offer');
  static const ratingBonusEarned = Key('speedrun.ratingBonus.earned');
  static const attemptScreen = Key('speedrun.attempt.screen');

  /// Um speedrun na lista e o recorde dele.
  static Key item(String id) => Key('speedrun.item.$id');
  static Key itemBest(String id) => Key('speedrun.item.$id.best');

  /// Uma tentativa em andamento, no alto da lista.
  static Key inProgress(String id) => Key('speedrun.inProgress.$id');

  /// O ritmo da lista e a explicação do speedrun.
  static const pace = Key('speedrun.pace');

  /// No alto da lista: a categoria do ritmo e cada ritmo dela (`180+2`).
  static Key paceCategory(String category) =>
      Key('speedrun.pace.category.$category');
  static Key paceOption(String code) => Key('speedrun.pace.option.$code');

  /// O ritmo numa linha (quem está começando) e a explicação do "15+10".
  static const compactPace = Key('speedrun.pace.compact');
  static const paceHelp = Key('speedrun.help.pace');

  /// A dificuldade dos finais: iniciante, intermediário ou avançado.
  static const category = Key('speedrun.category');
  static Key categoryOption(String category) =>
      Key('speedrun.category.$category');

  /// O modo da lista no alto: clássico ou Maratona.
  static const mode = Key('speedrun.mode');
  static Key modeOption(String mode) => Key('speedrun.mode.$mode');
  static const help = Key('speedrun.help');
  static const helpText = Key('speedrun.help.text');
  static const intro = Key('speedrun.intro');

  /// Na tela do speedrun: o ritmo e a etapa na grade.
  static const paceBadge = Key('speedrun.paceBadge');
  static Key stageCard(int index) => Key('speedrun.stage.$index');

  /// Na tentativa: a etapa da vez em destaque e o menu (desistir).
  static const current = Key('speedrun.attempt.current');
  static const menu = Key('speedrun.attempt.menu');

  /// O melhor tempo total e o melhor de cada etapa.
  static const best = Key('speedrun.best');

  /// No detalhe: o cartão do recorde, "Ver histórico", a linha "Melhor
  /// tentativa" (nunca concluiu) e o cartão da tentativa em andamento com a
  /// linha "+N ao concluir".
  static const recordCard = Key('speedrun.recordCard');
  static const seeHistory = Key('speedrun.seeHistory');
  static const bestAttempt = Key('speedrun.bestAttempt');
  static const ongoingCard = Key('speedrun.ongoingCard');
  static const ongoingOffer = Key('speedrun.ongoingOffer');

  static const start = Key('speedrun.start');
  static const resume = Key('speedrun.resume');

  /// Na tentativa: cada etapa e o tempo dela.
  static Key stage(int index) => Key('speedrun.attempt.stage.$index');
  static Key stageTime(int index) => Key('speedrun.attempt.stage.$index.time');
  static const total = Key('speedrun.attempt.total');
  static const play = Key('speedrun.attempt.play');
  static const abandon = Key('speedrun.attempt.abandon');
  static const abandonConfirm = Key('speedrun.attempt.abandon.confirm');
  static const abandoned = Key('speedrun.attempt.abandoned');

  /// No fim: o herói do recorde novo, a frase da diferença para o recorde,
  /// as barras de comparação e o aviso de que o bônus já foi pago.
  static const newRecord = Key('speedrun.attempt.newRecord');
  static const recordDifference = Key('speedrun.attempt.recordDifference');
  static const recordBars = Key('speedrun.attempt.recordBars');
  static const ratingAlreadyEarned = Key('speedrun.attempt.alreadyEarned');

  /// No fim sem concluir: o cartão do herói (qualquer falha), os títulos de
  /// perdeu e empatou (`abandoned` é o de desistiu), o tempo até parar, o
  /// aviso de que ainda não concluiu e a melhor etapa dele.
  static const abandonedHero = Key('speedrun.attempt.hero');
  static const lostTitle = Key('speedrun.attempt.lost');
  static const drawnTitle = Key('speedrun.attempt.drawn');
  static const timeUntil = Key('speedrun.attempt.timeUntil');
  static const notFinishedNotice = Key('speedrun.attempt.notFinished');
  static const bestReached = Key('speedrun.attempt.bestReached');

  /// No fim da Maratona: o herói (perdeu, empatou, sem tempo, desistiu), contra
  /// quem, o tempo que sobrou, o aviso de que ainda não concluiu, o cartão do
  /// recorde (maratona já concluída) e "Tentar novamente".
  static const marathonEndHero = Key('speedrun.marathon.end.hero');
  static const paceChip = Key('speedrun.pace.chip');
  static const marathonEndOpponent = Key('speedrun.marathon.end.opponent');
  static const marathonEndLeft = Key('speedrun.marathon.end.left');
  static const marathonNotFinished = Key('speedrun.marathon.notFinished');
  static const marathonRecord = Key('speedrun.marathon.record');
  static const retry = Key('speedrun.attempt.retry');

  /// A nota da etapa onde a tentativa parou ("perdeu aqui").
  static Key stageNote(int index) => Key('speedrun.attempt.stage.$index.note');

  /// O histórico de um speedrun: o recorde, as contagens, o mês, a tentativa
  /// e o "+N" da primeira conclusão.
  static const historyScreen = Key('speedrun.history.screen');
  static const historyRecord = Key('speedrun.history.record');

  /// "Em 12 de outubro, às 20:06", embaixo do recorde.
  static const historyRecordAt = Key('speedrun.history.recordAt');
  static const historyNotFinished = Key('speedrun.history.notFinished');
  static const historyAttempts = Key('speedrun.history.attempts');
  static const historyFinished = Key('speedrun.history.finished');
  static Key historyMonth(int index) =>
      Key('speedrun.history.screen.month.$index');
  static Key historyRun(int index) => Key('speedrun.history.screen.run.$index');
  static const historyBonus = Key('speedrun.history.bonus');
}
