import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/all_modes_keys.dart';
import 'package:lucena/domain/use_cases/race_turn.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:lucena/ui/race/view_models/race_cubit.dart';
import 'package:patrol/patrol.dart';

import 'home_robot.dart';
import '../../testing/board_gestures.dart';

/// A Corrida de problemas: abertura, corrida e resultado.
class RaceRobot {
  const RaceRobot(this.$);

  final PatrolIntegrationTester $;

  /// Pela tela de todos os modos, no item "Problemas".
  Future<void> openFromAllModes() async {
    await openAllModes($);
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
    final side = _turn.problem.side;
    await $.tester.tapAt(squareCenter(rect, from, orientation: side));
    await $.pump();
    await $.tester.tapAt(squareCenter(rect, to, orientation: side));
    await $.pumpAndSettle();
  }

  /// A vez do problema sorteado (o banco sorteia dentro da faixa, então o
  /// cenário lê o lance certo em vez de fixar casas).
  RaceTurn get _turn => $.tester
      .element(find.byKey(RaceKeys.gameView))
      .read<RaceCubit>()
      .state
      .turn!;

  /// Resolve o problema da vez pela sequência mais rápida, até o placar subir.
  Future<void> solve() async {
    final before = corrects;
    while (corrects == before) {
      final best = _turn.node.best.firstWhere((uci) => uci.length == 4);
      await move(best.substring(0, 2), best.substring(2));
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
    }
  }

  /// Um lance legal que não é o mais rápido (sem roque nem promoção).
  Future<void> miss() async {
    final turn = _turn;
    final position = Chess.fromSetup(Setup.parseFen(turn.fen));
    for (final MapEntry(key: from, value: targets)
        in position.legalMoves.entries) {
      final role = position.board.roleAt(from);
      for (final to in targets.squares) {
        if (role == Role.king && (from.file - to.file).abs() > 1) continue;
        if (role == Role.pawn &&
            (to.rank == Rank.first || to.rank == Rank.eighth)) {
          continue;
        }
        final uci = '${from.name}${to.name}';
        if (turn.judge(uci) == RaceMoveKind.optimal) continue;
        return move(from.name, to.name);
      }
    }
    fail('nenhum lance errado em ${turn.fen}');
  }

  /// O número grande de acertos do placar.
  int get corrects =>
      int.parse($.tester.widget<Text>(find.byKey(RaceKeys.count)).data!);

  Future<void> waitForResult() => $(RaceKeys.resultView).waitUntilVisible();
}
