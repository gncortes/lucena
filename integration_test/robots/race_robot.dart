import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/all_modes_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:patrol/patrol.dart';

import '../../testing/board_gestures.dart';

/// A Corrida de problemas: abertura, corrida e resultado.
class RaceRobot {
  const RaceRobot(this.$);

  final PatrolIntegrationTester $;

  /// Pela tela de todos os modos, no item "Problemas".
  Future<void> openFromAllModes() async {
    await $(HomeKeys.allModesButton).tap();
    await $(AllModesKeys.item(RaceKeys.allModesItem)).scrollTo().tap();
    await $(RaceKeys.introView).waitUntilVisible();
  }

  Future<void> start() async {
    await $(RaceKeys.start).tap();
    await $(RaceKeys.gameView).waitUntilVisible();
    await $.pumpAndSettle();
  }

  /// Joga [from] -> [to] no problema da vez.
  Future<void> move(String from, String to) async {
    final rect = $.tester.getRect(find.byType(Chessboard));
    await $.tester.tapAt(squareCenter(rect, from));
    await $.pump();
    await $.tester.tapAt(squareCenter(rect, to));
    await $.pumpAndSettle();
  }

  /// O número grande de acertos do placar.
  int get corrects =>
      int.parse($.tester.widget<Text>(find.byKey(RaceKeys.count)).data!);

  Future<void> waitForResult() => $(RaceKeys.resultView).waitUntilVisible();
}
