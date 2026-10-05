import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/pace.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:patrol/patrol.dart';

import 'variant.dart';

/// Telas do speedrun: lista, speedrun, as etapas no tabuleiro e o resumo da
/// tentativa.
class SpeedrunRobot {
  const SpeedrunRobot(this.$);

  final PatrolIntegrationTester $;

  /// A partir da tela inicial.
  Future<void> open() async {
    await $(HomeKeys.speedrunButton).scrollTo().tap();
    await $(SpeedrunKeys.listScreen).waitUntilVisible();
  }

  /// Troca o ritmo no alto da lista (`180+2` é o 3+2): a categoria e o
  /// ritmo dela.
  Future<void> choosePace(String code) async {
    final time = TimeControl.tryParse(code)!;
    await $(SpeedrunKeys.paceCategory(PaceCategory.of(time).name))
        .scrollTo()
        .tap();
    await $(SpeedrunKeys.paceOption(code)).waitUntilVisible();
    await $(SpeedrunKeys.paceOption(code)).tap();
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

  /// "Começar": a primeira etapa abre direto no tabuleiro, no ritmo da
  /// lista.
  Future<void> start() async {
    await $(SpeedrunKeys.start).waitUntilExists();
    await $(SpeedrunKeys.start).tap();
    await $(FreeBoardKeys.board).waitUntilVisible();
  }

  /// Venceu a etapa e há outra: "Continuar" abre a próxima no lugar desta.
  Future<void> continueToNextStage() async {
    await $(FreeBoardKeys.endNewGameButton).tap();
    await $.pumpAndSettle();
    await $(FreeBoardKeys.board).waitUntilVisible();
  }

  /// Venceu a última etapa: "Continuar" abre o resumo da tentativa.
  Future<void> finishAttempt() async {
    await $(FreeBoardKeys.endNewGameButton).tap();
    await $(SpeedrunKeys.attemptScreen).waitUntilVisible();
    await $(SpeedrunKeys.total).waitUntilVisible();
  }

  /// Perdeu a etapa: "Tentar novamente" começa uma tentativa nova, da
  /// primeira etapa.
  Future<void> retry() async {
    await $(FreeBoardKeys.endNewGameButton).tap();
    await $.pumpAndSettle();
    await $(FreeBoardKeys.board).waitUntilVisible();
  }

  /// Sai da etapa no meio pelo voltar, confirmando: a tentativa termina e
  /// a tela do speedrun volta.
  Future<void> quit() async {
    await $(BackButton).tap();
    await $(FreeBoardKeys.speedrunQuitConfirm).waitUntilVisible();
    await $(FreeBoardKeys.speedrunQuitConfirm).tap();
    await $(SpeedrunKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> back() async {
    await $(BackButton).tap();
    await $.pumpAndSettle();
  }

  /// Na tela do speedrun: o texto da tentativa [index] do histórico (0 é a
  /// mais recente).
  Future<void> expectHistory(int index, String text) async {
    await $(SpeedrunKeys.run(index)).scrollTo();
    expectTextIn(find.byKey(SpeedrunKeys.run(index)), text);
  }

  /// Toca na tentativa [index] do histórico: abre os detalhes dela.
  Future<void> openHistory(int index) async {
    await $(SpeedrunKeys.run(index)).scrollTo().tap();
    await $(SpeedrunKeys.attemptScreen).waitUntilVisible();
  }

  /// Nos detalhes de uma tentativa abandonada: o aviso e o tempo da etapa.
  Future<void> expectAbandonedDetails({required String firstStage}) async {
    await $(SpeedrunKeys.abandoned).waitUntilVisible();
    await $(SpeedrunKeys.stageTime(0)).scrollTo();
    expectStageTime(0, firstStage);
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

  /// No resumo: o texto da etapa [stage] (o adversário, as derrotas).
  void expectStageText(int stage, String text) {
    expectTextIn(find.byKey(SpeedrunKeys.stage(stage)), text);
  }

  Future<void> expectNewRecord({required bool record}) async {
    if (record) {
      await $(SpeedrunKeys.newRecord).waitUntilVisible();
    } else {
      expect(find.byKey(SpeedrunKeys.newRecord), findsNothing);
    }
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

  // O texto na key, simples ou com partes (os tempos têm os décimos
  // menores).
  String? _text(Key key) {
    final text = $.tester.widget<Text>(find.byKey(key));
    return text.data ?? text.textSpan?.toPlainText();
  }
}
