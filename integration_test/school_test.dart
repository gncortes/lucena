import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/school_robot.dart';
import 'robots/tour_robot.dart';

const _english = Locale('en', 'US');

void main() {
  patrolTest('tour: o Viktor fala em cada passo e o iniciante vai às aulas', (
    $,
  ) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);
    await tour.expectStep(TourStep.board);
    expect(find.byKey(TourKeys.speech), findsOneWidget);
    await tour.next();
    await tour.expectStep(TourStep.voice);
    expect(find.byKey(TourKeys.speech), findsOneWidget);

    await tour.nextUntilLevel();
    await tour.chooseLevel(RatingLevel.beginner);
    await tour.start();

    final school = SchoolRobot($);
    await school.expectTrail();
    expect(find.byKey(SchoolKeys.continueButton), findsOneWidget);
  });

  // As aulas do curso agora têm roteiro (T71): a rota troca pela tela
  // roteirizada, sem os passos da lição de reserva.
  patrolTest('aula da torre: abre a tela roteirizada; o balão não tem X, o '
      'toque abre a fala inteira e o X da folha fecha', ($) async {
    await AppRobot($).open(systemLocale: _english);
    final school = SchoolRobot($);
    await school.openFromHome();
    await school.openScriptLesson('pieces.rook');
    expect(find.byKey(LessonKeys.screen), findsNothing);

    await school.expectScriptSpeechSheet();
    // O Continuar anda para a fala seguinte, na mesma tela.
    await school.scriptContinue();
    await school.expectScriptSpeechSheet();
    expect(find.byKey(LessonScriptKeys.screen), findsOneWidget);
  });

  patrolTest('fechar à força no meio da aula: reabre na tela roteirizada', (
    $,
  ) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    final school = SchoolRobot($);
    await school.openFromHome();
    await school.openScriptLesson('pieces.rook');
    await school.scriptContinue();

    await app.restart();
    await $(LessonScriptKeys.screen).waitUntilVisible();
    await $(LessonScriptKeys.speech).waitUntilVisible();
  });
}
