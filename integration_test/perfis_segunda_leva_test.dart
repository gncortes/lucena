import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/platform_rating.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/external_page_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/core/keys/training_goal_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/catalog_robot.dart';
import 'robots/conclusion_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/home_robot.dart';
import 'robots/profile_robot.dart';
import 'robots/tour_robot.dart';
import 'robots/training_capture_robot.dart';

const _ptBr = Locale('pt', 'BR');

/// Torre e rei contra rei: a torre vai e volta, o Maia responde de verdade.
const _rookShuffle = 'k7/8/8/8/8/8/8/4K2R w - - 0 1';

/// Pausa de [ms] com quadros, para o vídeo ter o tempo de uma pessoa lendo.
Future<void> _hold(PatrolIntegrationTester $, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await $.pump(const Duration(milliseconds: 50));
  }
}

/// Volta ao Início, como o botão Início do sistema faria.
Future<void> _goHome(PatrolIntegrationTester $) async {
  if (find.byKey(HomeKeys.screen).evaluate().isEmpty) {
    GoRouter.of($.tester.element(find.byType(Scaffold).first)).go('/');
    await $.pumpAndSettle();
  }
  await $(HomeKeys.screen).waitUntilVisible();
}

/// "Continuar" da lição, quando o botão já apareceu (a fala termina de
/// aparecer antes). Devolve falso se ele não vem.
Future<bool> _lessonStep(PatrolIntegrationTester $) async {
  for (var i = 0; i < 200; i++) {
    if (find.byKey(LessonScriptKeys.primary).evaluate().isNotEmpty) {
      await $.tester.tap(find.byKey(LessonScriptKeys.primary).first);
      await $.pump(const Duration(seconds: 1));
      return true;
    }
    await $.pump(const Duration(milliseconds: 50));
  }
  return false;
}

/// O botão voltar do sistema.
Future<void> _back(PatrolIntegrationTester $) async {
  await $.tester.binding.handlePopRoute();
  await $.pumpAndSettle();
}

/// O primeiro exercício das Metas (qualquer tema), na Aba Metas.
final _exerciseGoal = find.byWidgetPredicate(
  (w) => switch (w.key) {
    ValueKey<String>(:final value) => value.startsWith(
      'training.goal.exercise.',
    ),
    _ => false,
  },
);

final _lessonGoal = find.byWidgetPredicate(
  (w) => switch (w.key) {
    ValueKey<String>(:final value) => value.startsWith('training.goal.lesson.'),
    _ => false,
  },
);

/// Abre o Pilares nas Metas pelo Início (a pessoa toca no cartão do curso).
Future<void> _openGoals(PatrolIntegrationTester $) async {
  await TrainingCaptureRobot($).openGuide();
  await TrainingCaptureRobot($).tab('goals');
}

/// Joga o lance [uci] no exercício aberto e espera o resultado.
Future<void> _exerciseMove(PatrolIntegrationTester $, String uci) =>
    TrainingCaptureRobot($).move(uci);

/// Abre o item [key] (se existir na tela), espera, e volta pelo sistema.
Future<bool> _visit(
  PatrolIntegrationTester $,
  Key key, {
  Key? ready,
  int hold = 1600,
}) async {
  final finder = find.byKey(key);
  if (finder.evaluate().isEmpty) {
    try {
      await $.scrollUntilExists(finder: finder, maxScrolls: 8);
    } catch (_) {
      return false;
    }
  }
  await $(key).scrollTo().tap();
  await $.pumpAndSettle();
  if (ready != null) await $(ready).waitUntilVisible();
  await _hold($, hold);
  await _back($);
  await _hold($, 600);
  return true;
}

/// `--dart-define=PERFIL=p9` roda só esse perfil; sem ele rodam todos.
bool _ativo(String id) {
  const perfil = String.fromEnvironment('PERFIL');
  return perfil.isEmpty || perfil == id;
}

void main() {
  // ---------------------------------------------------------------- P8 ----
  patrolTest('P8 Quem volta no dia seguinte', ($) async {
    final app = AppRobot($);
    await app.open(
      systemLocale: _ptBr,
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.goalsLarge,
    );
    final robot = TrainingCaptureRobot($);
    final home = HomeRobot($);

    // Preparação (fora da gravação): o primeiro dia de uso. Um exercício
    // feito, uma lição aberta e largada no meio.
    await home.expectVisible();
    await _openGoals($);
    await $(_exerciseGoal).first.tap();
    await $(TrainingKeys.exerciseBoard).waitUntilVisible();
    await $.pumpAndSettle();
    await _exerciseMove($, 'a1a8');
    await $(TrainingKeys.nextGoal).tap();
    await $.pumpAndSettle();
    await _goHome($);
    await _openGoals($);
    await $(_lessonGoal).first.tap();
    await $(LessonScriptKeys.screen)
        .waitUntilVisible(timeout: const Duration(seconds: 60));
    await _hold($, 1500);
    for (var i = 0; i < 3; i++) {
      if (!await _lessonStep($)) break;
    }
    await _goHome($);

    // O dia passa; o app é fechado e aberto de novo no dia seguinte.
    await app.advanceTime(const Duration(days: 1, hours: 9));
    await app.restart();
    await home.expectVisible();

    await robot.begin('P8VoltaNoDia');
    await robot.mark('x1_Inicio_no_dia_seguinte');
    await _hold($, 3000);
    await robot.mark('x1_Guia_e_Metas_do_dia');
    await robot.openGuide();
    await _hold($, 2500);
    await robot.tab('goals');
    await _hold($, 3500);
    // Hesita: olha a sequência e volta.
    if (find.byKey(TrainingGoalKeys.streak).evaluate().isNotEmpty) {
      await $(TrainingGoalKeys.streak).tap();
      await $.pumpAndSettle();
      await _hold($, 3500);
      await _back($);
      await _hold($, 1200);
    }
    await robot.mark('x1_Retoma_a_licao');
    if (_lessonGoal.evaluate().isNotEmpty) {
      await $(_lessonGoal).first.scrollTo().tap();
      await $(LessonScriptKeys.screen)
          .waitUntilVisible(timeout: const Duration(seconds: 60));
      await _hold($, 1500);
      await _hold($, 3500);
      await _lessonStep($);
      await _hold($, 2500);
      await _back($);
      await _hold($, 1500);
    }
    await robot.mark('x1_Exercicio_do_dia');
    await robot.exercise(
      // O primeiro exercício das metas novas.
      _firstExerciseTheme($),
    );
    await _hold($, 2500);
    await robot.move('a1a8');
    await _hold($, 3000);
    await _goHome($);
    await _hold($, 3000);
    await robot.end('P8VoltaNoDia');
  }, skip: !_ativo('p8'));

  // ---------------------------------------------------------------- P9 ----
  patrolTest('P9 Quem erra e desiste', ($) async {
    final app = AppRobot($);
    await app.open(
      systemLocale: _ptBr,
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.goalsLarge,
    );
    final robot = TrainingCaptureRobot($);
    final home = HomeRobot($);
    await home.expectVisible();
    await robot.begin('P9ErraDesiste');

    await robot.mark('x1_Inicio');
    await _hold($, 2500);
    await robot.mark('x1_Exercicio_erra_e_pede_dica');
    await robot.openGuide();
    await _hold($, 1500);
    await robot.tab('goals');
    await _hold($, 2000);
    await $(_exerciseGoal).first.scrollTo().tap();
    await $(TrainingKeys.exerciseBoard).waitUntilVisible();
    await $.pumpAndSettle();
    await _hold($, 3000);
    // Hesita e erra.
    await robot.move('a1a2');
    await _hold($, 3000);
    // Pede a dica e tenta de novo, ainda errando.
    await $(TrainingKeys.exercisePracticeRetry).tap();
    await $.pumpAndSettle();
    await _hold($, 1500);
    await robot.hint();
    await _hold($, 3500);
    await robot.move('a1a3');
    await _hold($, 2500);
    await $(TrainingKeys.exercisePracticeRetry).tap();
    await $.pumpAndSettle();
    await _hold($, 1200);
    await robot.move('a1a8');
    await _hold($, 3500);

    await robot.mark('x5_Outro_exercicio_com_erro');
    await $(TrainingKeys.nextGoal).tap();
    await $.pumpAndSettle();
    if (find.byKey(TrainingKeys.exerciseBoard).evaluate().isNotEmpty) {
      await _hold($, 600);
      await robot.move('a1a2');
      await _hold($, 600);
      await $(TrainingKeys.exercisePracticeRetry).tap();
      await $.pumpAndSettle();
      await robot.hint();
      await _hold($, 800);
      await robot.move('a1a8');
      await _hold($, 800);
    }
    await _goHome($);
    await _hold($, 800);

    await robot.mark('x1_Partida_e_desistencia');
    await FreeBoardRobot($).openAt(
      _rookShuffle,
      opponent: 'maia',
      level: 1400,
      user: Side.white,
      goal: 'win',
    );
    final board = FreeBoardRobot($);
    await _hold($, 2500);
    await board.move('h1', 'h2');
    await board.waitForMoves(2);
    await _hold($, 2000);
    await board.move('h2', 'h1');
    await board.waitForMoves(4);
    await _hold($, 2500);
    await board.resign();
    await ConclusionRobot($).waitConclusion();
    await _hold($, 4000);
    await ConclusionRobot($).close();
    await home.expectVisible();
    await robot.mark('x1_De_volta_ao_Inicio');
    await _hold($, 3500);
    await robot.end('P9ErraDesiste');
  }, skip: !_ativo('p9'));

  // --------------------------------------------------------------- P10 ----
  patrolTest('P10 Quem só explora', ($) async {
    final app = AppRobot($);
    await app.open(
      systemLocale: _ptBr,
      lightDevice: true,
      tour: false,
      trainingScenario: E2ETrainingScenario.goalsLarge,
    );
    final robot = TrainingCaptureRobot($);
    final home = HomeRobot($);
    await home.expectVisible();
    await robot.begin('P10Explora1');

    await robot.mark('x1_Inicio');
    await _hold($, 2500);

    // Configurações, item por item.
    await robot.mark('x1_Configuracoes');
    await home.openSettings();
    await $(SettingsKeys.screen).waitUntilVisible();
    await _hold($, 2000);
    await _visit($, SettingsKeys.profileTile, ready: ProfileKeys.screen);
    for (final group in [
      SettingsKeys.appearanceTile,
      SettingsKeys.gameTile,
      SettingsKeys.soundTile,
    ]) {
      await $(group).scrollTo().tap();
      await $.pumpAndSettle();
      await _hold($, 1500);
      for (final tile in [
        SettingsKeys.languageTile,
        SettingsKeys.themeTile,
        SettingsKeys.boardAppearanceTile,
        SettingsKeys.clockTile,
        SettingsKeys.boardBehaviorTile,
      ]) {
        if (find.byKey(tile).evaluate().isNotEmpty) {
          await _visit($, tile, hold: 1300);
        }
      }
      await _back($);
      await _hold($, 700);
    }
    await _visit($, SettingsKeys.homeLayoutTile);
    await _visit($, SettingsKeys.alertsTile);
    await _visit($, SettingsKeys.aboutTile, ready: SettingsKeys.aboutScreen);
    await _visit($, SettingsKeys.privacyTile);

    // Perfil: olha as linhas e volta.
    await robot.mark('x1_Perfil');
    // Volta ao topo da lista de Configurações, como a pessoa faria.
    for (var i = 0; i < 3; i++) {
      await $.tester.drag(find.byType(Scrollable).first, const Offset(0, 1200));
      await $.pump(const Duration(milliseconds: 400));
    }
    await $.pumpAndSettle();
    await $(SettingsKeys.profileTile).scrollTo().tap();
    await $(ProfileKeys.screen).waitUntilVisible();
    await _hold($, 2500);
    await $(ProfileKeys.rowLevel).scrollTo().tap();
    await $(LevelKeys.screen).waitUntilVisible();
    await _hold($, 2200);
    await _back($);
    await _hold($, 1000);
    await $(ProfileKeys.rowGoal).scrollTo().tap();
    await _hold($, 2200);
    await _back($);
    await _hold($, 1000);
    await _back($);
    await _goHome($);
    await _hold($, 1200);

    // Aulas de finais: filtro em tela cheia.
    await robot.mark('x1_Finais_e_filtro');
    await HomeRobot($).openSettings();
    await _back($);
    await _hold($, 500);
    await _goHome($);
    // Com o Pilares no Início, as aulas soltas não têm cartão: entra pela rota.
    unawaited(
      GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)))
          .push<void>(Routes.endgamesFiltered(forYou: false)),
    );
    await $.pumpAndSettle();
    await $(EndgamesKeys.screen).waitUntilVisible();
    await _hold($, 2500);
    if (find.byKey(EndgamesKeys.filtersButton).evaluate().isNotEmpty) {
      await $(EndgamesKeys.filtersButton).tap();
      await $.pumpAndSettle();
      await _hold($, 2500);
      await _back($);
      await _hold($, 1000);
    }
    await _back($);
    await _hold($, 1200);
    await _goHome($);

    // Catálogo.
    await robot.mark('x1_Catalogo');
    final catalog = CatalogRobot($);
    await catalog.open();
    await _hold($, 2000);
    await catalog.openCategory('basic');
    await _hold($, 2500);
    await _back($);
    await _hold($, 1000);
    await _back($);
    await _goHome($);
    await _hold($, 800);

    // Todos os modos.
    await robot.mark('x1_Todos_os_modos');
    await openAllModes($);
    await _hold($, 2500);
    await _back($);
    await _hold($, 800);

    // Pilares: uma lição e o link na fala do Viktor.
    await robot.end('P10Explora1');
    await robot.begin('P10Explora2');
    await robot.mark('x1_Pilares_e_link');
    await _openGoals($);
    await _hold($, 2500);
    await $(_lessonGoal).first.scrollTo().tap();
    await $(find.textContaining('conde Isouard', findRichText: true))
        .waitUntilVisible(timeout: const Duration(seconds: 60));
    await _hold($, 3000);
    // A fala do Morphy pode vir passos depois: a pessoa segue a lição.
    for (var i = 0; i < 8; i++) {
      if (find.textRange.ofSubstring('Paul Morphy').evaluate().isNotEmpty) {
        break;
      }
      if (!await _lessonStep($)) break;
      await _hold($, 1800);
    }
    final hasLink = find.textRange
        .ofSubstring('Paul Morphy')
        .evaluate()
        .isNotEmpty;
    if (hasLink) {
      await $.tester.tapOnText(find.textRange.ofSubstring('Paul Morphy').first);
      await $(ExternalPageKeys.sheet).waitUntilVisible();
      await _hold($, 4500);
      await $(ExternalPageKeys.close).tap();
      await $.pumpAndSettle();
      await _hold($, 1500);
    } else {
      // Sem o link na fala aberta, a pessoa só lê e segue.
      await _hold($, 3000);
    }
    await _back($);
    await _hold($, 1000);
    await _goHome($);

    // Telas de venda.
    await robot.mark('x1_Telas_de_venda');
    unawaited(
      GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)))
          .push<void>(D2Paths.pilaresPresentation),
    );
    await $.pumpAndSettle();
    await _hold($, 3500);
    await $.tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await _hold($, 1500);
    await $.tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await _hold($, 1500);
    await _back($);
    await _hold($, 1500);
    await _goHome($);
    await _hold($, 2500);
    await robot.end('P10Explora2');
  }, skip: !_ativo('p10'));

  // --------------------------------------------------------------- P11 ----
  patrolTest('P11 Quem conecta o Lichess', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _ptBr, lightDevice: true, tour: true);
    final robot = TrainingCaptureRobot($);
    final tour = TourRobot($);
    final home = HomeRobot($);
    await robot.begin('P11Lichess');

    await robot.mark('x1_Tour');
    await _hold($);
    await tour.answerGoal(GoalPreference.train);
    await _hold($);
    for (final step in [TourStep.board, TourStep.theme, TourStep.voice]) {
      await tour.expectStep(step);
      await _hold($);
      await tour.next();
    }
    await tour.expectStep(TourStep.level);
    await _hold($, 2000);
    await tour.chooseLevel(RatingLevel.intermediate);
    await _hold($, 1500);
    await tour.start(leave: false);
    await tour.expectStep(TourStep.region);
    await _hold($);
    await tour.next();
    await tour.expectStep(TourStep.account);
    await _hold($);
    await tour.next();
    await home.expectVisible();

    await robot.mark('x1_Inicio_com_rating_informado');
    await _hold($, 3500);

    e2eLichess.rating = PlatformRating(
      user: 'gabriel_xadrez',
      readAt: DateTime(2026, 11, 5),
      blitz: const ModeRating(rating: 1830, games: 410),
      rapid: const ModeRating(rating: 1880, games: 220),
    );
    await robot.mark('x1_Perfil_e_Lichess');
    await home.openSettings();
    await _hold($);
    await ProfileRobot($).open();
    await _hold($, 2500);
    await $(ProfileKeys.rowLichess).scrollTo().tap();
    await $(LevelKeys.screen).waitUntilVisible();
    await _hold($, 2200);
    // Hesita: volta sem escolher e entra de novo.
    await _back($);
    await _hold($, 1200);
    await $(ProfileKeys.rowLichess).scrollTo().tap();
    await $(LevelKeys.screen).waitUntilVisible();
    await _hold($, 1200);
    await $(LevelKeys.option(LevelChoice.known)).scrollTo().tap();
    await _hold($, 900);
    await $(LevelKeys.continueButton).scrollTo().tap();
    await _hold($, 1500);
    await $(LevelKeys.option(LevelChoice.lichess)).scrollTo().tap();
    await _hold($, 900);
    await $(LevelKeys.continueButton).scrollTo().tap();
    await $(LevelKeys.lichessScreen).waitUntilVisible();
    await _hold($, 3500);
    await $(LevelKeys.lichessUse).tap();
    await _hold($, 2500);
    // Sem conta, o convite aparece: a pessoa lê e diz "Agora não".
    if ($(AccountKeys.inviteSheet).exists) {
      await _hold($, 2500);
      await $(AccountKeys.notNow).tap();
    }
    await _hold($, 3000);

    await robot.mark('x1_Inicio_com_o_novo_rating');
    if (!$(HomeKeys.screen).exists) {
      await _back($);
      await _hold($, 1000);
    }
    if (!$(HomeKeys.screen).exists) await _back($);
    await home.expectVisible();
    await _hold($, 4500);
    await robot.end('P11Lichess');
  }, skip: !_ativo('p11'));
}

/// O tema do primeiro exercício das Metas na tela.
String _firstExerciseTheme(PatrolIntegrationTester $) {
  final key = $.tester.widget(_exerciseGoal.first).key! as ValueKey<String>;
  return key.value.substring('training.goal.exercise.'.length);
}
