import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/frentes/coach_your_game_routes.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/core/keys/coach_your_game_keys.dart';
import 'package:patrol/patrol.dart';

import 'app_robot.dart';
import 'variant.dart';

/// A aba Seu jogo do Treinador de partidas (T87) e as telas que saem dela.
class YourGameRobot {
  const YourGameRobot(this.$);

  final PatrolIntegrationTester $;

  /// Abre a aba em tela própria. A entrada pelo casco do Treinador é da
  /// frente app-análise; aqui a rota vai direto.
  Future<void> open() async {
    final context = $.tester.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(context).push(YourGamePaths.yourGame));
    await $(YourGameKeys.tab).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> expectSummary() async {
    await $(YourGameKeys.numbers).waitUntilVisible();
    await $(YourGameKeys.focus).waitUntilVisible();
  }

  /// A linha "Últimas N partidas do Lichess" debaixo dos ritmos.
  void expectBase(String text) {
    final base = $(YourGameKeys.base).evaluate().single.widget as Text;
    expectText(base.data, text);
  }

  /// [wire] = `blitz`, `rapida`, `bullet` ou `todos`.
  Future<void> pickTimeControl(String wire) async {
    await $(YourGameKeys.timeControl(wire)).tap();
    await $.pumpAndSettle();
  }

  Future<void> openTheoryFromFocus() async {
    await $(YourGameKeys.focusSee).scrollTo().tap();
    await $(YourGameKeys.theoryScreen).waitUntilVisible();
  }

  Future<void> pickCandidate(String san) async {
    await $(YourGameKeys.theoryCandidate(san)).scrollTo().tap();
    await $(YourGameKeys.theoryLine).waitUntilVisible();
  }

  Future<void> openModelGames() async {
    await $(YourGameKeys.theoryModelGames).scrollTo().tap();
    await $(YourGameKeys.modelGamesScreen).waitUntilVisible();
  }

  Future<void> enableModelGamesNotice() async {
    await $(YourGameKeys.modelGamesNoticeKey).tap();
    await $.pumpAndSettle();
  }

  Future<void> expectModelGame(int i) async {
    // O texto do modelo, não a coluna: sem link, o centro da coluna cai ao
    // lado do título curto e o Patrol não a conta como visível. A rolagem é
    // a da tela das partidas-modelo (a teoria embaixo também rola).
    final text = find
        .descendant(
          of: find.byKey(YourGameKeys.modelGame(i)),
          matching: find.byType(Text),
        )
        .first;
    await $(text).scrollTo(
      view: find
          .descendant(
            of: find.byKey(YourGameKeys.modelGamesScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }

  /// O link do foco para o curso: sem o curso, a abertura no Pilares; com
  /// ele, as Metas de hoje.
  Future<void> openCourseFromFocus() async {
    await $(YourGameKeys.focusCourse).scrollTo().tap();
    await $.pumpAndSettle();
  }

  Future<void> expectPilaresLocked() async {
    await $(YourGameKeys.pilaresScreen).waitUntilVisible();
    await $(YourGameKeys.pilaresHighlight).waitUntilVisible();
    await $(YourGameKeys.pilaresOffer).scrollTo();
  }

  Future<void> discoverPilares() async {
    await $(YourGameKeys.pilaresDiscover).scrollTo().tap();
    await $(PurchaseKeys.planSaleScreen).waitUntilVisible();
  }

  Future<void> expectGoalsWithHighlight() async {
    await $(YourGameKeys.goalsHighlight).waitUntilVisible();
    await $(YourGameKeys.goalsHighlightPart).waitUntilVisible();
  }

  /// A seta da AppBar e a tela de baixo de volta.
  /// [arrow]: a key da seta quando a tela tem a própria (o guia do curso).
  Future<void> backByArrow(Key screenBelow, {Key? arrow}) async {
    await (arrow == null ? $(BackButton) : $(arrow)).tap();
    await $(screenBelow).waitUntilVisible();
  }

  /// O Voltar do sistema (só no primeiro caso do arquivo: ver a skill).
  Future<void> backBySystem(Key screenBelow) async {
    await $.platform.android.pressBack();
    await $(screenBelow).waitUntilVisible();
  }

  /// Rola a aba até o fim, conferindo a cada tela que nenhum texto ficou
  /// cortado (dados reais: nomes de abertura e de adversário compridos).
  Future<void> scrollCheckingText(AppRobot app) async {
    final scrollableArea = find.byType(Scrollable).first;
    app.expectNoClippedText();
    for (var i = 0; i < 30; i++) {
      final pos = $.tester.state<ScrollableState>(scrollableArea).position;
      if (pos.pixels >= pos.maxScrollExtent) break;
      await $.tester.drag(scrollableArea, const Offset(0, -500));
      await $.pumpAndSettle();
      app.expectNoClippedText();
    }
  }
}
