import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/core/keys/game_setup_keys.dart';
import 'package:lucena/ui/game_setup/widgets/custom_pace_sheet.dart';
import 'package:patrol/patrol.dart';

import 'variant.dart';

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

  /// Ajusta o tempo de `user` ou `opponent` no painel "Personalizar ritmo",
  /// sem mexer no do outro lado: desliga "mesmo tempo para os dois".
  Future<void> setTime(
    String who, {
    required int minutes,
    required int increment,
  }) async {
    await _openCustom();
    await _slide(who, 'minutes', CustomPaceSteps.minutes, minutes);
    await _slide(who, 'increment', CustomPaceSteps.increments, increment);
    await $(GameSetupKeys.customConfirm).tap();
    await $.pumpAndSettle();
  }

  Future<void> _openCustom() async {
    await $(GameSetupKeys.customPace).scrollTo().tap();
    await $(GameSetupKeys.customSheet).waitUntilVisible();
    final same = $.tester.widget<SwitchListTile>(
      find.byKey(GameSetupKeys.customSame),
    );
    if (same.value) {
      await $(GameSetupKeys.customSame).tap();
      await $.pumpAndSettle();
    }
  }

  // O controle deslizante anda por passos: o cenário pede o valor direto.
  Future<void> _slide(
    String who,
    String field,
    List<int> steps,
    int value,
  ) async {
    final index = steps.indexOf(value);
    if (index == -1) fail('$value não é um passo de $field');
    final key = GameSetupKeys.customSlider(who, field);
    await $(key).scrollTo();
    $.tester.widget<Slider>(find.byKey(key)).onChanged!(index.toDouble());
    await $.pumpAndSettle();
  }

  /// Confere, no painel "Personalizar ritmo", o tempo de `user` ou
  /// `opponent`.
  Future<void> expectTime(
    String who, {
    required int minutes,
    required int increment,
  }) async {
    await $(GameSetupKeys.customPace).scrollTo().tap();
    await $(GameSetupKeys.customSheet).waitUntilVisible();
    // Com o mesmo tempo para os dois, só o primeiro bloco aparece.
    final shown = find.byKey(GameSetupKeys.customValue(who)).evaluate().isEmpty
        ? 'user'
        : who;
    expect(
      _text(GameSetupKeys.customValue(shown)),
      startsWith('$minutes+$increment'),
    );
    await $(GameSetupKeys.customConfirm).tap();
    await $.pumpAndSettle();
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
    expectTextIn(find.byKey(GameSetupKeys.goal), text);
  }

  /// Os resultados do histórico, de cima para baixo (`Win`, `Draw`).
  Future<void> expectAttempts(List<String> outcomes) async {
    for (final (index, outcome) in outcomes.indexed) {
      await $(GameSetupKeys.attempt(index)).scrollTo();
      expectTextIn(find.byKey(GameSetupKeys.attempt(index)), outcome);
    }
    expect(find.byKey(GameSetupKeys.attempt(outcomes.length)), findsNothing);
  }

  Future<void> chooseOpponent(OpponentKind kind) async {
    await $(GameSetupKeys.opponent(kind)).scrollTo().tap();
    await $.pumpAndSettle();
  }

  Future<void> expectOpponent(OpponentKind kind) async {
    await $(GameSetupKeys.opponent(kind)).scrollTo();
    // O treino só oferece adversários de verdade.
    expect(
      find.byKey(GameSetupKeys.opponent(OpponentKind.twoPlayers)),
      findsNothing,
    );
    for (final other in OpponentKind.training) {
      final tile = $.tester.widget<ListTile>(
        find.byKey(GameSetupKeys.opponent(other)),
      );
      expect(tile.selected, other == kind, reason: other.name);
    }
  }

  Future<void> chooseLevel(int level) async {
    await $(GameSetupKeys.level(level)).scrollTo().tap();
    await $.pumpAndSettle();
  }

  /// O nível do Maia marcado e o aviso do nível sugerido pelo perfil.
  Future<void> expectLevel(int level, {String? suggestion}) async {
    await $(GameSetupKeys.level(level)).scrollTo();
    final chip = $.tester.widget<ChoiceChip>(
      find.byKey(GameSetupKeys.level(level)),
    );
    expect(chip.selected, isTrue);
    if (suggestion != null) {
      await $(GameSetupKeys.suggestedLevel).scrollTo();
      expectText(_text(GameSetupKeys.suggestedLevel), suggestion);
    }
  }

  void expectNoLevels() {
    expect(find.byKey(GameSetupKeys.levels), findsNothing);
  }

  Future<void> start() async {
    await $(GameSetupKeys.startButton).tap();
    await $.pumpAndSettle();
  }

  String _text(Key key) => $.tester.widget<Text>(find.byKey(key)).data!;
}
