// T87 A10 · Um MP4 por entrada do fluxo da análise (docs/fluxos/treinador-analise.md,
// tabela "Por onde se chega"), com o fake. Coletor no ar antes (porta 8794) e:
// bash "tools/t87 prints treinador.sh" <checkout> <emulador> <log> integration_test/coach_scenario_videos_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/coach_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_course_grants.dart';
import '../testing/fakes/fake_push_repository.dart';
import '../testing/fakes/fake_coach_repository.dart';
import '../testing/coach_fixtures.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';
import 'robots/coach_robot.dart';

const _new = 'lichess_DeF67890';
const _analyzing = 'lichess_GhI13579';
const _queue = 'lichess_MnO11223';

FakeCourseGrantsRepository _subscriber() => FakeCourseGrantsRepository()
  ..current = const CourseGrants(
    courses: {'treinador': CourseGrant(origin: GrantOrigin.gift)},
  );

/// Pausa sem `pumpAndSettle`: a barra da espera corre sem fim.
Future<void> _pause(PatrolIntegrationTester $, [int ms = 1200]) async {
  for (var t = 0; t < ms; t += 100) {
    await $.pump(const Duration(milliseconds: 100));
  }
}

/// Rola a espera até o "Como funciona" e volta, devagar, para o vídeo.
Future<void> _showWait(PatrolIntegrationTester $) async {
  await _pause($, 2500);
  final scrollables = find
      .descendant(
        of: find.byKey(CoachKeys.loading).first,
        matching: find.byType(Scrollable),
        matchRoot: true,
      )
      .evaluate();
  for (final e in scrollables) {
    final state = (e as StatefulElement).state;
    if (state is ScrollableState &&
        state.position.axis == Axis.vertical &&
        state.position.maxScrollExtent > 0) {
      final pos = state.position;
      await pos.animateTo(
        pos.maxScrollExtent,
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeInOut,
      );
      await _pause($, 3000);
      await pos.animateTo(
        0,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
      break;
    }
  }
  await _pause($, 1500);
}

/// Da abertura pronta aos exercícios (um erro, tentar de novo), ao fim e à
/// análise completa no lance do 1º exercício.
Future<void> _fromOpeningToAnalysis(
  PatrolIntegrationTester $,
  CoachRobot t,
) async {
  await $(CoachKeys.begin).tap();
  await t.waitExercise();
  await _pause($, 1000);
  await t.miss();
  await $(CoachKeys.retry).waitUntilVisible();
  await _pause($, 1200);
  await $(CoachKeys.retry).tap();
  await $.pumpAndSettle();
  await t.solve();
  await $(CoachKeys.next).waitUntilVisible();
  await _pause($, 1000);
  await $(CoachKeys.next).tap();
  await $.pumpAndSettle();
  for (var i = 0; i < 3; i++) {
    await t.solveAndAdvance();
  }
  await $(CoachKeys.end).waitUntilVisible();
  await _pause($, 2500);
  await $(CoachKeys.analysisEnd).scrollTo().tap();
  await $(CoachKeys.analysis).waitUntilVisible();
  await $.pumpAndSettle();
  await _pause($, 2000);
  await $(GameDetailsKeys.tabMoves).tap();
  await $.pumpAndSettle();
  await _pause($, 1500);
}

void main() {
  patrolTest('E1 aviso: a análise ficou pronta e o toque abre a partida', (
    $,
  ) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository.withData();
    final push = FakePushRepository(granted: true, allowed: true);
    t.finish(fake, _new);
    await app.open(
      systemLocale: const Locale('pt'),
      coach: fake,
      courseGrants: _subscriber(),
      push: push,
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await shot.begin('E1-aviso-abre-a-partida');
    await _pause($, 1500);
    push.open(Uri.parse('/treinador/partida/$_new'));
    await $(CoachKeys.start).waitUntilVisible();
    await $.pumpAndSettle();
    await _pause($, 2500);
    await _fromOpeningToAnalysis($, t);
    await shot.end('E1-aviso-abre-a-partida', ready: CoachKeys.analysis);
  });

  patrolTest('E1b aviso com a partida ainda analisando: espera e fica pronta', (
    $,
  ) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository.withData();
    final push = FakePushRepository(granted: true, allowed: true);
    await app.open(
      systemLocale: const Locale('pt'),
      coach: fake,
      courseGrants: _subscriber(),
      push: push,
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await shot.begin('E1b-aviso-partida-analisando');
    await _pause($, 1500);
    push.open(Uri.parse('/treinador/partida/$_analyzing'));
    await t.waitLoading();
    await _showWait($);
    t.finish(fake, _analyzing);
    await $(CoachKeys.start).waitUntilVisible();
    await $.pumpAndSettle();
    await _pause($, 2500);
    await shot.end('E1b-aviso-partida-analisando', ready: CoachKeys.start);
  });

  patrolTest('E2 Home, atalho Análise: abre a última partida', ($) async {
    final app = AppRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository.withData();
    await app.open(
      systemLocale: const Locale('pt'),
      coach: fake,
      courseGrants: _subscriber(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await shot.begin('E2-home-atalho-analise');
    await _pause($, 1500);
    await $(HomeKeys.analysisButton).scrollTo().tap();
    await $(CoachKeys.back).waitUntilVisible();
    await _pause($, 3000);
    await shot.end('E2-home-atalho-analise', ready: CoachKeys.back);
  });

  patrolTest('E3 Home, atalho Análise sem plano: aba Hoje', ($) async {
    final app = AppRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository.withData();
    await app.open(systemLocale: const Locale('pt'), coach: fake);
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await shot.begin('E3-home-atalho-sem-plano');
    await _pause($, 1500);
    await $(HomeKeys.analysisButton).scrollTo().tap();
    await $(CoachKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
    await _pause($, 2500);
    await shot.end('E3-home-atalho-sem-plano', ready: CoachKeys.screen);
  });

  patrolTest(
    'E4 E6 E7 lista → partida nova → espera → pronta → exercícios → análise',
    ($) async {
      final app = AppRobot($);
      final t = CoachRobot($);
      final shot = TrainingCaptureRobot($);
      final fake = FakeCoachRepository.withData();
      await app.open(
        systemLocale: const Locale('pt'),
        coach: fake,
        courseGrants: _subscriber(),
      );
      await TrainingCaptureRobot.semFaixaDoTeste($);
      await t.openFromHome();
      await t.tab(CoachKeys.tabGames);
      await shot.begin('E4-partida-nova-ate-analise');
      await _pause($, 1000);
      await $(CoachKeys.game(_new)).scrollTo();
      await $.tester.tap(find.byKey(CoachKeys.game(_new)));
      await t.waitLoading();
      await _showWait($);
      t.finish(fake, _new);
      await $(CoachKeys.start).waitUntilVisible();
      await $.pumpAndSettle();
      await _pause($, 2500);
      await _fromOpeningToAnalysis($, t);
      await shot.end('E4-partida-nova-ate-analise', ready: CoachKeys.analysis);

      // E8 · a partida já feita abre o resumo.
      bool onScreen(Key k) => find.byKey(k).hitTestable().evaluate().isNotEmpty;
      for (var i = 0; i < 5 && !onScreen(CoachKeys.games); i++) {
        if (onScreen(CoachKeys.today)) {
          await t.tab(CoachKeys.tabGames);
          break;
        }
        await $.platform.android.pressBack();
        await $.pumpAndSettle();
      }
      await shot.begin('E8-partida-feita-resumo');
      await _pause($, 1000);
      await t.openGame(_new);
      await _pause($, 2500);
      await shot.end('E8-partida-feita-resumo', ready: CoachKeys.summary);
    },
  );

  patrolTest('C8 saiu no meio: Continuar (n de N)', ($) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository.withData();
    t.finish(fake, _new);
    await app.open(
      systemLocale: const Locale('pt'),
      coach: fake,
      courseGrants: _subscriber(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await t.openFromHome();
    await t.tab(CoachKeys.tabGames);
    await shot.begin('C8-continuar');
    await t.openGame(_new);
    await _pause($, 1500);
    await $(CoachKeys.begin).tap();
    await t.waitExercise();
    await t.solveAndAdvance();
    await _pause($, 1200);
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    await _pause($, 1000);
    if (find.byKey(CoachKeys.start).evaluate().isEmpty) {
      await t.openGame(_new);
    }
    await _pause($, 2500);
    await shot.end('C8-continuar', ready: CoachKeys.start);
  });

  patrolTest('E5 partida nova sem plano: Começar a análise', ($) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository.withData();
    await app.open(systemLocale: const Locale('pt'), coach: fake);
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await t.openFromHome();
    await t.tab(CoachKeys.tabGames);
    await shot.begin('E5-sem-plano-comecar');
    await t.openGame(_new);
    await _pause($, 2000);
    await $(CoachKeys.begin).tap();
    await t.waitLoading();
    await _showWait($);
    await shot.end('E5-sem-plano-comecar', ready: CoachKeys.loading);
  });

  patrolTest('C10 grátis no limite: Começar a análise vai à compra', ($) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository.withData()
      ..analyzeFailure = 'permission-denied'
      ..analyzeReason = 'cota';
    await app.open(systemLocale: const Locale('pt'), coach: fake);
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await t.openFromHome();
    await t.tab(CoachKeys.tabGames);
    await shot.begin('C10-cota-compra');
    await t.openGame(_new);
    await _pause($, 2000);
    await $(CoachKeys.begin).tap();
    await _pause($, 3000);
    await shot.end('C10-cota-compra');
  });

  patrolTest('C11 espera → Me avise: volta à lista', ($) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository.withData();
    await app.open(
      systemLocale: const Locale('pt'),
      coach: fake,
      courseGrants: _subscriber(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await t.openFromHome();
    await t.tab(CoachKeys.tabGames);
    await shot.begin('C11-me-avise');
    await $(CoachKeys.game(_queue)).scrollTo();
    await $.tester.tap(find.byKey(CoachKeys.game(_queue)));
    await t.waitLoading();
    await _pause($, 2500);
    await $.tester.tap(find.byKey(CoachKeys.notifyMe));
    await _pause($, 3000);
    await shot.end('C11-me-avise', ready: CoachKeys.screen);
  });

  patrolTest('C9 erro da análise: Tentar de novo', ($) async {
    final app = AppRobot($);
    final t = CoachRobot($);
    final shot = TrainingCaptureRobot($);
    final fake = FakeCoachRepository.withData();
    fake.perGame(
      CoachFixtures.list()
          .firstWhere((p) => p.id == _analyzing)
          .copyWith(status: GameStatus.error),
    );
    await app.open(
      systemLocale: const Locale('pt'),
      coach: fake,
      courseGrants: _subscriber(),
    );
    await TrainingCaptureRobot.semFaixaDoTeste($);
    await t.openFromHome();
    await t.tab(CoachKeys.tabGames);
    await shot.begin('C9-erro-tentar');
    await t.openGame(_analyzing);
    await _pause($, 2500);
    await $(CoachKeys.errorRetry).tap();
    await _pause($, 3000);
    await shot.end('C9-erro-tentar', ready: CoachKeys.back);
  });
}
