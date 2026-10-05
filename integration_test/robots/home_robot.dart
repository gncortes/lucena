import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:patrol/patrol.dart';

import 'variant.dart';

class HomeRobot {
  const HomeRobot(this.$);

  final PatrolIntegrationTester $;

  /// Espera a tela pronta: o nome do app e o botão da Jornada.
  Future<void> expectVisible() async {
    await $(HomeKeys.screen).waitUntilVisible();
    await $(HomeKeys.title).waitUntilVisible();
    await $(HomeKeys.journeyButton).waitUntilExists();
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

  Future<void> openSettings() async {
    await $(HomeKeys.settingsButton).tap();
  }
}
