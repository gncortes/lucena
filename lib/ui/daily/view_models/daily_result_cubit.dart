import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/crowd/crowd_repository.dart';
import '../../../data/repositories/daily/daily_final_repository.dart';
import '../../../domain/models/crowd_stat.dart';
import '../../../domain/models/daily_final.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/use_cases/now.dart';

/// O resultado de um dia: a primeira tentativa gravada e o final dele (o
/// objetivo muda o título do empate). Num dia que já passou, o "x%
/// acertaram" (E1.24).
class DailyResultState {
  const DailyResultState({
    this.ready = false,
    this.daily,
    this.record,
    this.past = false,
    this.crowd,
  });

  final bool ready;
  final DailyFinal? daily;

  /// Nulo: o dia ainda não foi jogado até o fim.
  final DailyRecord? record;

  /// O dia já fechou ("Final de ontem"). No próprio dia nunca há número.
  final bool past;

  /// Nulo: o número não saiu (ou sem rede).
  final CrowdStat? crowd;

  /// Cumpriu o objetivo do final na primeira tentativa (decisão 13).
  bool get gotItRight {
    final outcome = record?.outcome;
    return outcome == DailyOutcome.won ||
        (outcome == DailyOutcome.drew &&
            daily?.position.goal == PositionGoal.draw);
  }
}

class DailyResultCubit extends Cubit<DailyResultState> {
  DailyResultCubit({
    required this.date,
    required this._daily,
    required this._crowd,
    required this._now,
  }) : super(const DailyResultState());

  /// O dia (`aaaa-mm-dd`).
  final String date;
  final DailyFinalRepository _daily;
  final CrowdRepository _crowd;
  final Now _now;

  Future<void> load() async {
    final day = DateTime.parse(date);
    final past = date.compareTo(DailyRecord.dayCode(_now())) < 0;
    final daily = await _daily.of(day);
    final record = await _daily.record(day);
    final crowd = past ? await _crowd.daily(date) : null;
    if (isClosed) return;
    emit(
      DailyResultState(
        ready: true,
        daily: daily,
        record: record,
        past: past,
        crowd: crowd,
      ),
    );
  }
}
