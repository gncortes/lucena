import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/school_robot.dart';
import 'robots/tour_robot.dart';

const _english = Locale('en', 'US');

void main() {
  patrolTest('tour B: os cinco passos na ordem, com a barra de progresso '
      'avançando a cada um e o Viktor falando em todos', ($) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);

    var previous = 0.0;
    for (final step in TourStep.values) {
      await tour.nextUntil(step);
      await tour.expectStep(step);
      tour.expectProgress(step);
      final value = (step.index + 1) / TourStep.values.length;
      expect(value, greaterThan(previous));
      previous = value;
      expect(find.byKey(TourKeys.speech), findsOneWidget);
      // O "Voltar" só falta no primeiro passo.
      expect(
        find.byKey(TourKeys.backButton),
        step == TourStep.board ? findsNothing : findsOneWidget,
      );
    }
    expect(previous, 1);
    // O último passo tem a chave do fim e leva à conta.
    expect(find.byKey(TourKeys.nextButton), findsNothing);
    expect(find.byKey(TourKeys.startButton), findsOneWidget);
    expect(find.byKey(TourKeys.skipButton), findsNothing);
  });

  patrolTest('Seu nível: "Fazer o teste" vem marcado, "Continuar" habilitado e '
      '"Não sei jogar" grava a faixa iniciante', ($) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);
    await tour.nextUntilLevel();

    expect(tour.levelCubit.state.choice, LevelChoice.test);
    expect(tour.levelCubit.state.levelChosen, isFalse);
    expect(
      $.tester.widget<FilledButton>(find.byKey(LevelKeys.next)).onPressed,
      isNotNull,
    );

    await tour.chooseLevel(RatingLevel.beginner);
    await tour.start();
    // Com a Escola escondida (VisibleLessons), o tour leva à tela inicial.
    VisibleLessons.school
        ? await SchoolRobot($).expectTrail()
        : await HomeRobot($).expectVisible();

    final saved = await tour.savedOnboarding();
    expect(saved.done, isTrue);
    expect(saved.inProgress, isFalse);
    expect(saved.selectedRating, RatingLevel.beginner.rating);
  });

  patrolTest('Seu nível: escolher outra faixa pela folha, confirmar e '
      'continuar grava a faixa', ($) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);
    await tour.nextUntilLevel();

    await tour.chooseLevel(RatingLevel.advanced);
    expect(tour.levelCubit.state.choice, LevelChoice.band);
    expect(tour.levelCubit.state.level, RatingLevel.advanced);
    expect(tour.levelCubit.state.levelChosen, isTrue);
    final selected = await tour.savedOnboarding();
    expect(selected.selectedRating, RatingLevel.advanced.rating);

    // Abrir a folha e sair sem confirmar não muda a faixa.
    await tour.openBandSheet();
    await tour.dismissBandSheet();
    expect(tour.levelCubit.state.level, RatingLevel.advanced);

    // Voltar ao iniciante pelo cartão dele.
    await tour.chooseLevel(RatingLevel.beginner);
    expect(tour.levelCubit.state.choice, LevelChoice.beginner);
    await tour.chooseLevel(RatingLevel.advanced);

    await tour.start();
    await HomeRobot($).expectVisible();
    final saved = await tour.savedOnboarding();
    expect(saved.done, isTrue);
    expect(saved.selectedRating, RatingLevel.advanced.rating);
    expect(saved.startRung, isNotNull);
  });

  patrolTest('tour B: fechar à força em qualquer passo reabre no mesmo '
      'passo (tour.stepV2)', ($) async {
    final app = AppRobot($);
    final tour = TourRobot($);
    await app.open(systemLocale: _english, tour: true);

    for (final step in TourStep.values.skip(1)) {
      await tour.nextUntil(step);
      expect(
        await PreferencesService().getString('tour.stepV2'),
        '${step.index}',
      );

      await app.restart();
      await tour.expectStep(step);
      tour.expectProgress(step);
    }

    // Voltar também é gravado.
    await tour.back();
    await tour.expectStep(TourStep.play);
    expect(
      await PreferencesService().getString('tour.stepV2'),
      '${TourStep.play.index}',
    );
    await app.restart();
    await tour.expectStep(TourStep.play);
  });
}
