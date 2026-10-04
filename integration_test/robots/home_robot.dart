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
}
