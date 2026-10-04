import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:patrol/patrol.dart';

class HomeRobot {
  const HomeRobot(this.$);

  final PatrolIntegrationTester $;

  Future<void> expectVisible() async {
    await $(HomeKeys.screen).waitUntilVisible();
    expect($(HomeKeys.mascot).visible, isTrue);
  }

  void expectMascot({required bool dark}) {
    final image = $.tester.widget<Image>(find.byKey(HomeKeys.mascot));
    expect(
      (image.image as AssetImage).assetName,
      dark
          ? 'assets/branding/mascot_dark.png'
          : 'assets/branding/mascot_light.png',
    );
  }

  void expectTagline(String text) {
    expect($.tester.widget<Text>(find.byKey(HomeKeys.tagline)).data, text);
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
