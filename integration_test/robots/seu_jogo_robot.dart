import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/frentes/treinador_seu_jogo_routes.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/core/keys/treinador_seu_jogo_keys.dart';
import 'package:patrol/patrol.dart';

import 'app_robot.dart';
import 'variant.dart';

/// A aba Seu jogo do Treinador de partidas (T87) e as telas que saem dela.
class SeuJogoRobot {
  const SeuJogoRobot(this.$);

  final PatrolIntegrationTester $;

  /// Abre a aba em tela própria. A entrada pelo casco do Treinador é da
  /// frente app-análise; aqui a rota vai direto.
  Future<void> open() async {
    final context = $.tester.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(context).push(SeuJogoPaths.seuJogo));
    await $(SeuJogoKeys.aba).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> expectResumo() async {
    await $(SeuJogoKeys.numeros).waitUntilVisible();
    await $(SeuJogoKeys.foco).waitUntilVisible();
  }

  /// A linha "Últimas N partidas do Lichess" debaixo dos ritmos.
  void expectBase(String texto) {
    final base = $(SeuJogoKeys.base).evaluate().single.widget as Text;
    expectText(base.data, texto);
  }

  /// [wire] = `blitz`, `rapida`, `bullet` ou `todos`.
  Future<void> escolherRitmo(String wire) async {
    await $(SeuJogoKeys.ritmo(wire)).tap();
    await $.pumpAndSettle();
  }

  Future<void> abrirTeoriaPeloFoco() async {
    await $(SeuJogoKeys.focoVer).scrollTo().tap();
    await $(SeuJogoKeys.teoriaScreen).waitUntilVisible();
  }

  Future<void> escolherCandidato(String san) async {
    await $(SeuJogoKeys.teoriaCandidato(san)).scrollTo().tap();
    await $(SeuJogoKeys.teoriaLinha).waitUntilVisible();
  }

  Future<void> abrirModelos() async {
    await $(SeuJogoKeys.teoriaModelos).scrollTo().tap();
    await $(SeuJogoKeys.modelosScreen).waitUntilVisible();
  }

  Future<void> ligarAvisoModelos() async {
    await $(SeuJogoKeys.modelosAviso).tap();
    await $.pumpAndSettle();
  }

  Future<void> expectModelo(int i) async {
    // O texto do modelo, não a coluna: sem link, o centro da coluna cai ao
    // lado do título curto e o Patrol não a conta como visível. A rolagem é
    // a da tela das partidas-modelo (a teoria embaixo também rola).
    final texto = find
        .descendant(
          of: find.byKey(SeuJogoKeys.modelo(i)),
          matching: find.byType(Text),
        )
        .first;
    await $(texto).scrollTo(
      view: find
          .descendant(
            of: find.byKey(SeuJogoKeys.modelosScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }

  /// O link do foco para o curso: sem o curso, a abertura no Pilares; com
  /// ele, as Metas de hoje.
  Future<void> abrirCursoPeloFoco() async {
    await $(SeuJogoKeys.focoCurso).scrollTo().tap();
    await $.pumpAndSettle();
  }

  Future<void> expectPilaresTravado() async {
    await $(SeuJogoKeys.pilaresScreen).waitUntilVisible();
    await $(SeuJogoKeys.pilaresDestaque).waitUntilVisible();
    await $(SeuJogoKeys.pilaresOferta).scrollTo();
  }

  Future<void> conhecerOPilares() async {
    await $(SeuJogoKeys.pilaresConhecer).scrollTo().tap();
    await $(PurchaseKeys.planSaleScreen).waitUntilVisible();
  }

  Future<void> expectMetasComDestaque() async {
    await $(SeuJogoKeys.metasDestaque).waitUntilVisible();
    await $(SeuJogoKeys.metasDestaqueParte).waitUntilVisible();
  }

  /// A seta da AppBar e a tela de baixo de volta.
  /// [seta]: a key da seta quando a tela tem a própria (o guia do curso).
  Future<void> voltarPelaSeta(Key telaDeBaixo, {Key? seta}) async {
    await (seta == null ? $(BackButton) : $(seta)).tap();
    await $(telaDeBaixo).waitUntilVisible();
  }

  /// O Voltar do sistema (só no primeiro caso do arquivo: ver a skill).
  Future<void> voltarPeloSistema(Key telaDeBaixo) async {
    await $.platform.android.pressBack();
    await $(telaDeBaixo).waitUntilVisible();
  }

  /// Rola a aba até o fim, conferindo a cada tela que nenhum texto ficou
  /// cortado (dados reais: nomes de abertura e de adversário compridos).
  Future<void> rolarConferindoTexto(AppRobot app) async {
    final rolavel = find.byType(Scrollable).first;
    app.expectNoClippedText();
    for (var i = 0; i < 30; i++) {
      final pos = $.tester.state<ScrollableState>(rolavel).position;
      if (pos.pixels >= pos.maxScrollExtent) break;
      await $.tester.drag(rolavel, const Offset(0, -500));
      await $.pumpAndSettle();
      app.expectNoClippedText();
    }
  }
}
