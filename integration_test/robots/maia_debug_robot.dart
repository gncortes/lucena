import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/maia_debug_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:patrol/patrol.dart';

/// Tela de depuração do Maia (Configurações, só em build de desenvolvimento).
class MaiaDebugRobot {
  const MaiaDebugRobot(this.$);

  final PatrolIntegrationTester $;

  /// A partir da tela inicial.
  Future<void> open() async {
    await $(HomeKeys.settingsButton).tap();
    await $(SettingsKeys.maiaDebugTile).scrollTo().tap();
    await expectVisible();
  }

  Future<void> expectVisible() async {
    await $(MaiaDebugKeys.screen).waitUntilVisible();
    await $(MaiaDebugKeys.evaluate).waitUntilVisible();
  }

  Future<void> enterFen(String fen) async {
    await $(MaiaDebugKeys.fen).enterText(fen);
    await $.pumpAndSettle();
  }

  Future<void> chooseLevel(int level) async {
    await $(MaiaDebugKeys.level(level)).scrollTo().tap();
    await $.pumpAndSettle();
  }

  /// Avalia e espera a resposta do modelo (ele roda fora do ritmo dos
  /// quadros, então não basta o pumpAndSettle).
  Future<void> evaluate() => _run(MaiaDebugKeys.evaluate);

  /// Mede a velocidade do modelo (várias contas seguidas) e espera o fim.
  Future<void> measure() => _run(MaiaDebugKeys.measure);

  /// O tempo típico por lance da última medição, em milissegundos.
  Future<int> measuredMedian() async {
    await $(MaiaDebugKeys.timing).scrollTo();
    return int.parse(
      RegExp(r'\d+').firstMatch(_text(MaiaDebugKeys.timing))![0]!,
    );
  }

  Future<void> _run(Key action) async {
    await $(action).scrollTo().tap();
    for (var guard = 0; guard < 600; guard++) {
      await $.pump(const Duration(milliseconds: 100));
      final button = $.tester.widget<FilledButton>(
        find.byKey(MaiaDebugKeys.evaluate),
      );
      if (button.onPressed != null) break;
    }
    await $.pumpAndSettle();
    expect(
      find.byKey(MaiaDebugKeys.failed),
      findsNothing,
      reason: 'o modelo não respondeu',
    );
  }

  Future<void> expectResult() async {
    await $(MaiaDebugKeys.elapsed).scrollTo();
    await $(MaiaDebugKeys.move(0)).scrollTo();
  }

  /// O lance mais provável e a chance dele, como aparecem (`a1a4`, `37.6%`).
  Future<void> expectBest(String move, {String? probability}) async {
    await $(MaiaDebugKeys.move(0)).scrollTo();
    expect(_text(MaiaDebugKeys.move(0)), move);
    if (probability != null) {
      expect(_text(MaiaDebugKeys.probability(0)), probability);
    }
  }

  /// Os lances mostrados com a chance de cada um, do mais provável para o
  /// menos.
  List<String> shownMoves() => [
    for (
      var index = 0;
      find.byKey(MaiaDebugKeys.move(index)).evaluate().isNotEmpty;
      index++
    )
      '${_text(MaiaDebugKeys.move(index))} '
          '${_text(MaiaDebugKeys.probability(index))}',
  ];

  Future<void> expectInvalidPosition() async {
    await $(MaiaDebugKeys.invalid).waitUntilExists();
    expect(find.byKey(MaiaDebugKeys.result), findsNothing);
  }

  String _text(Key key) => $.tester.widget<Text>(find.byKey(key)).data!;
}
