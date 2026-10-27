import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/ui/core/keys/all_modes_keys.dart';
import 'package:patrol/patrol.dart';

import 'variant.dart';

/// Abre "Todos os modos" pelo "Ver mais" dos atalhos da tela inicial.
Future<void> openAllModes(PatrolIntegrationTester $) async {
  await $(HomeKeys.shortcutsSeeMore).scrollTo().tap();
  await $(AllModesKeys.screen).waitUntilVisible();
}

/// Abre o modo [mode] (`freeBoard`, `custom`, `achievements`...) pela tela
/// "Todos os modos".
Future<void> openFromAllModes(PatrolIntegrationTester $, String mode) async {
  await openAllModes($);
  await $(AllModesKeys.item(mode)).scrollTo().tap();
}

/// Abre o caminho [path] da tela inicial pelo atalho dele. Fora dos quatro
/// atalhos (é o cartão azul ou o nível o deixou de fora), abre por "Todos os
/// modos".
Future<void> tapHomePath(PatrolIntegrationTester $, HomePath path) async {
  await $(HomeKeys.shortcutsTitle).waitUntilExists();
  final key = switch (path) {
    HomePath.journey => HomeKeys.journeyButton,
    HomePath.endgames || HomePath.forYou => HomeKeys.endgamesButton,
    HomePath.train => HomeKeys.catalogButton,
    HomePath.speedrun => HomeKeys.speedrunButton,
    HomePath.race => HomeKeys.raceButton,
    HomePath.learn => null,
  };
  if (key != null && find.byKey(key).evaluate().isNotEmpty) {
    await $(key).scrollTo().tap();
    return;
  }
  await openFromAllModes($, path.name);
}

class HomeRobot {
  const HomeRobot(this.$);

  final PatrolIntegrationTester $;

  /// Espera a tela pronta: o nome do app e os atalhos.
  Future<void> expectVisible() async {
    await $(HomeKeys.screen).waitUntilVisible();
    await $(HomeKeys.title).waitUntilVisible();
    await $(HomeKeys.shortcutsTitle).waitUntilExists();
  }

  /// O rating no alto, ao lado do nome do app (ou "Começando").
  Future<void> expectRating() async {
    await $(HomeKeys.playerCard).waitUntilVisible();
  }

  /// A tela no tema escuro (ou claro).
  void expectDark({required bool dark}) {
    final context = $.tester.element(find.byKey(HomeKeys.screen));
    expect(
      Theme.of(context).brightness,
      dark ? Brightness.dark : Brightness.light,
    );
  }

  /// O lugar do cartão azul (a Jornada), no idioma da tela.
  void expectJourneyLabel(String text) {
    expectText(
      $.tester.widget<Text>(find.byKey(HomeKeys.heroLabel)).data,
      text,
    );
  }

  /// Com a tela espelhada (direita para a esquerda), o botão fica à esquerda.
  void expectSettingsButtonOnLeft() {
    final button = $.tester.getCenter(find.byKey(HomeKeys.settingsButton));
    final width = $.tester.getSize(find.byKey(HomeKeys.screen)).width;
    expect(button.dx, lessThan(width / 2));
  }

  /// O botão do cartão azul da Jornada: abre o próximo desafio.
  Future<void> continueJourney() async {
    await $(HomeKeys.goalAction).scrollTo().tap();
    await $(JourneyKeys.challengeScreen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> openSettings() async {
    await $(HomeKeys.settingsButton).tap();
  }
}
