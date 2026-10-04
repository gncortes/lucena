import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/ui/core/keys/board_settings_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:patrol/patrol.dart';

/// Tela de comportamento do tabuleiro (jeito de mover, ajudas, notação).
class BoardBehaviorRobot {
  const BoardBehaviorRobot(this.$);

  final PatrolIntegrationTester $;

  /// A partir de Configurações.
  Future<void> open() async {
    await $(SettingsKeys.boardBehaviorTile).scrollTo().tap();
    await expectVisible();
  }

  Future<void> expectVisible() async {
    await $(BoardSettingsKeys.behaviorScreen).waitUntilVisible();
  }

  /// Abre o painel, marca o jeito de mover e confirma.
  Future<void> chooseMoveMethod(MoveMethod method) async {
    await openMoveMethods();
    await $(BoardSettingsKeys.moveMethodOption(method)).tap();
    await confirmChoice();
  }

  Future<void> openMoveMethods() async {
    await $(BoardSettingsKeys.moveMethodTile).tap();
    await $(BoardSettingsKeys.choiceSheet).waitUntilVisible();
  }

  /// Abre o painel, marca a notação e confirma.
  Future<void> chooseNotation(MoveNotation notation) async {
    await $(BoardSettingsKeys.notationTile).scrollTo().tap();
    await $(BoardSettingsKeys.choiceSheet).waitUntilVisible();
    await $(BoardSettingsKeys.notationOption(notation)).tap();
    await confirmChoice();
  }

  Future<void> confirmChoice() async {
    await $(BoardSettingsKeys.choiceConfirmButton).tap();
    await $.pumpAndSettle();
    expect(find.byKey(BoardSettingsKeys.choiceSheet), findsNothing);
  }

  Future<void> toggleLegalMoves() async {
    await $(BoardSettingsKeys.legalMovesSwitch).tap();
    await $.pumpAndSettle();
  }

  void expectLegalMoves({required bool enabled}) {
    final tile = $.tester.widget<SwitchListTile>(
      find.byKey(BoardSettingsKeys.legalMovesSwitch),
    );
    expect(tile.value, enabled);
  }

  void expectMoveMethodValue(String text) {
    expect(_text(BoardSettingsKeys.moveMethodValue), text);
  }

  void expectNotationValue(String text) {
    expect(_text(BoardSettingsKeys.notationValue), text);
  }

  String? _text(Key key) => $.tester.widget<Text>(find.byKey(key)).data;
}
