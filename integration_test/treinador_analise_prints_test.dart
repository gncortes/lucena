// T87 · Prints e MP4 de todos os estados da análise de partidas, com o fake,
// para a prancha do Gabriel (docs/qa/T87-app-analise/app). Coletor no ar antes:
// python3 tools/t87_captura_5556.py docs/qa/T87-app-analise/app 8794
// e o Patrol: bash tools/t87_patrol.sh treinador_analise_prints CAPTURA=1.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/treinador_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_course_grants.dart';
import '../testing/fakes/fake_treinador_repository.dart';
import '../testing/treinador_fixtures.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';
import 'robots/treinador_robot.dart';

const _nova = 'lichess_DeF67890';
const _analisando = 'lichess_GhI13579';
const _fila = 'lichess_MnO11223';

FakeCourseGrantsRepository _assinante() => FakeCourseGrantsRepository()
  ..current = const CourseGrants(
    courses: {'treinador': CourseGrant(origin: GrantOrigin.gift)},
  );

/// A primeira lista vertical dentro de [tela] (nula se a tela não rola).
ScrollableState? _rolavel(PatrolIntegrationTester $, Key tela) {
  final todos = find
      .descendant(
        of: find.byKey(tela).first,
        matching: find.byType(Scrollable),
        matchRoot: true,
      )
      .evaluate();
  for (final e in todos) {
    final estado = (e as StatefulElement).state;
    if (estado is ScrollableState &&
        estado.position.axis == Axis.vertical &&
        estado.position.maxScrollExtent > 0) {
      return estado;
    }
  }
  return null;
}

/// A tela inteira, um print por altura, até o fim da rolagem.
Future<void> _rolando(PatrolIntegrationTester $, String nome, Key tela) async {
  final shot = TrainingCaptureRobot($);
  for (var i = 1; i <= 6; i++) {
    await shot.shot('$nome-$i', ready: tela);
    final pos = _rolavel($, tela)?.position;
    if (pos == null || pos.pixels >= pos.maxScrollExtent) break;
    pos.jumpTo((pos.pixels + 500).clamp(0, pos.maxScrollExtent));
    await $.pumpAndSettle();
  }
  _rolavel($, tela)?.position.jumpTo(0);
  await $.pumpAndSettle();
}

void main() {
  patrolTest('T87 prints: grátis, conectar a conta e Hoje sem plano', (
    $,
  ) async {
    final app = AppRobot($);
    final t = TreinadorRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeTreinadorRepository(partidas: TreinadorFixtures.lista());
    await app.open(systemLocale: const Locale('pt'), treinador: fake);
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await t.abrirPelaHome();
    await shot.shot('01-conectar-conta', ready: TreinadorKeys.ligarConta);
    await $(TreinadorKeys.ligarLichess).tap();
    await $.pumpAndSettle();
    await shot.shot('01b-conectar-usuario', ready: TreinadorKeys.usuario);
    fake.falhaLigar = FalhaLigarConta.naoExiste;
    await $(TreinadorKeys.usuario).enterText('ninguem_aqui');
    await $(TreinadorKeys.confirmarConta).tap();
    await $.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await $.pumpAndSettle();
    await shot.shot('01c-conectar-erro', ready: TreinadorKeys.contaErro);
    await $(TreinadorKeys.usuario).enterText('gabriel_lucena');
    await $(TreinadorKeys.confirmarConta).tap();
    await $.pumpAndSettle();
    await $(TreinadorKeys.semPlano).waitUntilVisible();
    await _rolando($, '03-hoje-sem-plano', TreinadorKeys.hoje);
  });

  patrolTest('T87 prints: assinante, da lista ao fim e ao resumo', ($) async {
    final app = AppRobot($);
    final t = TreinadorRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeTreinadorRepository.comDados();
    fake.porPartida(
      TreinadorFixtures.lista()
          .firstWhere((p) => p.id == _fila)
          .copyWith(status: StatusPartida.naFila),
    );
    await app.open(
      systemLocale: const Locale('pt'),
      treinador: fake,
      courseGrants: _assinante(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    // MP4 das animações padrão: a lista do Hoje em ordem e a troca de aba.
    await shot.begin('abas-e-listas');
    await t.abrirPelaHome();
    await $.pump(const Duration(milliseconds: 1500));
    await t.aba(TreinadorKeys.tabPartidas);
    await $.pump(const Duration(milliseconds: 1500));
    await t.aba(TreinadorKeys.tabHoje);
    await $.pump(const Duration(milliseconds: 1000));
    await shot.end('abas-e-listas', ready: TreinadorKeys.hoje);
    await _rolando($, '02-hoje-com-plano', TreinadorKeys.hoje);
    await t.aba(TreinadorKeys.tabPartidas);
    await _rolando($, '04-partidas', TreinadorKeys.partidas);

    // 6 · Analisando (com porcentagem) e 7 · Na fila (barra sem número).
    await t.abrirPartida(_analisando);
    await t.esperarCarregando();
    await shot.shot('06-analisando', ready: TreinadorKeys.carregando);
    await $(TreinadorKeys.back).tap();
    await $.pumpAndSettle();
    // Na fila a barra corre sem fim: só pump, nunca pumpAndSettle.
    await $(TreinadorKeys.partida(_fila)).scrollTo();
    await $.tester.tap(find.byKey(TreinadorKeys.partida(_fila)));
    for (var i = 0; i < 10; i++) {
      await $.pump(const Duration(milliseconds: 200));
    }
    await shot.shot('07-na-fila', ready: TreinadorKeys.carregando);
    await $.tester.tap(find.byKey(TreinadorKeys.back));
    for (var i = 0; i < 10; i++) {
      await $.pump(const Duration(milliseconds: 200));
    }

    // 5 · Partida nova e MP4 da análise até o fim dos exercícios.
    await shot.begin('analise-ate-fim');
    // A10 G2: com plano, a partida nova já pede a análise e abre a espera.
    await $(TreinadorKeys.partida(_nova)).scrollTo();
    await $.tester.tap(find.byKey(TreinadorKeys.partida(_nova)));
    await t.esperarCarregando();
    await $.pump(const Duration(seconds: 3));
    t.concluir(fake, _nova);
    await $(TreinadorKeys.inicio).waitUntilVisible();
    await $.pumpAndSettle();
    await shot.shot('05b-partida-pronta', ready: TreinadorKeys.inicio);
    await $(TreinadorKeys.comecar).tap();
    await t.esperarExercicio();
    await shot.shot('10-exercicio', ready: TreinadorKeys.exercicio);
    await t.errar();
    await $(TreinadorKeys.tentarDeNovo).waitUntilVisible();
    await $.pump(const Duration(milliseconds: 600));
    await shot.shot('11-exercicio-errou', ready: TreinadorKeys.exercicio);
    await $(TreinadorKeys.tentarDeNovo).tap();
    await $.pumpAndSettle();
    await t.acertar();
    await $(TreinadorKeys.proximo).waitUntilVisible();
    await $.pump(const Duration(milliseconds: 600));
    await shot.shot('11b-exercicio-acertou', ready: TreinadorKeys.exercicio);
    await $(TreinadorKeys.proximo).tap();
    await $.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await t.acertarEAvancar();
    }
    await $(TreinadorKeys.fim).waitUntilVisible();
    await $.pump(const Duration(seconds: 2));
    await shot.end('analise-ate-fim', ready: TreinadorKeys.fim);
    await _rolando($, '12-fim', TreinadorKeys.fim);

    // 9 · Resumo da partida já feita, rolado até o fim.
    await $(TreinadorKeys.fimAnalise).tap();
    await $(TreinadorKeys.analise).waitUntilVisible();
    await $.pumpAndSettle();
    await shot.shot('13-analise-completa', ready: TreinadorKeys.analise);
    await $(GameDetailsKeys.tabMoves).tap();
    await $.pumpAndSettle();
    await shot.shot('13a-analise-lances', ready: TreinadorKeys.analise);
    await $(GameDetailsKeys.tabEngine).tap();
    await $.pumpAndSettle();
    await shot.shot('13b-analise-motor', ready: TreinadorKeys.analise);
    // Volta até a lista de partidas (ou a Home, se a pilha acabar antes).
    bool naTela(Key k) => find.byKey(k).hitTestable().evaluate().isNotEmpty;
    for (var i = 0; i < 5; i++) {
      if (naTela(TreinadorKeys.partidas) ||
          naTela(TreinadorKeys.hoje) ||
          naTela(HomeKeys.screen)) {
        break;
      }
      await $.platform.android.pressBack();
      await $.pumpAndSettle();
    }
    if (naTela(TreinadorKeys.hoje)) {
      await t.aba(TreinadorKeys.tabPartidas);
    } else if (!naTela(TreinadorKeys.partidas)) {
      await t.abrirPelaHome();
      await t.aba(TreinadorKeys.tabPartidas);
    }
    await t.abrirPartida(_nova);
    await _rolando($, '09-resumo', TreinadorKeys.resumo);
  });

  // MP4 único do fluxo: Home → Análise → histórico com filtro → partida
  // nova → espera da análise → exercícios → fim → análise completa.
  patrolTest('T87 vídeo: fluxo inteiro', ($) async {
    final app = AppRobot($);
    final t = TreinadorRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeTreinadorRepository.comDados();
    await app.open(
      systemLocale: const Locale('pt'),
      treinador: fake,
      courseGrants: _assinante(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    Future<void> pausa([int ms = 1200]) => $.pump(Duration(milliseconds: ms));
    await shot.begin('fluxo-completo');
    await pausa(1000);
    await t.abrirPelaHome();
    await pausa(2000);
    await t.aba(TreinadorKeys.tabPartidas);
    await pausa(1500);
    await $(TreinadorKeys.filtroRitmo('blitz')).tap();
    await $.pumpAndSettle();
    await pausa(1500);
    await $(TreinadorKeys.filtroTodas).tap();
    await $.pumpAndSettle();
    await pausa(1000);
    await $(TreinadorKeys.partida(_nova)).scrollTo();
    await $.tester.tap(find.byKey(TreinadorKeys.partida(_nova)));
    await t.esperarCarregando();
    await pausa(4000);
    t.concluir(fake, _nova);
    await $(TreinadorKeys.inicio).waitUntilVisible();
    await $.pumpAndSettle();
    await pausa(1500);
    await $(TreinadorKeys.comecar).tap();
    await t.esperarExercicio();
    await pausa(1000);
    await t.errar();
    await $(TreinadorKeys.tentarDeNovo).waitUntilVisible();
    await pausa(1200);
    await $(TreinadorKeys.tentarDeNovo).tap();
    await $.pumpAndSettle();
    await t.acertar();
    await $(TreinadorKeys.proximo).waitUntilVisible();
    await pausa(1200);
    await $(TreinadorKeys.proximo).tap();
    await $.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await t.acertarEAvancar();
    }
    await $(TreinadorKeys.fim).waitUntilVisible();
    await pausa(2500);
    await $(TreinadorKeys.fimAnalise).tap();
    await $(TreinadorKeys.analise).waitUntilVisible();
    await $.pumpAndSettle();
    await pausa(1500);
    await $(GameDetailsKeys.tabMoves).tap();
    await $.pumpAndSettle();
    await pausa(1500);
    await $(GameDetailsKeys.tabEngine).tap();
    await $.pumpAndSettle();
    await pausa(1500);
    await shot.end('fluxo-completo', ready: TreinadorKeys.analise);
  });

  patrolTest('T87 prints: espera com frases e dica do exercício', ($) async {
    final app = AppRobot($);
    final t = TreinadorRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeTreinadorRepository.comDados();
    await app.open(
      systemLocale: const Locale('pt'),
      treinador: fake,
      courseGrants: _assinante(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await t.abrirPelaHome();
    await t.aba(TreinadorKeys.tabPartidas);
    await $(TreinadorKeys.partida(_nova)).scrollTo();
    await $.tester.tap(find.byKey(TreinadorKeys.partida(_nova)));
    await t.esperarCarregando();
    await shot.begin('espera-frases');
    for (var i = 0; i < 14; i++) {
      await app.advanceTime(const Duration(seconds: 1));
      await $.pump(const Duration(milliseconds: 700));
      if (i == 1 || i == 5 || i == 9) {
        await shot.shot('06c-espera-$i', ready: TreinadorKeys.carregando);
      }
    }
    await shot.end('espera-frases', ready: TreinadorKeys.carregando);
    t.concluir(fake, _nova);
    await $(TreinadorKeys.inicio).waitUntilVisible();
    await $.pumpAndSettle();
    await $(TreinadorKeys.comecar).tap();
    await t.esperarExercicio();
    await shot.begin('dica-sequencia');
    await shot.shot('10a-dica-antes', ready: TreinadorKeys.exercicio);
    await $(TreinadorKeys.dica).tap();
    await $.pumpAndSettle();
    await shot.shot('10b-dica-1', ready: TreinadorKeys.exercicio);
    await $(TreinadorKeys.dica).tap();
    await $.pumpAndSettle();
    await shot.shot('10c-dica-2', ready: TreinadorKeys.exercicio);
    await shot.end('dica-sequencia', ready: TreinadorKeys.exercicio);
  });

  patrolTest('T87 prints: erro da análise', ($) async {
    final app = AppRobot($);
    final t = TreinadorRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeTreinadorRepository.comDados();
    fake.porPartida(
      TreinadorFixtures.lista()
          .firstWhere((p) => p.id == _analisando)
          .copyWith(status: StatusPartida.erro),
    );
    await app.open(
      systemLocale: const Locale('pt'),
      treinador: fake,
      courseGrants: _assinante(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await t.abrirPelaHome();
    await t.aba(TreinadorKeys.tabPartidas);
    await t.abrirPartida(_analisando);
    await shot.shot('08-erro', ready: TreinadorKeys.erro);
  });
}
