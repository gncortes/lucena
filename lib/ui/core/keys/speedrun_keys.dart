import 'package:flutter/widgets.dart';

abstract final class SpeedrunKeys {
  static const listScreen = Key('speedrun.list.screen');
  static const screen = Key('speedrun.screen');
  static const attemptScreen = Key('speedrun.attempt.screen');

  /// Um speedrun na lista e o recorde dele.
  static Key item(String id) => Key('speedrun.item.$id');
  static Key itemBest(String id) => Key('speedrun.item.$id.best');

  /// Uma tentativa em andamento, no alto da lista.
  static Key inProgress(String id) => Key('speedrun.inProgress.$id');

  /// O ritmo da lista e a explicação do speedrun.
  static const pace = Key('speedrun.pace');
  static const help = Key('speedrun.help');
  static const helpText = Key('speedrun.help.text');
  static const intro = Key('speedrun.intro');

  /// Na tela do speedrun: o ritmo e a etapa na grade.
  static const paceBadge = Key('speedrun.paceBadge');
  static Key stageCard(int index) => Key('speedrun.stage.$index');

  /// O progresso por passos da tentativa em andamento.
  static const progress = Key('speedrun.progress');

  /// Na tentativa: a etapa da vez em destaque e o menu (desistir).
  static const current = Key('speedrun.attempt.current');
  static const menu = Key('speedrun.attempt.menu');

  /// O melhor tempo total e o melhor de cada etapa.
  static const best = Key('speedrun.best');
  static Key stageRecord(int index) => Key('speedrun.stage.$index.record');

  static const start = Key('speedrun.start');
  static const resume = Key('speedrun.resume');

  /// Na tentativa: cada etapa, o tempo dela e as derrotas.
  static Key stage(int index) => Key('speedrun.attempt.stage.$index');
  static Key stageTime(int index) => Key('speedrun.attempt.stage.$index.time');
  static Key stageLosses(int index) =>
      Key('speedrun.attempt.stage.$index.losses');
  static const total = Key('speedrun.attempt.total');
  static const play = Key('speedrun.attempt.play');
  static const abandon = Key('speedrun.attempt.abandon');
  static const abandonConfirm = Key('speedrun.attempt.abandon.confirm');
  static const abandoned = Key('speedrun.attempt.abandoned');

  /// No fim: "novo recorde pessoal" ou a diferença para o recorde.
  static const newRecord = Key('speedrun.attempt.newRecord');
  static const recordDifference = Key('speedrun.attempt.recordDifference');

  /// O histórico de tempos: o título de cada mês e cada tentativa concluída.
  static Key month(int index) => Key('speedrun.history.month.$index');
  static Key run(int index) => Key('speedrun.history.run.$index');
}
