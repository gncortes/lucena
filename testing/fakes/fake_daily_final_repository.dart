import 'package:lucena/data/repositories/daily/daily_final_repository.dart';
import 'package:lucena/domain/models/daily_final.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/use_cases/streak_rules.dart';

import 'fake_positions_repository.dart';

/// O mesmo final todo dia ([position], nulo: nenhum) e as tentativas na
/// memória.
class FakeDailyFinalRepository implements DailyFinalRepository {
  FakeDailyFinalRepository({
    EndgamePosition? position,
    bool none = false,
    Map<DateTime, DailyRecord>? records,
  }) : position = none ? null : position ?? samplePositions.first,
       records = {...?records};

  final EndgamePosition? position;
  final Map<DateTime, DailyRecord> records;

  @override
  Future<DailyFinal?> of(DateTime at) async => switch (position) {
    null => null,
    final position => DailyFinal(date: StreakRules.day(at), position: position),
  };

  @override
  Future<DailyRecord?> record(DateTime at) async =>
      records[StreakRules.day(at)];

  @override
  Future<void> saveFirst(DailyRecord record) async =>
      records.putIfAbsent(StreakRules.day(record.date), () => record);
}
