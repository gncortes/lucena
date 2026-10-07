import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:patrol/patrol.dart';

import 'variant.dart';

/// Toca no caminho [key] da tela inicial. Fora do destaque (o nível ou a
/// escolha do jogador o escondeu), ele está em "Outros modos": abre a seção
/// antes.
Future<void> tapHomePath(PatrolIntegrationTester $, Key key) async {
  await $(HomeKeys.pathsTitle).waitUntilExists();
  if (find.byKey(key).evaluate().isEmpty) {
    await $(HomeKeys.otherModes).scrollTo().tap();
    await $.pumpAndSettle();
  }
  await $(key).scrollTo().tap();
}

class HomeRobot {
  const HomeRobot(this.$);

  final PatrolIntegrationTester $;

  /// Espera a tela pronta: o nome do app e os caminhos.
  Future<void> expectVisible() async {
    await $(HomeKeys.screen).waitUntilVisible();
    await $(HomeKeys.title).waitUntilVisible();
    await $(HomeKeys.pathsTitle).waitUntilExists();
  }

  /// O cumprimento do painel do jogador, com o apelido.
  Future<void> expectHello(String text) async {
    await $(HomeKeys.hello).waitUntilVisible();
    expectText($.tester.widget<Text>(find.byKey(HomeKeys.hello)).data, text);
  }

  /// A tela no tema escuro (ou claro).
  void expectDark({required bool dark}) {
    final context = $.tester.element(find.byKey(HomeKeys.screen));
    expect(
      Theme.of(context).brightness,
      dark ? Brightness.dark : Brightness.light,
    );
  }

  /// O nome do botão da Jornada, no idioma da tela.
  void expectJourneyLabel(String text) {
    final label = $.tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(HomeKeys.journeyButton),
            matching: find.byType(Text),
          ),
        )
        .first
        .data;
    expectText(label, text);
  }

  /// Com a tela espelhada (direita para a esquerda), o botão fica à esquerda.
  void expectSettingsButtonOnLeft() {
    final button = $.tester.getCenter(find.byKey(HomeKeys.settingsButton));
    final width = $.tester.getSize(find.byKey(HomeKeys.screen)).width;
    expect(button.dx, lessThan(width / 2));
  }

  /// "Continuar" no cartão do adversário atual: abre o próximo desafio.
  Future<void> continueJourney() async {
    await $(HomeKeys.whereContinue).scrollTo().tap();
    await $(JourneyKeys.challengeScreen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> openSettings() async {
    await $(HomeKeys.settingsButton).tap();
  }
}
