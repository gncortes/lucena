import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/school_robot.dart';
import 'robots/tour_robot.dart';
import 'robots/variant.dart';

const _english = Locale('en', 'US');

void main() {
  patrolTest('tour: o Viktor fala em cada passo e o iniciante vai às aulas', (
    $,
  ) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);
    await tour.passVoice();
    expect(find.byKey(TourKeys.speech), findsOneWidget);
    await tour.next();
    await tour.expectStep(TourStep.theme);
    expect(find.byKey(TourKeys.speech), findsOneWidget);

    await tour.nextUntilLevel();
    await tour.chooseLevel(RatingLevel.beginner);
    await tour.start();

    final school = SchoolRobot($);
    await school.expectTrail();
    expect(find.byKey(SchoolKeys.continueButton), findsOneWidget);
  });

  patrolTest('aula da torre: estrelas, fim da aula e a do bispo abre', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _english);
    final school = SchoolRobot($);
    await school.openFromHome();
    await school.openLesson('pieces.rook');
    await school.expectStep('pieces.rook', 'intro');
    await school.next();

    await school.expectStep('pieces.rook', 'stars1');
    school.expectStar('a6');
    await school.move('a1', 'a6');
    school.expectStar('a6', visible: false);
    await school.move('a6', 'f6');
    await school.move('f6', 'f2');
    expectText(
      school.speech,
      'Perfect. See how it crosses the whole board in a single move?',
    );
    await school.next();
    await school.expectStep('pieces.rook', 'block');
    await school.next();
    await school.move('c1', 'c5');
    await school.move('c5', 'h5');
    await school.move('h5', 'h8');
    await school.next();

    await school.expectFinished();
    await school.openNextLesson();
    await school.expectStep('pieces.bishop', 'intro');
  });

  patrolTest('lance errado: a peça volta e o Viktor dá a dica', ($) async {
    await AppRobot($).open(systemLocale: _english);
    final school = SchoolRobot($);
    await school.openFromHome();
    await school.openLesson('pieces.pawn');
    await school.next();
    await school.expectStep('pieces.pawn', 'double');

    await school.move('e2', 'e3');
    expectText(
      school.speech,
      'On its first move the pawn may go two squares: from e2 to e4.',
    );
    await school.move('e2', 'e4');
    expectText(school.speech, 'Perfect.');
    expect(find.byKey(LessonKeys.nextButton), findsOneWidget);
  });

  patrolTest('fechar à força no meio da aula: reabre no mesmo passo', (
    $,
  ) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    final school = SchoolRobot($);
    await school.openFromHome();
    await school.openLesson('pieces.rook');
    await school.next();
    await school.move('a1', 'a6');

    await app.restart();
    await school.expectStep('pieces.rook', 'stars1');
    school.expectStar('a6', visible: false);
    school.expectStar('f6');
  });

  patrolTest('jogar: a dica mostra a seta e o mate conclui o passo', ($) async {
    await AppRobot($).open(systemLocale: _english);
    final school = SchoolRobot($);
    await school.openFromHome();
    await school.openLesson('technique.rookMate');
    // Os passos até o primeiro de jogar.
    for (final step in ['final', 'mate1', 'plan', 'waitMate']) {
      await school.expectStep('technique.rookMate', step);
      switch (step) {
        case 'mate1':
          await school.move('h1', 'h8');
        case 'waitMate':
          await school.move('h1', 'e1');
          await $.pump(const Duration(seconds: 1));
          await $.pumpAndSettle();
          await school.move('e1', 'e8');
      }
      await school.next();
    }
    await school.expectStep('technique.rookMate', 'play1');
    await school.hint();
    school.expectHintArrow('h1', 'h8');
    await school.move('h1', 'h8');
    expectText(school.speech, 'Well done. Now the whole way, from the centre.');
  });
}
