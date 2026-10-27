import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/profile_robot.dart';
import 'robots/tour_robot.dart';

void main() {
  patrolTest('primeira abertura com "Aprender a jogar": sem "Seu nível", a '
      'tela inicial já tem o cartão do objetivo', ($) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: const Locale('pt', 'BR'), tour: true);
    await tour.finishSteps();
    await tour.answerGoal(GoalPreference.learn);

    await HomeRobot($).expectVisible();
    expect(find.byKey(LevelKeys.screen), findsNothing);
    await $(HomeKeys.goalCard).waitUntilVisible();
  });

  patrolTest('trocar o objetivo no Perfil troca o cartão do alto e fica ao '
      'reabrir', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final tour = TourRobot($);
    await app.open(systemLocale: const Locale('pt', 'BR'), tour: true);
    await tour.nextUntilLevel();
    await tour.chooseLevel(RatingLevel.intermediate);
    await tour.start();
    await home.expectVisible();
    await $(HomeKeys.goalTitle).waitUntilVisible();
    final before = $.tester.widget<Text>(find.byKey(HomeKeys.goalTitle)).data;
    // "Aprender finais": o Curso de finais é o primeiro atalho.
    await $(HomeKeys.endgamesButton).scrollTo();
    double top(Key key) => $.tester.getTopLeft(find.byKey(key)).dy;
    expect(top(HomeKeys.endgamesButton), lessThan(top(HomeKeys.catalogButton)));

    await home.openSettings();
    final profile = ProfileRobot($);
    await profile.open();
    await profile.chooseGoal(GoalPreference.train);

    await app.restart();
    await $(HomeKeys.goalTitle).waitUntilVisible();
    expect(
      $.tester.widget<Text>(find.byKey(HomeKeys.goalTitle)).data,
      isNot(before),
    );
    // "Treinar finais": agora o treino vem antes do curso.
    await $(HomeKeys.catalogButton).scrollTo();
    expect(top(HomeKeys.catalogButton), lessThan(top(HomeKeys.endgamesButton)));
  });

  patrolTest('editar apelido e rating e reiniciar: mantidos', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final profile = ProfileRobot($);
    await app.open(systemLocale: const Locale('pt', 'BR'));

    await home.openSettings();
    await profile.open();
    await profile.enterNickname('Ana');
    await profile.saveData();
    await profile.chooseLevel(RatingLevel.advanced);
    profile.expectFields(name: 'Ana', rating: RatingLevel.advanced.rating);
    await profile.close();
    await profile.expectSummary('Sem conta · ${RatingLevel.advanced.rating}');

    await app.restart();

    await home.openSettings();
    await profile.expectSummary('Sem conta · ${RatingLevel.advanced.rating}');
    await profile.open();
    profile.expectFields(name: 'Ana', rating: RatingLevel.advanced.rating);
  });

  patrolTest('apelido vazio: usa o apelido padrão', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final profile = ProfileRobot($);
    await app.open(systemLocale: const Locale('pt', 'BR'));

    await home.openSettings();
    await profile.open();
    await profile.enterNickname('Ana');
    await profile.saveData();
    await profile.close();
    await profile.expectSummary('Sem conta · ${RatingLevel.casual.rating}');

    await profile.open();
    await profile.enterNickname('');
    await profile.saveData();
    await profile.close();

    await profile.expectSummary('Sem conta · ${RatingLevel.casual.rating}');
    await profile.open();
    profile.expectFields(name: 'Jogador', rating: RatingLevel.casual.rating);
  });

  patrolTest('"Seus dados" fechado sem salvar: nada muda', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final profile = ProfileRobot($);
    await app.open(systemLocale: const Locale('pt', 'BR'));

    await home.openSettings();
    await profile.open();
    await profile.enterNickname('Ana');
    await profile.saveData();

    await profile.enterNickname('Outro');
    await $(BackButton).tap();
    await profile.expectVisible();

    profile.expectFields(name: 'Ana', rating: RatingLevel.casual.rating);
  });
}
