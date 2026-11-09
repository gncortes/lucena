// T87 · Prints da aba Seu jogo e das telas que saem dela, para o qa-telas
// (docs/qa/T87-app-seu-jogo/app). Coletor no ar antes:
// python3 tools/capture/t85_capture_server.py --serial emulator-5558
//   --output docs/qa/T87-app-seu-jogo --port 8796
// e o Patrol com --dart-define=E2E_CAPTURE_URL=http://10.0.2.2:8796.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/routing/frentes/treinador_seu_jogo_routes.dart';
import 'package:lucena/ui/core/keys/treinador_keys.dart';
import 'package:lucena/ui/core/keys/treinador_seu_jogo_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_treinador_repository.dart';
import '../testing/treinador_fixtures.dart';
import '../testing/treinador_seu_jogo_fixtures.dart';
import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/seu_jogo_robot.dart';
import 'robots/training_capture_robot.dart';

FakeTreinadorRepository _treinador() => FakeTreinadorRepository(
  conta: TreinadorFixtures.conta,
  partidas: SeuJogoFixtures.partidas(),
  estatisticas: SeuJogoFixtures.estatisticas(),
  modelosPorEco: {
    'B12': [
      const PartidaModelo(
        fonte: 'torneio',
        titulo: 'Silva x Moreira',
        subtitulo: 'Aberto de São Paulo 2024 · o mesmo 5...c5 que você jogou',
        url: 'https://lichess.org/study/exemplo1',
      ),
      const PartidaModelo(
        fonte: 'torneio',
        titulo: 'Costa x Pereira',
        subtitulo:
            'Torneio de Curitiba 2023 · as pretas jogam 5...c5 e trocam em d4',
        url: 'https://lichess.org/study/exemplo2',
      ),
    ],
  },
);

/// O servidor fora do ar: a lista de partidas não chega.
class _TreinadorComErro extends FakeTreinadorRepository {
  _TreinadorComErro() : super(conta: TreinadorFixtures.conta);

  @override
  Stream<List<PartidaTreinador>> partidas() =>
      Stream.error(StateError('sem servidor'));
}

/// A aba inteira, uma tela por print (rola até o fim).
Future<void> _abaInteira(PatrolIntegrationTester $, String nome) async {
  final shot = TrainingCaptureRobot($);
  final rolavel = find.byType(Scrollable).first;
  for (var i = 1; i <= 8; i++) {
    await shot.shot('$nome-$i', ready: SeuJogoKeys.aba);
    final pos = $.tester.state<ScrollableState>(rolavel).position;
    if (pos.pixels >= pos.maxScrollExtent) break;
    await $.tester.drag(rolavel, const Offset(0, -600));
    await $.pumpAndSettle();
  }
  // De volta ao alto: o scrollTo do Patrol só desce.
  $.tester.state<ScrollableState>(rolavel).position.jumpTo(0);
  await $.pumpAndSettle();
}

void main() {
  patrolTest('T87 prints: aba, teoria e partidas-modelo', ($) async {
    final app = AppRobot($);
    final seuJogo = SeuJogoRobot($);
    final shot = TrainingCaptureRobot($);
    await app.open(
      systemLocale: const Locale('pt'),
      treinador: _treinador(),
      trainingScenario: E2ETrainingScenario.large,
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await seuJogo.open();
    await seuJogo.expectResumo();
    await _abaInteira($, '01-aba');

    await seuJogo.abrirTeoriaPeloFoco();
    await shot.shot('02-teoria', ready: SeuJogoKeys.teoriaScreen);
    await seuJogo.escolherCandidato('Nd7');
    await shot.shot('03-teoria-linha', ready: SeuJogoKeys.teoriaScreen);
    await seuJogo.abrirModelos();
    await shot.shot('04-modelos', ready: SeuJogoKeys.modelosScreen);
    await seuJogo.voltarPelaSeta(SeuJogoKeys.teoriaScreen);
    await seuJogo.voltarPelaSeta(SeuJogoKeys.aba);

    await seuJogo.abrirCursoPeloFoco();
    await seuJogo.expectMetasComDestaque();
    await shot.shot('05-metas-destaque', ready: SeuJogoKeys.metasDestaque);
  });

  patrolTest('T87 prints: sem o curso, Pilares travado', ($) async {
    final app = AppRobot($);
    final seuJogo = SeuJogoRobot($);
    final shot = TrainingCaptureRobot($);
    await app.open(
      systemLocale: const Locale('pt'),
      demo: true,
      treinador: _treinador(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await seuJogo.open();
    await seuJogo.abrirCursoPeloFoco();
    await seuJogo.expectPilaresTravado();
    // As partes e a oferta cabem numa tela só (411×914).
    await $(SeuJogoKeys.pilaresConhecer).scrollTo();
    await shot.shot('06-pilares-oferta', ready: SeuJogoKeys.pilaresScreen);
  });

  patrolTest('T87 prints: estilo, tema e a posição abrindo a análise', (
    $,
  ) async {
    final app = AppRobot($);
    final seuJogo = SeuJogoRobot($);
    final shot = TrainingCaptureRobot($);
    await app.open(
      systemLocale: const Locale('pt'),
      demo: true,
      treinador: _treinador(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await seuJogo.open();
    await $(SeuJogoKeys.estilo).scrollTo().tap();
    await $(SeuJogoKeys.estiloScreen).waitUntilVisible();
    await shot.shot('08-estilo', ready: SeuJogoKeys.estiloScreen);
    await seuJogo.voltarPelaSeta(SeuJogoKeys.aba);

    await $(SeuJogoKeys.tema('garfo')).scrollTo().tap();
    await $(SeuJogoKeys.temaScreen).waitUntilVisible();
    await shot.shot('09-tema', ready: SeuJogoKeys.temaScreen);
    await shot.record(
      '10-tema-analise',
      () => $(SeuJogoKeys.temaPosicao(0)).tap(),
      ready: TreinadorKeys.analise,
    );
    await shot.shot('10-tema-analise', ready: TreinadorKeys.analise);
  });

  patrolTest('T87 prints: aba sem partidas', ($) async {
    final shot = TrainingCaptureRobot($);
    await AppRobot($).open(
      systemLocale: const Locale('pt'),
      demo: true,
      treinador: FakeTreinadorRepository(conta: TreinadorFixtures.conta),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    final context = $.tester.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(context).push(SeuJogoPaths.seuJogo));
    // O centro do vazio é espaço em branco: existe, mas não é "visível" para o Patrol.
    await $(SeuJogoKeys.vazio).waitUntilExists();
    await $.pumpAndSettle();
    await shot.shot('11-vazio', ready: SeuJogoKeys.screen);
  });

  patrolTest('T87 prints: aba com erro', ($) async {
    final shot = TrainingCaptureRobot($);
    await AppRobot($).open(
      systemLocale: const Locale('pt'),
      demo: true,
      treinador: _TreinadorComErro(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    final context = $.tester.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(context).push(SeuJogoPaths.seuJogo));
    await $(SeuJogoKeys.erro).waitUntilVisible();
    await shot.shot('12-erro', ready: SeuJogoKeys.erro);
  });
}
