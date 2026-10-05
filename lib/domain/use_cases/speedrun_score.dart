import '../models/speedrun.dart';

/// As contas do speedrun, todas tiradas das partidas gravadas (regras da T20):
/// o tempo é o que o relógio do jogador gastou, inclusive nas partidas
/// perdidas; perder repete a etapa sem zerar a tentativa; só tentativa
/// concluída vale recorde.
abstract final class SpeedrunScore {
  /// A tentativa [attempt] de [speedrun], etapa por etapa.
  static SpeedrunRun run(Speedrun speedrun, SpeedrunAttempt attempt) {
    final stages = [
      for (var index = 0; index < speedrun.stages.length; index++)
        _stage(attempt, index),
    ];
    return SpeedrunRun(attempt: attempt, stages: stages);
  }

  static StageResult _stage(SpeedrunAttempt attempt, int index) {
    var time = Duration.zero;
    var wins = 0;
    var losses = 0;
    for (final game in attempt.games) {
      if (game.speedrunStage != index) continue;
      time += game.userClock ?? Duration.zero;
      if (game.fulfilled) {
        wins++;
      } else {
        losses++;
      }
    }
    return StageResult(time: time, wins: wins, losses: losses);
  }

  /// Os recordes de [speedrun] entre as tentativas [attempts].
  static SpeedrunRecords records(
    Speedrun speedrun,
    List<SpeedrunAttempt> attempts,
  ) {
    final completed =
        [for (final attempt in attempts) run(speedrun, attempt)]
            .where((run) => run.completed)
            .toList()
          ..sort((a, b) => b.finishedAt!.compareTo(a.finishedAt!));
    Duration? best;
    final bestStages = List<Duration?>.filled(speedrun.stages.length, null);
    for (final run in completed) {
      if (best == null || run.total < best) best = run.total;
      for (final (index, stage) in run.stages.indexed) {
        final current = bestStages[index];
        if (current == null || stage.time < current) {
          bestStages[index] = stage.time;
        }
      }
    }
    return SpeedrunRecords(
      best: best,
      bestStages: bestStages,
      completed: completed,
    );
  }

  /// O recorde de antes de [run] terminar: o melhor tempo das tentativas
  /// concluídas antes dela. Nulo se ela foi a primeira.
  static Duration? previousBest(SpeedrunRecords records, SpeedrunRun run) {
    final finishedAt = run.finishedAt;
    Duration? best;
    for (final other in records.completed) {
      if (other.attempt.id == run.attempt.id) continue;
      if (finishedAt != null && !other.finishedAt!.isBefore(finishedAt)) {
        continue;
      }
      if (best == null || other.total < best) best = other.total;
    }
    return best;
  }
}
