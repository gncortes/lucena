import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/use_cases/position_assessment.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:patrol/patrol.dart';

import '../../testing/e2e_dependencies.dart';

/// O personagem na partida: o retrato com a emoção, o nome e o balão. A
/// avaliação da posição é a combinada pelo cenário.
class CharacterRobot {
  const CharacterRobot(this.$);

  final PatrolIntegrationTester $;

  static const _linePrefix = 'freeBoard.character.line.';

  /// A partir de agora, a posição vale [centipawns] para o personagem.
  void evaluate(int centipawns) =>
      e2eEvaluation.fallback = Evaluation(centipawns: centipawns);

  /// O personagem acima do tabuleiro, com o nome ao lado do relógio dele.
  Future<void> expectCharacter(String name, int level) async {
    await $(FreeBoardKeys.characterBar).waitUntilExists();
    await $(find.text(name)).waitUntilVisible();
  }

  /// O id da fala no balão. Nulo: balão fechado.
  String? lineId() {
    final keys = find
        .byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(_linePrefix),
        )
        .evaluate()
        .map((e) => (e.widget.key! as ValueKey<String>).value)
        .toList();
    return keys.isEmpty ? null : keys.single.substring(_linePrefix.length);
  }

  /// O balão mostra uma fala da categoria [category] (`opponentBlunder`).
  Future<String> expectLine(String category) async {
    await _settle();
    final id = lineId();
    expect(id, isNotNull, reason: 'balão fechado');
    expect(id!.split('.')[1], category, reason: id);
    return id;
  }

  Future<void> expectNoBubble() async {
    await _settle();
    expect(find.byKey(FreeBoardKeys.speechBubble), findsNothing);
  }

  /// A emoção do retrato.
  Emotion emotion() {
    for (final emotion in Emotion.values) {
      if (find
          .byKey(FreeBoardKeys.characterAvatar(emotion))
          .evaluate()
          .isNotEmpty) {
        return emotion;
      }
    }
    fail('o retrato não está na tela');
  }

  Rect bubbleRect() => $.tester.getRect(find.byKey(FreeBoardKeys.speechBubble));

  Rect avatarRect() =>
      $.tester.getRect(find.byKey(FreeBoardKeys.characterAvatar(emotion())));

  // A avaliação e a fala chegam depois do lance.
  Future<void> _settle() async {
    await $.pump(const Duration(milliseconds: 300));
    await $.pumpAndSettle();
  }
}
