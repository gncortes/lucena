import 'package:flutter/widgets.dart';
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
    await profile.enterRating('1850');
    await profile.save();
    await profile.expectSummary('Ana · 1850');

    await app.restart();

    await home.openSettings();
    await profile.expectSummary('Ana · 1850');
    await profile.open();
    profile.expectFields(nickname: 'Ana', rating: '1850');
  });

  patrolTest('rating fora da faixa: erro traduzido e nada salvo', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final profile = ProfileRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('pt', 'BR'));

    await home.openSettings();
    await profile.open();
    await profile.enterNickname('Ana');
    await profile.enterRating('5000');
    await profile.save();

    await profile.expectVisible();
    profile.expectRatingError('Digite um número de 100 a 3500');

    await settings.back();
    await profile.expectSummary('Jogador · 1200');

    await app.restart();

    await home.openSettings();
    await profile.expectSummary('Jogador · 1200');
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
    await profile.expectSummary('Ana · 1200');

    await profile.open();
    await profile.enterNickname('');
    await profile.save();

    await profile.expectSummary('Player · 1200');
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
    await profile.enterRating('1850');
    await profile.save();

    await profile.open();
    await profile.enterNickname('Outro');
    await profile.enterRating('900');
    await settings.back();

    await profile.expectSummary('Ana · 1850');
    await profile.open();
    profile.expectFields(nickname: 'Ana', rating: '1850');
  });
}
