import '../models/history_filter.dart';
import '../models/pace.dart';
import '../models/player_rating.dart';
import '../models/speedrun.dart';
import '../models/speedrun_pace.dart';
import 'speedrun_category.dart';
import 'speedrun_score.dart';

/// Uma linha das abas Clássico e Maratona: um speedrun já com o ritmo.
class SpeedrunHistoryRow {
  const SpeedrunHistoryRow({
    required this.speedrun,
    required this.category,
    required this.attempts,
    required this.finished,
    required this.newRecord,
    required this.stages,
    this.record,
    this.bonus,
    this.bestStage,
  });

  /// O speedrun com o ritmo (`SpeedrunPaces.idFor`).
  final Speedrun speedrun;
  final SpeedrunCategory category;

  /// Todas as tentativas, inclusive em andamento e desistidas.
  final int attempts;

  /// Alguma tentativa foi concluída.
  final bool finished;

  /// O recorde bateu um tempo anterior. A primeira conclusão nunca.
  final bool newRecord;

  /// O melhor tempo (o total da tentativa; use `recordTime` para mostrar).
  final Duration? record;

  /// O que o bônus pago neste speedrun deu. Nulo sem bônus.
  final int? bonus;

  /// A etapa mais longe que chegaram (de 1), sem ter concluído.
  final int? bestStage;

  /// Quantas etapas ele tem.
  final int stages;
}

/// As contas das abas Clássico e Maratona do Histórico.
abstract final class SpeedrunHistoryRows {
  /// As linhas: um speedrun por id com ritmo que tem tentativa. [bases] são os
  /// speedruns da Jornada (com as Maratonas); [marathon] escolhe a aba. Em
  /// ordem: nível (iniciante a avançado), depois a ordem de [bases] e a dos
  /// ritmos.
  static List<SpeedrunHistoryRow> build({
    required List<Speedrun> bases,
    required List<SpeedrunAttempt> attempts,
    required List<SpeedrunBonus> bonuses,
    required bool marathon,
  }) {
    final byId = <String, List<SpeedrunAttempt>>{};
    for (final attempt in attempts) {
      byId.putIfAbsent(attempt.speedrunId, () => []).add(attempt);
    }
    final rows = <(int, int, SpeedrunHistoryRow)>[];
    for (final MapEntry(key: id, value: own) in byId.entries) {
      final speedrun = SpeedrunPaces.resolve(bases, id);
      if (speedrun == null) continue;
      final isMarathon = speedrun.kind == SpeedrunKind.marathon;
      final category = SpeedrunCategories.of(speedrun);
      if (isMarathon != marathon || category == null) continue;
      if (!marathon && speedrun.journeyOnly) continue;
      final (baseId, time) = SpeedrunPaces.parse(id);
      rows.add((
        bases.indexWhere((base) => base.id == baseId),
        SpeedrunPaces.all.indexOf(time),
        _row(speedrun, category, own, bonuses),
      ));
    }
    rows.sort((a, b) {
      final byLevel = a.$3.category.index.compareTo(b.$3.category.index);
      if (byLevel != 0) return byLevel;
      final byBase = a.$1.compareTo(b.$1);
      return byBase != 0 ? byBase : a.$2.compareTo(b.$2);
    });
    return [for (final (_, _, row) in rows) row];
  }

  static SpeedrunHistoryRow _row(
    Speedrun speedrun,
    SpeedrunCategory category,
    List<SpeedrunAttempt> attempts,
    List<SpeedrunBonus> bonuses,
  ) {
    final records = SpeedrunScore.records(speedrun, attempts);
    final runs = [for (final a in attempts) SpeedrunScore.run(speedrun, a)];
    final best = records.best;
    // O recorde mais antigo entre os empatados: empatar não é bater.
    var newRecord = false;
    if (best != null) {
      final run = records.completed.lastWhere((run) => run.total == best);
      final previous = SpeedrunScore.previousBest(records, run);
      newRecord = previous != null && best < previous;
    }
    final ids = {for (final attempt in attempts) attempt.id};
    final paid = [
      for (final bonus in bonuses)
        if (ids.contains(bonus.attemptId)) bonus.points,
    ];
    final finished = records.completed.isNotEmpty;
    final total = speedrun.stages.length;
    var farthest = 0;
    for (final run in runs) {
      final stage = run.currentStage + 1;
      if (stage > farthest) farthest = stage;
    }
    return SpeedrunHistoryRow(
      speedrun: speedrun,
      category: category,
      attempts: attempts.length,
      finished: finished,
      newRecord: newRecord,
      record: best,
      bonus: paid.isEmpty
          ? null
          : paid.fold<int>(0, (sum, points) => sum + points),
      bestStage: finished ? null : farthest.clamp(1, total),
      stages: total,
    );
  }

  /// As linhas de [rows] que passam por [filter].
  static List<SpeedrunHistoryRow> filter(
    List<SpeedrunHistoryRow> rows,
    SpeedrunHistoryFilter filter,
  ) => [
    for (final row in rows)
      if ((filter.level == null || row.category == filter.level) &&
          (filter.pace == null ||
              PaceCategory.of(row.speedrun.time) == filter.pace))
        row,
  ];

  /// Tentativas, speedruns concluídos e recordes novos de [rows].
  static ({int attempts, int finished, int newRecords}) score(
    Iterable<SpeedrunHistoryRow> rows,
  ) {
    var attempts = 0, finished = 0, newRecords = 0;
    for (final row in rows) {
      attempts += row.attempts;
      if (row.finished) finished++;
      if (row.newRecord) newRecords++;
    }
    return (attempts: attempts, finished: finished, newRecords: newRecords);
  }
}
