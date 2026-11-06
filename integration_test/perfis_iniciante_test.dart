import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/training/training_course.dart';

import '../testing/e2e_dependencies.dart';
import '../testing/training/e2e_training.dart';

import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/goal_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/lesson_finished_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/training_entry_keys.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/domain/use_cases/training/complete_training_lesson.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';
import 'package:lucena/ui/core/keys/my_progress_keys.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/conclusion_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/home_robot.dart';
import 'robots/profile_robot.dart';
import 'robots/race_robot.dart';
import 'robots/speedrun_robot.dart';
import 'robots/script_lesson_robot.dart';
import 'robots/tour_robot.dart';
import 'robots/training_capture_robot.dart';

/// T85: vídeos por perfil de usuário (docs/tasks/T85-videos-perfis.md).
/// P1: quem chega para aprender a jogar (Escola do Viktor).
Future<void> _hold(PatrolIntegrationTester $, [int ms = 1500]) async {
  await $.pump(Duration(milliseconds: ms));
}

/// Primeiro passo de um caminho de torre (BFS, peças bloqueiam) até [targets].
(String, String)? _rookStep(String fen, String from, Set<String> targets) {
  final blocked = <String>{};
  final rows = fen.split(' ').first.split('/');
  for (var r = 0; r < 8; r++) {
    var f = 0;
    for (final ch in rows[r].split('')) {
      final n = int.tryParse(ch);
      if (n != null) {
        f += n;
      } else {
        blocked.add('${'abcdefgh'[f]}${8 - r}');
        f++;
      }
    }
  }
  blocked.remove(from);
  final fromFile = 'abcdefgh'.indexOf(from[0]);
  final fromRank = 8 - int.parse(from[1]);
  var piece = '';
  var col = 0;
  for (final ch in rows[fromRank].split('')) {
    final n = int.tryParse(ch);
    if (n != null) {
      col += n;
    } else {
      if (col == fromFile) piece = ch.toLowerCase();
      col++;
    }
  }
  const straight = [(1, 0), (-1, 0), (0, 1), (0, -1)];
  const diagonal = [(1, 1), (1, -1), (-1, 1), (-1, -1)];
  final dirs = piece == 'b'
      ? diagonal
      : piece == 'q' || piece == 'k'
      ? [...straight, ...diagonal]
      : straight;
  final first = <String, String>{};
  final queue = <String>[from];
  final seen = <String>{from};
  while (queue.isNotEmpty) {
    final cur = queue.removeAt(0);
    for (final d in dirs) {
      var f = 'abcdefgh'.indexOf(cur[0]) + d.$1;
      var r = int.parse(cur[1]) + d.$2;
      while (f >= 0 && f < 8 && r >= 1 && r <= 8) {
        final sq = '${'abcdefgh'[f]}$r';
        if (blocked.contains(sq)) break;
        if (seen.add(sq)) {
          first[sq] = cur == from ? sq : first[cur]!;
          if (targets.contains(sq)) return (from, first[sq]!);
          queue.add(sq);
        }
        if (piece == 'k') break;
        f += d.$1;
        r += d.$2;
      }
    }
  }
  return null;
}

/// Joga uma aula da Escola até a tela "Aula concluída", como um aluno que erra
/// primeiro e depois pede a resposta. [dwell]: pausa (ms) depois de cada passo,
/// para dar para ver no vídeo em 1×.
Future<void> _playLesson(
  PatrolIntegrationTester $, {
  int dwell = 0,
  bool peekSheet = false,
}) async {
  final lesson = ScriptLessonRobot($, manualClock: true);
  var tries = 0;
  var moveCount = 0;
  final visited = <String>{};
  String lastFrom = '';
  var stall = 0;
  String last = '';
  for (var i = 0; i < 300; i++) {
    if (find.byKey(LessonFinishedKeys.screen).evaluate().isNotEmpty) return;
    if (find.byKey(LessonScriptKeys.screen).evaluate().isEmpty) {
      await lesson.settle(3);
      continue;
    }
    final s = lesson.state;
    final sig = '${s.stageId}/${s.exampleIndex}/${s.phase}/${s.fen}/${s.tone}';
    stall = sig == last ? stall + 1 : 0;
    last = sig;
    if (stall > 80) {
      fail('aula parada em $sig (fala: ${lesson.speech})');
    }
    if (peekSheet &&
        i == 3 &&
        find.byKey(LessonScriptKeys.speech).evaluate().isNotEmpty) {
      await lesson.expectSpeechSheetRoundTrip();
    }
    bool tap(Key k) => find.byKey(k).evaluate().isNotEmpty;
    Future<void> press(Key k) async {
      await $.tester.tap(find.byKey(k).first);
      await $.pump();
      await lesson.settle(4);
      if (dwell > 0) await $.pump(Duration(milliseconds: dwell));
    }

    if (tap(LessonScriptKeys.showAnswer)) {
      await press(LessonScriptKeys.showAnswer);
    } else if (tap(LessonScriptKeys.primary) &&
        s.phase != ScriptPhase.praticaVez) {
      await press(LessonScriptKeys.primary);
    } else if (tap(LessonScriptKeys.nextPart)) {
      await press(LessonScriptKeys.nextPart);
    } else if (s.arrows.any((a) => a.color == 'g')) {
      final a = s.arrows.firstWhere((a) => a.color == 'g');
      await lesson.move(a.from, a.to);
      await lesson.settle(4);
      if (dwell > 0) await $.pump(Duration(milliseconds: dwell));
    } else if (s.phase == ScriptPhase.pergunta &&
        find.byKey(LessonScriptKeys.answerChoice(0)).evaluate().isNotEmpty) {
      await press(LessonScriptKeys.answerChoice(tries++ % 3));
    } else if (s.phase == ScriptPhase.praticaVez && s.touching) {
      if (s.marks.isNotEmpty) {
        await lesson.tapSquare(s.marks.first);
      } else {
        await lesson.tapSquare(tries++ == 0 ? 'a1' : 'h8');
      }
      if (dwell > 0) await $.pump(Duration(milliseconds: dwell));
    } else if (s.movable != null && (s.dests?.isNotEmpty ?? false)) {
      final remaining = s.stars.where((q) => !visited.contains(q)).toList();
      moveCount++;
      if (moveCount % 5 == 0 && tap(LessonScriptKeys.hint)) {
        await press(LessonScriptKeys.hint);
        continue;
      }
      final moves = <(String, String)>[
        for (final e in s.dests!.entries)
          for (final t in e.value) (e.key.name, t.name),
      ];
      (String, String) pick = moves.first;
      final bfs = remaining.isEmpty
          ? null
          : _rookStep(s.fen, moves.first.$1, remaining.toSet());
      if (bfs != null && moves.contains(bfs)) {
        visited.add(bfs.$2);
        lastFrom = bfs.$1;
        await lesson.move(bfs.$1, bfs.$2);
        await lesson.settle(4);
        if (dwell > 0) await $.pump(Duration(milliseconds: dwell));
        continue;
      }
      final direct = moves.where((m) => remaining.contains(m.$2));
      if (direct.isNotEmpty) {
        pick = direct.first;
      } else if (remaining.isNotEmpty) {
        final target = remaining.first;
        final line = moves.where(
          (m) =>
              m.$2 != lastFrom &&
              (m.$2[0] == target[0] || m.$2[1] == target[1]),
        );
        if (line.isNotEmpty) pick = line.first;
      }
      visited.add(pick.$2);
      lastFrom = pick.$1;
      await lesson.move(pick.$1, pick.$2);
      await lesson.settle(4);
      if (dwell > 0) await $.pump(Duration(milliseconds: dwell));
    } else {
      await lesson.settle(5);
    }
  }
  final d = lesson.state;
  fail(
    'aula não terminou: stage=${d.stageId} ex=${d.exampleIndex} fase=${d.phase} '
    'fen=${d.fen} tone=${d.tone} stars=${d.stars} marks=${d.marks} '
    'arrows=${d.arrows.length} dests=${d.dests?.length} touching=${d.touching} '
    'fala=${lesson.speech}',
  );
}

/// `--dart-define=PERFIL=P1|P2` roda só um perfil; sem ele, os dois.
const _perfil = String.fromEnvironment('PERFIL');

void main() {
  patrolTest('P1 iniciante que aprende a jogar', skip: _perfil == 'P2', (
    $,
  ) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      tour: true,
    );
    final tour = TourRobot($);
    final robot = TrainingCaptureRobot($);
    await $(GoalKeys.screen).waitUntilVisible();
    await robot.begin('P1Iniciante1');
    await robot.mark('x1_Tour');
    await _hold($);
    // Hesita: marca outro objetivo, olha, e troca por "Aprender a jogar".
    await $(GoalKeys.option(GoalPreference.improve)).tap();
    await _hold($, 1200);
    await tour.answerGoal(GoalPreference.learn);
    for (var i = 0; i < 6; i++) {
      if (find.byKey(TourKeys.screen).evaluate().isEmpty) break;
      await _hold($);
      if (i == 2) {
        // Volta um passo e avança de novo.
        await tour.back();
        await _hold($, 1000);
      }
      await tour.next();
    }
    await $(HomeKeys.screen).waitUntilVisible();
    await robot.mark('x1_Inicio');
    await _hold($, 2500);
    await robot.shot('p1-home', ready: HomeKeys.screen);
    await $(HomeKeys.schoolButton).scrollTo().tap();
    await $(TrainingEntryKeys.signIn).waitUntilVisible();
    await $.pumpAndSettle();
    await robot.mark('x1_Escola_pede_conta');
    await _hold($, 2500);
    await robot.shot('p1-escola-pede-conta', ready: TrainingEntryKeys.signIn);
    // Olha a tela de entrar, hesita e volta ao Início.
    await $(TrainingEntryKeys.signIn).tap();
    await $(AccountKeys.enterScreen).waitUntilVisible();
    await $.pumpAndSettle();
    await _hold($, 2000);
    await robot.shot('p1-entrar', ready: AccountKeys.enterScreen);
    Navigator.of($.tester.element(find.byKey(AccountKeys.enterScreen))).pop();
    await $.pumpAndSettle();
    await $(TrainingEntryKeys.signIn).waitUntilVisible();
    await _hold($, 1000);
    await $(TrainingEntryKeys.accountBack).tap();
    await $(HomeKeys.screen).waitUntilVisible();
    await _hold($, 1500);
    // O login de verdade não existe no teste: reabre o app já com a conta
    // e a Escola baixada (o mesmo cenário do T85) e volta pelo atalho.
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.schoolWelcome,
    );
    await $(HomeKeys.screen).waitUntilVisible();
    await robot.mark('x1_Escola_Boas_vindas');
    await _hold($, 1500);
    await robot.openGuide(escola: true);
    await _hold($, 2500);
    await robot.shot('p1-escola-boasvindas');
    await $(CourseGuideKeys.continueButton).scrollTo().tap();
    await $(TrainingKeys.planScreen).waitUntilVisible();
    await $.pumpAndSettle();
    await robot.mark('x1_Plano_de_estudo');
    await _hold($, 2000);
    await robot.shot('p1-plano', ready: TrainingKeys.planScreen);
    await $(TrainingKeys.planChip(30)).tap();
    await _hold($, 1000);
    await $(TrainingKeys.planSave).scrollTo().tap();
    await $(CourseGuideKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
    await robot.mark('x1_Metas_do_dia');
    await robot.tab('goals');
    await _hold($, 2000);
    final guide = $.tester
        .element(find.byKey(CourseGuideKeys.screen))
        .read<CourseGuideCubit>();
    await guide.load();
    await $.pumpAndSettle();
    final goals = guide.state.training!.day!.goals;
    debugPrint(
      'T85 metas: ${goals.map((g) => '${g.kind.name}:${g.ref}').join(', ')}',
    );
    await robot.shot('p1-lista-inicial');
    await robot.mark('x1_Aula_1');
    final first = goals.firstWhere((g) => g.kind == GoalKind.lesson);
    await $(TrainingKeys.goalTile('lesson', first.ref)).scrollTo().tap();
    await $(LessonScriptKeys.screen).waitUntilVisible();
    await _hold($, 1500);
    await _playLesson($, dwell: 900, peekSheet: true);
    await $.pumpAndSettle();
    await robot.shot('p1-aula-concluida', ready: LessonFinishedKeys.screen);
    await _hold($, 2500);
    await $(LessonFinishedKeys.back).tap();
    await $(CourseGuideKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
    // A gravação do aparelho corta em 180 s: o fluxo vai em dois blocos.
    await robot.end('P1Iniciante1');
    await robot.begin('P1Iniciante2');
    // Aulas 2 em diante: o aluno já sabe o caminho, o vídeo anda em 5x.
    await robot.mark('x5_Aulas_2_a_N');
    final repository = $.tester
        .element(find.byKey(CourseGuideKeys.screen))
        .read<TrainingRepository>();
    for (var n = 0; n < 2; n++) {
      final today = await repository.load(TrainingCourse.escola);
      final pending = today.day!.goals
          .where((g) => g.kind == GoalKind.lesson && !g.done)
          .toList();
      if (pending.isEmpty) break;
      await $(TrainingKeys.goalTile('lesson', pending.first.ref))
          .scrollTo()
          .tap();
      await $.pump(const Duration(seconds: 3));
      if (find.byKey(LessonScriptKeys.screen).evaluate().isEmpty) {
        final textos = find
            .byType(Text)
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .join(' | ');
        fail('AULA ${pending.first.ref} sem tela: $textos');
      }
      await _playLesson($);
      await $.pumpAndSettle();
      await $(LessonFinishedKeys.back).tap();
      await $(CourseGuideKeys.screen).waitUntilVisible();
      await $.pumpAndSettle();
    }
    // As aulas que sobram entram por atalho de dados (o vídeo não as joga).
    final resources = await repository.resources(TrainingCourse.escola);
    final complete = CompleteTrainingLesson(e2eNow, guide.config);
    await repository.update(TrainingCourse.escola, (state) {
      var next = state;
      for (final l in resources.lessons) {
        if (l.visible && l.inCourseOrder) next = complete(next, resources, l);
      }
      return next;
    });
    await guide.load();
    await $.pumpAndSettle();
    await robot.mark('x1_Formatura');
    await $(CourseGuideKeys.tab('lesson')).tap();
    await $.pumpAndSettle();
    await _hold($, 2500);
    await robot.shot('p1-escola-completa');
    await $(TrainingKeys.completedPrimary).scrollTo().tap();
    await $.pumpAndSettle();
    await _hold($, 4000);
    await robot.end('P1Iniciante2');
  });

  patrolTest('P2 iniciante dos desafios', skip: _perfil == 'P1', ($) async {
    final app = AppRobot($);
    await app.open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      tour: true,
    );
    final tour = TourRobot($);
    final robot = TrainingCaptureRobot($);
    await $(GoalKeys.screen).waitUntilVisible();
    await robot.begin('P2Desafios1');
    await robot.mark('x1_Tour');
    await _hold($);
    await tour.answerGoal(GoalPreference.train);
    for (var i = 0; i < 6; i++) {
      if (find.byKey(TourKeys.screen).evaluate().isEmpty) break;
      await _hold($, 1200);
      await tour.next();
    }
    await $(HomeKeys.screen).waitUntilVisible();
    await robot.mark('x1_Inicio');
    await _hold($, 2500);
    await robot.shot('p2-home', ready: HomeKeys.screen);

    // Maratona: três etapas que emendam sozinhas (1ª vez em 1x).
    final speedrun = SpeedrunRobot($);
    final board = FreeBoardRobot($);
    await robot.mark('x1_Maratona');
    await speedrun.open(pace: null);
    await _hold($, 2000);
    await robot.shot('p2-speedrun-lista', ready: SpeedrunKeys.listScreen);
    await speedrun.chooseMode(marathon: true);
    await speedrun.choosePace('30+0');
    await _hold($, 1500);
    await speedrun.openSpeedrun('marathon.e2e.ending@30+0');
    await _hold($, 1500);
    await speedrun.start();
    final (from, to) = E2EJourneyRepository.mate;
    for (var stage = 0; stage < 3; stage++) {
      if (stage > 0) {
        await speedrun.expectNextMarathonStage(stage);
      } else {
        await speedrun.waitVersusGone();
      }
      await _hold($, stage == 0 ? 1500 : 300);
      await app.advanceTime(const Duration(seconds: 2));
      await board.move(from, to);
      if (stage == 0) await robot.mark('x5_Maratona_etapas_2_e_3');
    }
    await $(ConclusionKeys.screen).waitUntilVisible();
    await $(ConclusionKeys.total).scrollTo();
    await robot.mark('x1_Maratona_resultado');
    await _hold($, 3500);
    await robot.shot('p2-maratona-resultado', ready: ConclusionKeys.screen);
    await ConclusionRobot($).close();
    await $.pumpAndSettle();
    await _homeFromAnywhere($);
    await $(HomeKeys.screen).waitUntilVisible();

    await robot.end('P2Desafios1');
    await robot.begin('P2Desafios2');
    // Corrida de problemas: 1ª rodada em 1x; as seguintes em 5x.
    final race = RaceRobot($);
    await robot.mark('x1_Corrida');
    await race.openFromAllModes();
    await _hold($, 2000);
    await robot.shot('p2-corrida-intro', ready: RaceKeys.introView);
    await race.start();
    await _hold($, 1500);
    await race.solve();
    await _hold($, 800);
    await race.miss();
    await _hold($, 1200);
    await robot.mark('x5_Corrida_demais_problemas');
    await race.solve();
    await race.solve();
    await race.miss();
    await race.miss();
    await robot.mark('x1_Corrida_resultado');
    await race.waitForResult();
    await $.pumpAndSettle();
    await _hold($, 3500);
    await robot.shot('p2-corrida-resultado', ready: RaceKeys.resultView);
    await $(RaceKeys.diagnosisProgress).scrollTo();
    await _hold($, 1500);
    await _homeFromAnywhere($);

    // Progresso e Perfil.
    await robot.mark('x1_Progresso');
    await $(HomeKeys.playerCard)
        .scrollTo(scrollDirection: AxisDirection.up)
        .tap();
    await $(MyProgressKeys.screen).waitUntilVisible();
    await _hold($, 3000);
    await robot.shot('p2-progresso', ready: MyProgressKeys.screen);
    await $(BackButton).tap();
    await $(HomeKeys.screen).waitUntilVisible();
    await robot.mark('x1_Perfil');
    await HomeRobot($).openSettings();
    await ProfileRobot($).open();
    await _hold($, 3000);
    await robot.shot('p2-perfil', ready: ProfileKeys.screen);
    await robot.end('P2Desafios2');
  });
}

Future<void> _homeFromAnywhere(PatrolIntegrationTester $) async {
  for (var i = 0; i < 8; i++) {
    if (find.byKey(HomeKeys.screen).hitTestable().evaluate().isNotEmpty) return;
    final navigator = Navigator.of(
      $.tester.element(find.byType(Scaffold).last),
    );
    await navigator.maybePop();
    await $.pumpAndSettle();
  }
}
