import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/positions/positions_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/speedrun/speedrun_repository.dart';
import '../../../domain/models/achievement.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/models/speedrun_pace.dart';
import '../../../domain/use_cases/speedrun_score.dart';

/// Junta do histórico tudo o que as regras de conquista olham: as partidas,
/// a Jornada, os speedruns (cada ritmo um speedrun próprio) e a
/// subcategoria de cada posição. Usado no fim da partida e na lista de
/// conquistas (o progresso das que faltam).
class AchievementFactsLoader {
  const AchievementFactsLoader({
    required this._journey,
    required this._progress,
    required this._speedruns,
    required this._positions,
  });

  final JourneyRepository _journey;
  final ProgressRepository _progress;
  final SpeedrunRepository _speedruns;
  final PositionsRepository _positions;

  Future<AchievementFacts> load() async {
    final games = await _progress.allAttempts();
    final ladder = await _journey.ladder();
    // Cada ritmo é um speedrun próprio, com os seus recordes.
    final speedruns = <String, Speedrun>{
      for (final base in await _journey.speedruns())
        for (final time in SpeedrunPaces.all)
          SpeedrunPaces.idFor(base.id, time): SpeedrunPaces.withTime(
            base,
            time,
          ),
    };
    final runs = <SpeedrunRun>[];
    for (final speedrun in speedruns.values) {
      for (final attempt in await _speedruns.attempts(speedrun.id)) {
        runs.add(SpeedrunScore.run(speedrun, attempt));
      }
    }
    // As posições das etapas dos speedruns de final ficam fora do catálogo:
    // o final delas vem do próprio speedrun.
    final subcategoryOf = <String, String>{
      for (final speedrun in speedruns.values)
        for (final stage in speedrun.stages)
          stage.position.id: stage.position.subcategory,
    };
    for (final id in {for (final game in games) game.positionId}) {
      if (subcategoryOf.containsKey(id)) continue;
      final position = await _positions.byId(id);
      if (position != null) subcategoryOf[id] = position.subcategory;
    }
    return AchievementFacts(
      games: games,
      ladder: ladder,
      subcategoryOf: subcategoryOf,
      runs: runs,
      speedruns: speedruns,
    );
  }
}
