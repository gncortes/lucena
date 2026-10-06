import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/lesson_rules.dart';
import 'package:lucena/domain/use_cases/star_challenge_rules.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:patrol/patrol.dart';

import '../../testing/board_gestures.dart';

/// Os desafios das estrelas: a lista e um desafio.
class StarChallengeRobot {
  const StarChallengeRobot(this.$);

  final PatrolIntegrationTester $;

  /// Da trilha da escola, pelo cartão dos desafios.
  Future<void> openFromSchool() async {
    await $(SchoolKeys.challengesButton).scrollTo().tap();
    await $(StarChallengeKeys.listScreen).waitUntilVisible();
  }

  Future<void> openChallenge(String piece, String level) async {
    await $(StarChallengeKeys.challenge(piece, level)).scrollTo().tap();
    await $(StarChallengeKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> go() async {
    await $(StarChallengeKeys.goButton).tap();
    await $.pumpAndSettle();
  }

  /// A casa da estrela acesa, lida da chave dela.
  String get star {
    final finder = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('starChallenge.star.');
    });
    final key = $.tester.widget(finder).key! as ValueKey<String>;
    return key.value.substring('starChallenge.star.'.length);
  }

  /// Leva a peça até a estrela (que tem que estar a um lance).
  Future<void> collect() async {
    final board = _board;
    final from = StarChallengeRules.pieceSquare(
      LessonRules.starsBoard(board.controller.fen),
    )!;
    final rect = $.tester.getRect(find.byKey(StarChallengeKeys.board));
    await $.tester.tapAt(squareCenter(rect, from.name));
    await $.pump();
    await $.tester.tapAt(squareCenter(rect, star));
    await $.pumpAndSettle();
  }

  String get collected =>
      $.tester.widget<Text>(find.byKey(StarChallengeKeys.collected)).data!;

  Future<void> back() async {
    await $(BackButton).tap();
    await $(StarChallengeKeys.listScreen).waitUntilVisible();
  }

  Chessboard get _board =>
      $.tester.widget<Chessboard>(find.byKey(StarChallengeKeys.board));
}
