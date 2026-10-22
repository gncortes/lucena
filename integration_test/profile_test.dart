import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/profile_robot.dart';
import 'robots/settings_robot.dart';
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
    // "Aprender finais": as Aulas de finais saem da lista.
    expect(find.byKey(HomeKeys.endgamesButton), findsNothing);

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
    await $(HomeKeys.endgamesButton).scrollTo();
    expect(find.byKey(HomeKeys.catalogButton), findsNothing);
  });

  patrolTest('editar apelido e rating e reiniciar: mantidos', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final profile = ProfileRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));

    await home.openSettings();
    await profile.open();
    await profile.enterNickname('Ana');
    await profile.chooseLevel(RatingLevel.advanced);
    await profile.save();
    await profile.expectSummary('Ana · Advanced');

    await app.restart();

    await home.openSettings();
    await profile.expectSummary('Ana · Advanced');
    await profile.open();
    profile.expectFields(nickname: 'Ana', level: 'Advanced');
  });

  patrolTest('rating: faixas traduzidas no painel; fechar sem confirmar não '
      'muda nada', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final profile = ProfileRobot($);
    await app.open(systemLocale: const Locale('pt', 'BR'));

    await home.openSettings();
    await profile.expectSummary('Jogador · Casual');
    await profile.open();

    await profile.openLevels();
    profile.expectInLevels('Iniciante');
    profile.expectInLevels('Estou aprendendo as regras');
    profile.expectInLevels('Intermediário');
    profile.expectInLevels('1300 a 1599');
    profile.expectInLevels('Mestre');
    profile.expectInLevels('2200 ou mais');
    await profile.markLevel(RatingLevel.expert);
    await profile.dismissLevels();
    profile.expectFields(nickname: '', level: 'Casual');

    await profile.chooseLevel(RatingLevel.master);
    profile.expectFields(nickname: '', level: 'Mestre');
    await profile.save();

    await profile.expectSummary('Jogador · Mestre');
  });

  patrolTest('apelido vazio: usa o apelido padrão', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final profile = ProfileRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));

    await home.openSettings();
    await profile.open();
    await profile.enterNickname('Ana');
    await profile.save();
    await profile.expectSummary('Ana · Casual');

    await profile.open();
    await profile.enterNickname('');
    await profile.save();

    await profile.expectSummary('Player · Casual');
  });

  patrolTest('editar e sair sem salvar: nada muda', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final profile = ProfileRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));

    await home.openSettings();
    await profile.open();
    await profile.enterNickname('Ana');
    await profile.chooseLevel(RatingLevel.advanced);
    await profile.save();

    await profile.open();
    await profile.enterNickname('Outro');
    await profile.chooseLevel(RatingLevel.beginner);
    await settings.back();

    await profile.expectSummary('Ana · Advanced');
    await profile.open();
    profile.expectFields(nickname: 'Ana', level: 'Advanced');
  });
}
