import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

/// O tour da primeira abertura.
class TourRobot {
  const TourRobot(this.$);

  final PatrolIntegrationTester $;

  Future<void> expectStep(TourStep step) async {
    await $(TourKeys.step(step)).waitUntilVisible();
  }

  void expectNotOpen() => expect(find.byKey(TourKeys.screen), findsNothing);

  Future<void> next() async {
    await $(TourKeys.nextButton).tap();
    await $.pumpAndSettle();
  }

  /// Avança até o passo do nível.
  Future<void> nextUntilLevel() async {
    while (find.byKey(TourKeys.step(TourStep.level)).evaluate().isEmpty) {
      await next();
    }
  }

  Future<void> chooseLevel(RatingLevel level) async {
    await $(TourKeys.level(level)).scrollTo().tap();
    await $.pumpAndSettle();
  }

  Future<void> start() async {
    await $(TourKeys.startButton).tap();
    await $.pumpAndSettle();
  }

  Future<void> skip() async {
    await $(TourKeys.skipButton).tap();
    await $.pumpAndSettle();
  }

  /// Em Configurações, "Rever o tour".
  Future<void> openFromSettings() async {
    await $(SettingsKeys.tourTile).scrollTo().tap();
    await $(TourKeys.screen).waitUntilVisible();
  }
}
