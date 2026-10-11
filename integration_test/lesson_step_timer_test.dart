import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/endgames_robot.dart';
import 'robots/home_robot.dart';
import 'robots/settings_robot.dart';

const _english = Locale('en', 'US');
const _lesson = 'basics.queenMate';

/// O primeiro passo de lance da aula (o mate de apoio, num lance).
const _move = 'supportMove';

/// T60: na lição, o aluno resolve com o tabuleiro no centro e um cronômetro
/// que conta para cima, sem limite; respondido o passo, o tabuleiro sobe e o
/// Viktor fala. O tempo de pensar não se escolhe mais.
void main() {
  patrolTest('passo de pensar: sem seletor de tempo, tabuleiro no centro e '
      'cronômetro no canto contando; 6 minutos depois, só ele mudou', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    await endgames.openFromHome();
    await endgames.openLesson(_lesson);
    await endgames.openSteps();
    await endgames.expectStep(_lesson, 't_support');
    await endgames.expectSolving();
    final speech = endgames.speech;
    expect(speech, isNotEmpty);
    expect(endgames.stepTimer, matches(RegExp(r'^0:0\d$')));

    e2eNow.advance(const Duration(minutes: 6));
    await $.pump(const Duration(milliseconds: 300));
    expect(endgames.stepTimer, matches(RegExp(r'^6:0\d$')));
    await endgames.expectSolving();
    expect(endgames.speech, speech);
    expect(find.byKey(LessonKeys.moreHintButton), findsOneWidget);
    expect(find.byKey(LessonKeys.nextButton), findsOneWidget);
  });

  patrolTest('dica e "Ver explicação" funcionam desde o começo; a explicação '
      'leva o tabuleiro ao alto com a folha da fala', ($) async {
    await AppRobot($).open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    await endgames.openFromHome();
    await endgames.openLesson(_lesson);
    await endgames.openSteps();
    await endgames.expectStep(_lesson, 't_support');
    final asked = endgames.speech;
    await endgames.moreHint();
    expect(endgames.speech, isNot(asked));
    await endgames.expectSolving();

    await endgames.nextStep();
    await endgames.expectStep(_lesson, 'goal');
    await endgames.expectExplaining();
  });

  patrolTest('passo de lance respondido: o cronômetro para, o tabuleiro sobe '
      'e o Viktor fala', ($) async {
    await AppRobot($).open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    final lesson = await endgames.lesson(_lesson);
    await endgames.openFromHome();
    await endgames.openLesson(_lesson);
    await endgames.openSteps();
    for (final step in ['t_support', 'goal']) {
      await endgames.expectStep(_lesson, step);
      await endgames.nextStep();
    }
    await endgames.expectStep(_lesson, 'd_support');
    await endgames.finishDemo();
    await endgames.nextStep();
    await endgames.expectStep(_lesson, _move);
    await endgames.expectSolving();
    final centered = endgames.boardRect;
    expect(endgames.stepTimer, matches(RegExp(r'^0:0\d$')));

    final line = (lesson.lesson.steps.firstWhere(
      (step) => step.id == _move,
    ) as dynamic).line;
    for (final turn in line) {
      await endgames.moveInLesson(turn.accept.first as String);
      if (turn.reply != null) await $.pumpAndSettle();
    }
    await endgames.expectExplaining();
    expect(endgames.boardRect.top, lessThan(centered.top));
  });

  patrolTest('sair do app no meio do passo e voltar: o cronômetro continua '
      'do tempo certo', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    await endgames.openFromHome();
    await endgames.openLesson(_lesson);
    await endgames.openSteps();
    await endgames.expectStep(_lesson, 't_support');
    e2eNow.advance(const Duration(minutes: 2));
    await $.pump(const Duration(milliseconds: 300));
    expect(endgames.stepTimer, matches(RegExp(r'^2:0\d$')));

    await app.restart();
    await endgames.expectStep(_lesson, 't_support');
    await endgames.expectSolving();
    expect(endgames.stepTimer, matches(RegExp(r'^2:0\d$')));
  });

  patrolTest('Configurações → Jogo: o tempo de pensar não existe mais', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _english);
    await HomeRobot($).openSettings();
    final settings = SettingsRobot($);
    await settings.expectVisible();
    await settings.openGame();
    expect(find.byKey(const Key('settings.thinkTime')), findsNothing);
    expect(find.byKey(const Key('settings.thinkTime.0')), findsNothing);
  });
}
