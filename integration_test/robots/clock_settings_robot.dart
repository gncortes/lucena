import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/clock_settings.dart';
import 'package:lucena/ui/core/keys/board_settings_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:patrol/patrol.dart';

/// Tela de preferências do relógio (posição e vibração).
class ClockSettingsRobot {
  const ClockSettingsRobot(this.$);

  final PatrolIntegrationTester $;

  /// A partir de Configurações.
  Future<void> open() async {
    await $(SettingsKeys.clockTile).scrollTo().tap();
    await expectVisible();
  }

  Future<void> expectVisible() async {
    await $(BoardSettingsKeys.clockScreen).waitUntilVisible();
  }

  /// Abre o painel, marca a posição e confirma.
  Future<void> choosePosition(ClockPosition position) async {
    await openPositions();
    await $(BoardSettingsKeys.clockPositionOption(position)).tap();
    await $(BoardSettingsKeys.choiceConfirmButton).tap();
    await $.pumpAndSettle();
    expect(find.byKey(BoardSettingsKeys.choiceSheet), findsNothing);
  }

  Future<void> openPositions() async {
    await $(BoardSettingsKeys.clockPositionTile).tap();
    await $(BoardSettingsKeys.choiceSheet).waitUntilVisible();
  }

  Future<void> toggleVibration() async {
    await $(BoardSettingsKeys.clockVibrationSwitch).tap();
    await $.pumpAndSettle();
  }

  void expectVibration({required bool enabled}) {
    final tile = $.tester.widget<SwitchListTile>(
      find.byKey(BoardSettingsKeys.clockVibrationSwitch),
    );
    expect(tile.value, enabled);
  }

  void expectPositionValue(String text) {
    expect(
      $.tester
          .widget<Text>(find.byKey(BoardSettingsKeys.clockPositionValue))
          .data,
      text,
    );
  }
}
