import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/game_setup_keys.dart';
import 'package:patrol/patrol.dart';

/// Tela de configuração da partida.
class GameSetupRobot {
  const GameSetupRobot(this.$);

  final PatrolIntegrationTester $;

  Future<void> expectVisible() async {
    await $(GameSetupKeys.screen).waitUntilVisible();
    await $(GameSetupKeys.startButton).waitUntilVisible();
  }

  Future<void> chooseSide(Side side) async {
    await $(GameSetupKeys.side(side)).scrollTo().tap();
    await $.pumpAndSettle();
  }

  /// Ajusta o tempo de `user` ou `opponent` pelos botões de menos e mais.
  Future<void> setTime(
    String who, {
    required int minutes,
    required int increment,
  }) async {
    await _stepTo(who, 'minutes', minutes);
    await _stepTo(who, 'increment', increment);
  }

  Future<void> _stepTo(String who, String field, int target) async {
    for (var guard = 0; guard < 200; guard++) {
      final current = int.parse(_text(GameSetupKeys.value(who, field)));
      if (current == target) return;
      final key = current < target
          ? GameSetupKeys.increase(who, field)
          : GameSetupKeys.decrease(who, field);
      await $(key).scrollTo().tap();
    }
    fail('não chegou em $target em $who.$field');
  }

  void expectTime(String who, {required int minutes, required int increment}) {
    expect(_text(GameSetupKeys.value(who, 'minutes')), '$minutes');
    expect(_text(GameSetupKeys.value(who, 'increment')), '$increment');
  }

  Future<void> expectZeroTimeError() async {
    await $(GameSetupKeys.timeError).scrollTo();
    final start = $.tester.widget<FilledButton>(
      find.byKey(GameSetupKeys.startButton),
    );
    expect(start.onPressed, isNull);
  }

  void expectPreviewOrientation(Side side) {
    final preview = $.tester.widget<StaticChessboard>(
      find.byKey(GameSetupKeys.preview),
    );
    expect(preview.orientation, side);
  }

  /// O objetivo da posição como aparece antes de jogar (`Win`, `Defend`).
  Future<void> expectGoal(String text) async {
    await $(GameSetupKeys.goal).scrollTo();
    expect(
      find.descendant(
        of: find.byKey(GameSetupKeys.goal),
        matching: find.text(text),
      ),
      findsOneWidget,
    );
  }

  Future<void> start() async {
    await $(GameSetupKeys.startButton).tap();
    await $.pumpAndSettle();
  }

  String _text(Key key) => $.tester.widget<Text>(find.byKey(key)).data!;
}
