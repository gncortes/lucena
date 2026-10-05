import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/ui/core/keys/custom_position_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:patrol/patrol.dart';

import '../../testing/board_gestures.dart';

import 'variant.dart';

/// Tela de posição personalizada: editor, FEN, vez e objetivo.
class CustomPositionRobot {
  const CustomPositionRobot(this.$);

  final PatrolIntegrationTester $;

  /// A partir da tela inicial.
  Future<void> open() async {
    await $(HomeKeys.customPositionButton).scrollTo().tap();
    await expectVisible();
  }

  Future<void> expectVisible() async {
    await $(CustomPositionKeys.screen).waitUntilVisible();
    await $(CustomPositionKeys.editor).waitUntilVisible();
  }

  Future<void> typeFen(String fen) async {
    await $(CustomPositionKeys.fenField).scrollTo().enterText(fen);
    await $.pumpAndSettle();
    expectFen(fen);
  }

  /// Escolhe a peça na paleta e toca nas casas.
  Future<void> place(Piece piece, List<String> squares) async {
    await $(CustomPositionKeys.palette(piece)).scrollTo().tap();
    await $(CustomPositionKeys.editor).scrollTo();
    for (final square in squares) {
      final board = $.tester.getRect(find.byKey(CustomPositionKeys.editor));
      await $.tester.tapAt(squareCenter(board, square));
      await $.pumpAndSettle();
    }
  }

  Future<void> chooseTurn(Side side) async {
    await $(CustomPositionKeys.turn(side)).scrollTo().tap();
    await $.pumpAndSettle();
  }

  Future<void> chooseGoal(PositionGoal goal) async {
    await $(CustomPositionKeys.goal(goal)).scrollTo().tap();
    await $.pumpAndSettle();
  }

  Future<void> expectError(String text) async {
    await $(CustomPositionKeys.error).scrollTo();
    expectText(
      $.tester.widget<Text>(find.byKey(CustomPositionKeys.error)).data,
      text,
    );
    final button = $.tester.widget<FilledButton>(
      find.byKey(CustomPositionKeys.continueButton),
    );
    expect(button.onPressed, isNull);
  }

  void expectNoError() {
    expect(find.byKey(CustomPositionKeys.error), findsNothing);
  }

  /// O FEN que o campo mostra.
  void expectFen(String fen) {
    final field = $.tester.widget<TextField>(
      find.byKey(CustomPositionKeys.fenField),
    );
    expect(field.controller?.text, fen);
  }

  Future<void> continueToSetup() async {
    await $(CustomPositionKeys.continueButton).tap();
    await $.pumpAndSettle();
  }
}
