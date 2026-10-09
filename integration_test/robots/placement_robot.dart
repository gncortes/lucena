import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/placement_keys.dart';
import 'package:patrol/patrol.dart';

import 'variant.dart';

/// O teste de nível (T52): a abertura, as perguntas e o resultado.
class PlacementRobot {
  const PlacementRobot(this.$);

  final PatrolIntegrationTester $;

  Future<void> expectIntro() async {
    await $(PlacementKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> start() async {
    await $(PlacementKeys.start).scrollTo().tap();
    await $.pumpAndSettle();
  }

  /// O teste começado: continua de onde parou.
  Future<void> resume() async {
    await $(PlacementKeys.resume).scrollTo().tap();
    await $.pumpAndSettle();
  }

  /// A pergunta [number] de 20 na tela.
  Future<void> expectQuestion(int number) async {
    await $(PlacementKeys.prompt).waitUntilVisible();
    await $(PlacementKeys.board).waitUntilExists();
    expectText(
      $.tester.widget<Text>(find.byKey(PlacementKeys.counter)).data,
      'Question $number of 20',
    );
  }

  /// Responde "Não sei" [count] vezes.
  Future<void> dontKnow(int count) async {
    for (var i = 0; i < count; i++) {
      await $(PlacementKeys.dontKnow).tap();
      await $.pumpAndSettle();
    }
  }

  Future<void> expectResult() async {
    await $(PlacementKeys.result).waitUntilVisible();
    await $(PlacementKeys.level).waitUntilVisible();
    await $(PlacementKeys.useLevel).waitUntilVisible();
  }

  Future<void> useLevel() async {
    await $(PlacementKeys.useLevel).tap();
    await $.pumpAndSettle();
  }
}
