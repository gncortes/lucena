import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/treinador_seu_jogo_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_treinador_repository.dart';
import '../testing/treinador_fixtures.dart';
import '../testing/treinador_seu_jogo_fixtures.dart';
import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/seu_jogo_robot.dart';

/// T87: a aba Seu jogo do Treinador de partidas e o que sai dela (teoria,
/// partidas-modelo, Pilares e Metas de hoje). As partidas vêm do fake: o
/// aparelho nunca fala com o Lichess.
FakeTreinadorRepository _treinador() => FakeTreinadorRepository(
  conta: TreinadorFixtures.conta,
  partidas: SeuJogoFixtures.partidas(),
  estatisticas: SeuJogoFixtures.estatisticas(),
  modelosPorEco: {
    'B12': [const PartidaModelo(fonte: 'torneio', titulo: 'Carlsen x Caruana')],
  },
);

void main() {
  patrolTest('o resumo e o ritmo escolhido voltam depois de fechar o app', (
    $,
  ) async {
    final app = AppRobot($);
    final seuJogo = SeuJogoRobot($);
    await app.open(systemLocale: const Locale('pt'), treinador: _treinador());
    await seuJogo.open();
    await seuJogo.expectResumo();
    seuJogo.expectBase('Últimas 60 partidas do Lichess');

    await seuJogo.escolherRitmo('blitz');
    seuJogo.expectBase('Últimas 20 partidas do Lichess');

    await app.restart();
    await seuJogo.open();
    seuJogo.expectBase('Últimas 20 partidas do Lichess');

    await seuJogo.abrirTeoriaPeloFoco();
    await seuJogo.voltarPeloSistema(SeuJogoKeys.aba);
  });

  patrolTest('do foco à teoria e às partidas-modelo, com segundo plano', (
    $,
  ) async {
    final app = AppRobot($);
    final seuJogo = SeuJogoRobot($);
    final treinador = _treinador();
    await app.open(systemLocale: const Locale('pt'), treinador: treinador);
    await seuJogo.open();
    await seuJogo.abrirTeoriaPeloFoco();
    await seuJogo.escolherCandidato('Nd7');

    await app.sendToBackgroundAndReturn();
    await $(SeuJogoKeys.teoriaLinha).waitUntilVisible();

    await seuJogo.abrirModelos();
    await seuJogo.expectModelo(0);
    await seuJogo.ligarAvisoModelos();
    expect(treinador.avisosModelos, [true]);

    await seuJogo.voltarPelaSeta(SeuJogoKeys.teoriaScreen);
    await seuJogo.voltarPelaSeta(SeuJogoKeys.aba);
  });

  patrolTest('sem o curso: o foco leva às partes travadas e à oferta', (
    $,
  ) async {
    final app = AppRobot($);
    final seuJogo = SeuJogoRobot($);
    await app.open(
      systemLocale: const Locale('pt'),
      demo: true,
      treinador: _treinador(),
    );
    await seuJogo.open();
    await seuJogo.abrirCursoPeloFoco();
    await seuJogo.expectPilaresTravado();
    await seuJogo.conhecerOPilares();

    await seuJogo.voltarPelaSeta(SeuJogoKeys.pilaresScreen);
    await seuJogo.voltarPelaSeta(SeuJogoKeys.aba);
  });

  patrolTest('com o curso: o foco leva às Metas de hoje com a parte', (
    $,
  ) async {
    final app = AppRobot($);
    final seuJogo = SeuJogoRobot($);
    // Com o plano já escolhido (sem plano, as Metas ainda não existem).
    await app.open(
      systemLocale: const Locale('pt'),
      treinador: _treinador(),
      trainingScenario: E2ETrainingScenario.large,
    );
    await seuJogo.open();
    await seuJogo.abrirCursoPeloFoco();
    await seuJogo.expectMetasComDestaque();
    await seuJogo.voltarPelaSeta(SeuJogoKeys.aba, seta: CourseGuideKeys.back);
  });
}
