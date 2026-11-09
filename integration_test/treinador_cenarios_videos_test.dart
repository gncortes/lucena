// T87 A10 · Um MP4 por entrada do fluxo da análise (docs/fluxos/treinador-analise.md,
// tabela "Por onde se chega"), com o fake. Coletor no ar antes (porta 8794) e:
// bash "tools/t87 prints treinador.sh" <checkout> <emulador> <log> integration_test/treinador_cenarios_videos_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/treinador_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_course_grants.dart';
import '../testing/fakes/fake_push_repository.dart';
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

/// Pausa sem `pumpAndSettle`: a barra da espera corre sem fim.
Future<void> _pausa(PatrolIntegrationTester $, [int ms = 1200]) async {
  for (var t = 0; t < ms; t += 100) {
    await $.pump(const Duration(milliseconds: 100));
  }
}

/// Rola a espera até o "Como funciona" e volta, devagar, para o vídeo.
Future<void> _mostrarEspera(PatrolIntegrationTester $) async {
  await _pausa($, 2500);
  final rolaveis = find
      .descendant(
        of: find.byKey(TreinadorKeys.carregando).first,
        matching: find.byType(Scrollable),
        matchRoot: true,
      )
      .evaluate();
  for (final e in rolaveis) {
    final estado = (e as StatefulElement).state;
    if (estado is ScrollableState &&
        estado.position.axis == Axis.vertical &&
        estado.position.maxScrollExtent > 0) {
      final pos = estado.position;
      await pos.animateTo(
        pos.maxScrollExtent,
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeInOut,
      );
      await _pausa($, 3000);
      await pos.animateTo(
        0,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
      break;
    }
  }
  await _pausa($, 1500);
}

/// Da abertura pronta aos exercícios (um erro, tentar de novo), ao fim e à
/// análise completa no lance do 1º exercício.
Future<void> _daAberturaAAnalise(
  PatrolIntegrationTester $,
  TreinadorRobot t,
) async {
  await $(TreinadorKeys.comecar).tap();
  await t.esperarExercicio();
  await _pausa($, 1000);
  await t.errar();
  await $(TreinadorKeys.tentarDeNovo).waitUntilVisible();
  await _pausa($, 1200);
  await $(TreinadorKeys.tentarDeNovo).tap();
  await $.pumpAndSettle();
  await t.acertar();
  await $(TreinadorKeys.proximo).waitUntilVisible();
  await _pausa($, 1000);
  await $(TreinadorKeys.proximo).tap();
  await $.pumpAndSettle();
  for (var i = 0; i < 3; i++) {
    await t.acertarEAvancar();
  }
  await $(TreinadorKeys.fim).waitUntilVisible();
  await _pausa($, 2500);
  await $(TreinadorKeys.fimAnalise).scrollTo().tap();
  await $(TreinadorKeys.analise).waitUntilVisible();
  await $.pumpAndSettle();
  await _pausa($, 2000);
  await $(GameDetailsKeys.tabMoves).tap();
  await $.pumpAndSettle();
  await _pausa($, 1500);
}

void main() {
  patrolTest('E1 aviso: a análise ficou pronta e o toque abre a partida', (
    $,
  ) async {
    final app = AppRobot($);
    final t = TreinadorRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeTreinadorRepository.comDados();
    final push = FakePushRepository(granted: true, allowed: true);
    t.concluir(fake, _nova);
    await app.open(
      systemLocale: const Locale('pt'),
      treinador: fake,
      courseGrants: _assinante(),
      push: push,
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await shot.begin('E1-aviso-abre-a-partida');
    await _pausa($, 1500);
    push.open(Uri.parse('/treinador/partida/$_nova'));
    await $(TreinadorKeys.inicio).waitUntilVisible();
    await $.pumpAndSettle();
    await _pausa($, 2500);
    await _daAberturaAAnalise($, t);
    await shot.end('E1-aviso-abre-a-partida', ready: TreinadorKeys.analise);
  });

  patrolTest('E1b aviso com a partida ainda analisando: espera e fica pronta', (
    $,
  ) async {
    final app = AppRobot($);
    final t = TreinadorRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeTreinadorRepository.comDados();
    final push = FakePushRepository(granted: true, allowed: true);
    await app.open(
      systemLocale: const Locale('pt'),
      treinador: fake,
      courseGrants: _assinante(),
      push: push,
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await shot.begin('E1b-aviso-partida-analisando');
    await _pausa($, 1500);
    push.open(Uri.parse('/treinador/partida/$_analisando'));
    await t.esperarCarregando();
    await _mostrarEspera($);
    t.concluir(fake, _analisando);
    await $(TreinadorKeys.inicio).waitUntilVisible();
    await $.pumpAndSettle();
    await _pausa($, 2500);
    await shot.end('E1b-aviso-partida-analisando', ready: TreinadorKeys.inicio);
  });

  patrolTest('E2 Home, atalho Análise: abre a última partida', ($) async {
    final app = AppRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeTreinadorRepository.comDados();
    await app.open(
      systemLocale: const Locale('pt'),
      treinador: fake,
      courseGrants: _assinante(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await shot.begin('E2-home-atalho-analise');
    await _pausa($, 1500);
    await $(HomeKeys.analysisButton).scrollTo().tap();
    await $(TreinadorKeys.back).waitUntilVisible();
    await _pausa($, 3000);
    await shot.end('E2-home-atalho-analise', ready: TreinadorKeys.back);
  });

  patrolTest('E3 Home, atalho Análise sem plano: aba Hoje', ($) async {
    final app = AppRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeTreinadorRepository.comDados();
    await app.open(systemLocale: const Locale('pt'), treinador: fake);
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await shot.begin('E3-home-atalho-sem-plano');
    await _pausa($, 1500);
    await $(HomeKeys.analysisButton).scrollTo().tap();
    await $(TreinadorKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
    await _pausa($, 2500);
    await shot.end('E3-home-atalho-sem-plano', ready: TreinadorKeys.screen);
  });

  patrolTest(
    'E4 E6 E7 lista → partida nova → espera → pronta → exercícios → análise',
    ($) async {
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
      await shot.begin('E4-partida-nova-ate-analise');
      await _pausa($, 1000);
      await $(TreinadorKeys.partida(_nova)).scrollTo();
      await $.tester.tap(find.byKey(TreinadorKeys.partida(_nova)));
      await t.esperarCarregando();
      await _mostrarEspera($);
      t.concluir(fake, _nova);
      await $(TreinadorKeys.inicio).waitUntilVisible();
      await $.pumpAndSettle();
      await _pausa($, 2500);
      await _daAberturaAAnalise($, t);
      await shot.end(
        'E4-partida-nova-ate-analise',
        ready: TreinadorKeys.analise,
      );

      // E8 · a partida já feita abre o resumo.
      bool naTela(Key k) => find.byKey(k).hitTestable().evaluate().isNotEmpty;
      for (var i = 0; i < 5 && !naTela(TreinadorKeys.partidas); i++) {
        if (naTela(TreinadorKeys.hoje)) {
          await t.aba(TreinadorKeys.tabPartidas);
          break;
        }
        await $.platform.android.pressBack();
        await $.pumpAndSettle();
      }
      await shot.begin('E8-partida-feita-resumo');
      await _pausa($, 1000);
      await t.abrirPartida(_nova);
      await _pausa($, 2500);
      await shot.end('E8-partida-feita-resumo', ready: TreinadorKeys.resumo);
    },
  );

  patrolTest('C8 saiu no meio: Continuar (n de N)', ($) async {
    final app = AppRobot($);
    final t = TreinadorRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeTreinadorRepository.comDados();
    t.concluir(fake, _nova);
    await app.open(
      systemLocale: const Locale('pt'),
      treinador: fake,
      courseGrants: _assinante(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await t.abrirPelaHome();
    await t.aba(TreinadorKeys.tabPartidas);
    await shot.begin('C8-continuar');
    await t.abrirPartida(_nova);
    await _pausa($, 1500);
    await $(TreinadorKeys.comecar).tap();
    await t.esperarExercicio();
    await t.acertarEAvancar();
    await _pausa($, 1200);
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    await _pausa($, 1000);
    if (find.byKey(TreinadorKeys.inicio).evaluate().isEmpty) {
      await t.abrirPartida(_nova);
    }
    await _pausa($, 2500);
    await shot.end('C8-continuar', ready: TreinadorKeys.inicio);
  });

  patrolTest('E5 partida nova sem plano: Começar a análise', ($) async {
    final app = AppRobot($);
    final t = TreinadorRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeTreinadorRepository.comDados();
    await app.open(systemLocale: const Locale('pt'), treinador: fake);
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await t.abrirPelaHome();
    await t.aba(TreinadorKeys.tabPartidas);
    await shot.begin('E5-sem-plano-comecar');
    await t.abrirPartida(_nova);
    await _pausa($, 2000);
    await $(TreinadorKeys.comecar).tap();
    await t.esperarCarregando();
    await _mostrarEspera($);
    await shot.end('E5-sem-plano-comecar', ready: TreinadorKeys.carregando);
  });

  patrolTest('C10 grátis no limite: Começar a análise vai à compra', ($) async {
    final app = AppRobot($);
    final t = TreinadorRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeTreinadorRepository.comDados()
      ..falhaAnalisar = 'permission-denied'
      ..motivoAnalisar = 'cota';
    await app.open(systemLocale: const Locale('pt'), treinador: fake);
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await t.abrirPelaHome();
    await t.aba(TreinadorKeys.tabPartidas);
    await shot.begin('C10-cota-compra');
    await t.abrirPartida(_nova);
    await _pausa($, 2000);
    await $(TreinadorKeys.comecar).tap();
    await _pausa($, 3000);
    await shot.end('C10-cota-compra');
  });

  patrolTest('C11 espera → Me avise: volta à lista', ($) async {
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
    await shot.begin('C11-me-avise');
    await $(TreinadorKeys.partida(_fila)).scrollTo();
    await $.tester.tap(find.byKey(TreinadorKeys.partida(_fila)));
    await t.esperarCarregando();
    await _pausa($, 2500);
    await $.tester.tap(find.byKey(TreinadorKeys.meAvise));
    await _pausa($, 3000);
    await shot.end('C11-me-avise', ready: TreinadorKeys.screen);
  });

  patrolTest('C9 erro da análise: Tentar de novo', ($) async {
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
    await shot.begin('C9-erro-tentar');
    await t.abrirPartida(_analisando);
    await _pausa($, 2500);
    await $(TreinadorKeys.erroTentar).tap();
    await _pausa($, 3000);
    await shot.end('C9-erro-tentar', ready: TreinadorKeys.back);
  });
}
