import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/frentes/treinador_seu_jogo_routes.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/core/keys/treinador_seu_jogo_keys.dart';
import 'package:patrol/patrol.dart';

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
    await $(SeuJogoKeys.modelo(i)).scrollTo();
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
}
