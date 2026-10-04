import 'package:flutter/widgets.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/profile_robot.dart';
import 'robots/settings_robot.dart';

void main() {
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
    profile.expectInLevels('Abaixo de 1000');
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
