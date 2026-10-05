import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/pace_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:patrol/patrol.dart';

import 'variant.dart';

/// Telas do speedrun: lista, speedrun, tentativa e o fim dela.
class SpeedrunRobot {
  const SpeedrunRobot(this.$);

  final PatrolIntegrationTester $;

  /// A partir da tela inicial.
  Future<void> open() async {
    await $(HomeKeys.speedrunButton).scrollTo().tap();
    await $(SpeedrunKeys.listScreen).waitUntilVisible();
  }

  /// Troca o ritmo da lista pelo painel (`180+2` é o 3+2).
  Future<void> choosePace(String code) async {
    await $(SpeedrunKeys.pace).tap();
    await $(PaceKeys.option(code)).waitUntilVisible();
    await $(PaceKeys.option(code)).tap();
    await $(PaceKeys.confirm).tap();
    await $.pumpAndSettle();
  }

  /// O speedrun [id] está na lista (no ritmo dela).
  Future<void> expectItem(String id) async {
    await $(SpeedrunKeys.item(id)).scrollTo();
  }

  Future<void> openSpeedrun(String id) async {
    await $(SpeedrunKeys.item(id)).scrollTo().tap();
    await $(SpeedrunKeys.screen).waitUntilVisible();
  }

  /// "Começar": a tentativa abre.
  Future<void> start() async {
    await $(SpeedrunKeys.start).waitUntilExists();
    await $(SpeedrunKeys.start).tap();
    // O painel do ritmo abre com o último escolhido marcado.
    await $(PaceKeys.confirm).waitUntilVisible();
    await $(PaceKeys.confirm).tap();
    await $(SpeedrunKeys.attemptScreen).waitUntilVisible();
    await $(SpeedrunKeys.total).waitUntilVisible();
  }

  /// O botão da etapa da vez: a partida abre no tabuleiro.
  Future<void> playStage() async {
    await $(SpeedrunKeys.play).scrollTo().tap();
    await $(FreeBoardKeys.board).waitUntilVisible();
  }

  /// No fim da partida da etapa, volta para a tentativa.
  Future<void> continueAfterGame() async {
    await $(FreeBoardKeys.endNewGameButton).tap();
    await $(SpeedrunKeys.attemptScreen).waitUntilVisible();
    await $(SpeedrunKeys.total).waitUntilVisible();
  }

  Future<void> back() async {
    await $(BackButton).tap();
    await $.pumpAndSettle();
  }

  /// Na tentativa: desiste dela pelo menu, confirmando.
  Future<void> abandon() async {
    await $(SpeedrunKeys.menu).tap();
    await $(SpeedrunKeys.abandon).tap();
    await $(SpeedrunKeys.abandonConfirm).tap();
    await $(SpeedrunKeys.abandoned).waitUntilVisible();
  }

  /// Na tela do speedrun: o texto da tentativa [index] do histórico (0 é a
  /// mais recente).
  Future<void> expectHistory(int index, String text) async {
    await $(SpeedrunKeys.run(index)).scrollTo();
    expectTextIn(find.byKey(SpeedrunKeys.run(index)), text);
  }

  /// Na tela do speedrun, sem tentativa em andamento: "Começar".
  Future<void> expectCanStart() async {
    await $(SpeedrunKeys.start).waitUntilExists();
    expect(find.byKey(SpeedrunKeys.resume), findsNothing);
  }

  void expectTotal(String time) {
    expect(_text(SpeedrunKeys.total), time);
  }

  void expectStageTime(int stage, String time) {
    expect(_text(SpeedrunKeys.stageTime(stage)), time);
  }

  void expectStageLosses(int stage, String text) {
    expectText(_text(SpeedrunKeys.stageLosses(stage)), text);
  }

  void expectPlayButton(String text) {
    expectTextIn(find.byKey(SpeedrunKeys.play), text);
  }

  Future<void> expectNewRecord({required bool record}) async {
    if (record) {
      await $(SpeedrunKeys.newRecord).waitUntilVisible();
    } else {
      expect(find.byKey(SpeedrunKeys.newRecord), findsNothing);
    }
    expect(find.byKey(SpeedrunKeys.play), findsNothing);
  }

  void expectRecordDifference(String text) {
    expectText(_text(SpeedrunKeys.recordDifference), text);
  }

  /// O melhor tempo na tela do speedrun (relida do banco ao voltar para ela).
  Future<void> expectBest(String time) async {
    await _waitForText(SpeedrunKeys.best, time);
    expect(_text(SpeedrunKeys.best), time);
  }

  /// O melhor tempo de uma etapa (por adversário), na tela do speedrun.
  Future<void> expectStageRecord(int stage, String time) async {
    await $(SpeedrunKeys.stageRecord(stage)).scrollTo();
    expect(_text(SpeedrunKeys.stageRecord(stage)), time);
  }

  Future<void> expectItemBest(String id, String time) async {
    await _waitForText(SpeedrunKeys.itemBest(id), time);
    expect(_text(SpeedrunKeys.itemBest(id)), time);
  }

  // A tela relê o banco ao voltar a aparecer: espera o texto chegar.
  Future<void> _waitForText(Key key, String text) async {
    for (var i = 0; i < 50 && _text(key) != text; i++) {
      await $.pump(const Duration(milliseconds: 100));
    }
  }

  String? _text(Key key) => $.tester.widget<Text>(find.byKey(key)).data;
}
