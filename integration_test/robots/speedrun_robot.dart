import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/conclusion.dart';
import 'package:lucena/domain/models/pace.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/pace_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:patrol/patrol.dart';

import 'conclusion_robot.dart';
import 'free_board_robot.dart';
import 'home_robot.dart';
import 'variant.dart';

/// Telas do speedrun: lista, speedrun, as etapas no tabuleiro, a conclusão
/// de cada etapa e o resumo da tentativa.
class SpeedrunRobot {
  const SpeedrunRobot(this.$);

  final PatrolIntegrationTester $;

  /// A partir da tela inicial. Os cenários jogam no 5+3 ([pace]); nulo
  /// deixa a lista no ritmo em que ela abre (o escolhido ou o do nível).
  Future<void> open({String? pace = '300+3'}) async {
    await tapHomePath($, HomeKeys.speedrunButton);
    await $(SpeedrunKeys.listScreen).waitUntilVisible();
    if (pace != null) await choosePace(pace);
  }

  /// Marca o modo no alto da lista: a Maratona ou o clássico.
  Future<void> chooseMode({required bool marathon}) async {
    await $(SpeedrunKeys.modeOption(marathon ? 'marathon' : 'classic')).tap();
    await $.pumpAndSettle();
  }

  /// Na Maratona: a etapa [stage] abriu sozinha, sem nenhum botão nem
  /// conclusão no meio, e o versus dela já passou.
  Future<void> expectNextMarathonStage(int stage) async {
    await FreeBoardRobot($).waitStage(stage);
    await waitVersusGone();
    expect(find.byKey(ConclusionKeys.screen), findsNothing);
  }

  /// A entrada de versus da etapa saiu: dá para jogar.
  Future<void> waitVersusGone() async {
    for (
      var i = 0;
      i < 100 && find.byKey(FreeBoardKeys.marathonBanner).evaluate().isNotEmpty;
      i++
    ) {
      await $.pump(const Duration(milliseconds: 100));
    }
    await $(FreeBoardKeys.board).waitUntilVisible();
  }

  /// A Maratona terminou: a conclusão dela abriu sozinha, com o total.
  Future<void> expectMarathonSummary() async {
    final conclusion = ConclusionRobot($);
    await conclusion.expectTitle('Marathon completed!');
    await $(ConclusionKeys.total).scrollTo();
    await conclusion.expectAction(ConclusionAction.retry);
  }

  /// Troca o ritmo no alto da lista (`180+2` é o 3+2): a categoria e o
  /// ritmo dela.
  Future<void> choosePace(String code) async {
    final time = TimeControl.tryParse(code)!;
    // Quem está começando vê o ritmo numa linha só, que abre o seletor.
    if (find.byKey(SpeedrunKeys.compactPace).evaluate().isNotEmpty) {
      await $(SpeedrunKeys.compactPace).tap();
      await $(PaceKeys.option(code)).scrollTo().tap();
      await $(PaceKeys.confirm).tap();
      await $.pumpAndSettle();
      return;
    }
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

  /// Venceu a etapa e há outra: na conclusão da etapa, "Continuar" abre a
  /// próxima no lugar dela.
  Future<void> continueToNextStage() async {
    await ConclusionRobot($).tap(ConclusionAction.nextStage);
    await $(FreeBoardKeys.board).waitUntilVisible();
  }

  /// Venceu a última etapa: a conclusão do speedrun, com o tempo de cada
  /// etapa e o total.
  Future<void> finishAttempt() async {
    final conclusion = ConclusionRobot($);
    await conclusion.expectTitle('Speedrun complete');
    await conclusion.expectAction(ConclusionAction.speedruns);
    await $(ConclusionKeys.total).scrollTo();
  }

  /// Perdeu a etapa: na conclusão, "Tentar de novo" começa uma tentativa
  /// nova, da primeira etapa.
  Future<void> retry() async {
    await ConclusionRobot($).tap(ConclusionAction.retry);
    await FreeBoardRobot($).waitStage(0);
  }

  /// Na conclusão de uma etapa perdida: "Resumo" abre os tempos da
  /// tentativa.
  Future<void> openSummary() async {
    await ConclusionRobot($).tap(ConclusionAction.summary);
    await $(SpeedrunKeys.attemptScreen).waitUntilVisible();
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

  /// Volta uma tela. Na conclusão, pelo fechar: ela volta para a tela do
  /// speedrun (as etapas foram trocadas por ela).
  Future<void> back() async {
    if (find.byKey(ConclusionKeys.screen).evaluate().isNotEmpty) {
      await ConclusionRobot($).close();
      return;
    }
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
    await expectSummaryStageTime(0, firstStage);
  }

  /// No resumo da tentativa: o tempo da etapa [stage] (`0:03.0`).
  Future<void> expectSummaryStageTime(int stage, String time) async {
    await $(SpeedrunKeys.stageTime(stage)).scrollTo();
    expect(_text(SpeedrunKeys.stageTime(stage)), time);
  }

  /// Na tela do speedrun, sem tentativa em andamento: "Começar".
  Future<void> expectCanStart() async {
    await $(SpeedrunKeys.start).waitUntilExists();
    expect(find.byKey(SpeedrunKeys.resume), findsNothing);
  }

  /// Na conclusão do fim: o total da tentativa (`12.0 s`).
  Future<void> expectTotal(String time) => ConclusionRobot($).expectTotal(time);

  /// Na conclusão do fim: o tempo da etapa [stage] (0 é a primeira).
  Future<void> expectStageTime(int stage, String time) async {
    final times = await ConclusionRobot($).runTimes();
    expect(times[stage], time);
  }

  /// No resumo: o texto da etapa [stage] (o adversário, as derrotas).
  void expectStageText(int stage, String text) {
    expectTextIn(find.byKey(SpeedrunKeys.stage(stage)), text);
  }

  /// Na conclusão do fim: bateu ou não o recorde.
  Future<void> expectNewRecord({required bool record}) =>
      ConclusionRobot($).expectNewRecord(record: record);

  /// No resumo de uma tentativa: a diferença para o recorde de antes.
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
