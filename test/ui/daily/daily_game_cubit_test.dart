import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/daily_final.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/kpk_outcome.dart';
import 'package:lucena/domain/models/wdl.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/position_judge.dart';
import 'package:lucena/ui/daily/view_models/daily_game_cubit.dart';
import 'package:lucena/ui/free_board/view_models/free_board_state.dart';

import '../../../testing/fakes/fake_activity_repository.dart';
import '../../../testing/fakes/fake_daily_final_repository.dart';
import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_positions_repository.dart';

// Torre e rei contra rei: a torre em h5 "estraga" (empata); fora disso, as
// brancas ganham.
class _RookJudge implements PositionJudge {
  @override
  Future<Wdl?> evaluate(Position position) async {
    final rookOnH5 = position.board.roleAt(Square.h5) == Role.rook;
    final white = rookOnH5 ? Wdl.draw : Wdl.win;
    return position.turn == Side.white ? white : white.flipped;
  }
}

void main() {
  final rook = samplePositions.firstWhere((p) => p.id == 'basic.rook.0001');
  final start = GameRules.fromFen(rook.fen)!;
  const mode = GameMode(
    opponent: OpponentKind.maia,
    level: 1400,
    userSide: Side.white,
    goal: PositionGoal.win,
    dailyDate: '2026-10-22',
  );

  FreeBoardState game(List<String> ucis, {GameEnd? end}) {
    var position = start;
    for (final uci in ucis) {
      position = GameRules.play(position, Move.parse(uci)!)!.position;
    }
    return FreeBoardState(
      start: start,
      position: position,
      ucis: ucis,
      mode: mode,
      forcedEnd: end,
    );
  }

  late FakeDailyFinalRepository daily;
  late FakeActivityRepository activity;

  Future<DailyGameCubit> open() async {
    daily = FakeDailyFinalRepository(position: rook);
    activity = FakeActivityRepository();
    final cubit = DailyGameCubit(
      date: '2026-10-22',
      daily: daily,
      activity: activity,
      kpk: FakeKpkRepository(FakeKpkOracle(fallback: KpkOutcome.outside)),
      engine: _RookJudge(),
    );
    await cubit.load();
    return cubit;
  }

  const won = GameEnd(GameEndReason.checkmate, winner: Side.white);
  const lost = GameEnd(GameEndReason.resign, winner: Side.black);

  test(
    'cada lance da pessoa ganha uma cor pelo que fez com o resultado',
    () async {
      final cubit = await open();
      cubit
        ..update(game(['h1h5']))
        ..update(game(['h1h5', 'd6c6']))
        ..update(game(['h1h5', 'd6c6', 'h5h1']));
      await cubit.settle();
      // Para a torre em h5: estragou. De volta, recupera: certo.
      expect(cubit.state.squares, [DailySquare.bad, DailySquare.right]);
      expect(activity.marked, {DateTime(2026, 10, 22)});
      await cubit.close();
    },
  );

  test('a primeira tentativa do dia é a que fica gravada', () async {
    final cubit = await open();
    cubit.update(game(['h1h2', 'd6c6', 'h2h5'], end: lost));
    await cubit.settle();
    final first = cubit.state.record;
    expect(first?.outcome, DailyOutcome.lost);
    expect(first?.fulfilled, isFalse);
    expect(first?.squares, [DailySquare.right, DailySquare.bad]);
    expect(first?.moves, 2);

    // Jogar de novo: as cores recomeçam, o gravado não muda.
    cubit
      ..update(game(const []))
      ..update(game(['h1h2'], end: won));
    await cubit.settle();
    expect(cubit.state.squares, [DailySquare.right]);
    expect(cubit.state.record?.outcome, DailyOutcome.lost);
    expect(daily.records.values.single.outcome, DailyOutcome.lost);
    await cubit.close();
  });

  test('desfazer tira a cor do lance desfeito', () async {
    final cubit = await open();
    cubit
      ..update(game(['h1h5', 'd6c6']))
      ..update(game(const []))
      ..update(game(['h1h2']));
    await cubit.settle();
    expect(cubit.state.squares, [DailySquare.right]);
    await cubit.close();
  });

  test('o objetivo de empatar se cumpre com o empate', () {
    expect(DailyOutcome.drew.fulfills(PositionGoal.draw), isTrue);
    expect(DailyOutcome.drew.fulfills(PositionGoal.win), isFalse);
    expect(DailyOutcome.lost.fulfills(PositionGoal.draw), isFalse);
    expect(DailyOutcome.of(won, Side.white), DailyOutcome.won);
    expect(DailyOutcome.of(won, Side.black), DailyOutcome.lost);
    expect(
      DailyOutcome.of(const GameEnd(GameEndReason.stalemate), Side.white),
      DailyOutcome.drew,
    );
  });
}
