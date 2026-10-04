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
}
