import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/lesson_rules.dart';
import 'package:lucena/domain/use_cases/star_challenge_rules.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:chessground/chessground.dart' show Chessboard;
import 'package:patrol/patrol.dart';

import '../../testing/board_gestures.dart';
import 'app_robot.dart';
import 'star_challenge_robot.dart';

/// Plays the existing star board through taps. The shortest legal path is
/// calculated from the displayed board, without changing app/repository state.
class TrainingAcceptanceRobot {
  const TrainingAcceptanceRobot(this.$);
  final PatrolIntegrationTester $;

  Future<void> finishStars({int points = 30}) async {
    final stars = StarChallengeRobot($);
    await stars.go();
    for (
      var collected = 0;
      stars.points < points && collected < 40;
      collected++
    ) {
      final finder = find.byKey(StarChallengeKeys.board);
      final widget = $.tester.widget<Chessboard>(finder);
      final board = LessonRules.starsBoard(widget.controller.fen);
      final target = Square.fromName(stars.star);
      final start = StarChallengeRules.pieceSquare(board)!;
      final queue = <(Board, List<Square>)>[
        (board, [start]),
      ];
      final seen = <Square>{start};
      List<Square>? path;
      for (var i = 0; i < queue.length && path == null; i++) {
        final (position, route) = queue[i];
        for (final to in StarChallengeRules.movesOf(position, route.last)) {
          if (!seen.add(to)) continue;
          final next = [...route, to];
          if (to == target) {
            path = next;
            break;
          }
          queue.add((StarChallengeRules.move(position, route.last, to)!, next));
        }
      }
      expect(path, isNotNull, reason: 'generated star must be reachable');
      for (var i = 1; i < path!.length; i++) {
        final rect = $.tester.getRect(finder);
        await $.tester.tapAt(squareCenter(rect, path[i - 1].name));
        await $.pump();
        await $.tester.tapAt(squareCenter(rect, path[i].name));
        await $.pumpAndSettle();
      }
    }
    expect(stars.points, greaterThanOrEqualTo(points));
    await AppRobot($).advanceTime(const Duration(minutes: 3));
    await $(StarChallengeKeys.result).waitUntilVisible();
  }
}
