import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/achievements/achievements_repository.dart';
import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../data/repositories/speedrun/speedrun_repository.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/player_rating.dart';
import '../../../domain/models/speedrun_pace.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/player_stats.dart';
import '../../../domain/use_cases/speedrun_score.dart';

/// Uma partida que mexeu no rating: como ele ficou, quanto mudou e a partida.
class RatedGame {
  const RatedGame({required this.entry, this.change, this.attempt});

  final RatingEntry entry;

  /// Quanto esta partida mudou o rating. Nulo na primeira (o ponto de
  /// partida não fica no histórico).
  final int? change;

  /// A partida em si. Nula se o histórico não foi pedido ou ela não existe
  /// mais.
  final Attempt? attempt;
}

/// Os números do jogador, na tela de detalhes do rating.
class PlayerNumbers {
  const PlayerNumbers({
    required this.stats,
    this.achievementsUnlocked = 0,
    this.achievementsTotal = 0,
    this.bestSpeedrun,
  });

  /// Partidas, vitórias e dias seguidos.
  final PlayerStats stats;
  final int achievementsUnlocked;
  final int achievementsTotal;

  /// O melhor tempo em qualquer speedrun. Nulo sem nenhum concluído.
  final Duration? bestSpeedrun;
}

/// O rating do jogador, o histórico dele e os números do progresso.
class RatingState {
  const RatingState({
    this.current,
    this.history = const [],
    this.attempts = const {},
    this.numbers,
  });

  /// Nulo enquanto é lido.
  final PlayerRating? current;

  /// Da partida mais antiga para a mais recente.
  final List<RatingEntry> history;

  /// As partidas do histórico, pelo id.
  final Map<int, Attempt> attempts;

  /// Partidas, vitórias, dias seguidos, conquistas e o melhor speedrun. Nulo
  /// onde só o rating interessa (sem o histórico de partidas).
  final PlayerNumbers? numbers;

  /// Quanto a última partida mudou o rating. Nulo sem duas partidas.
  int? get lastChange => history.length < 2
      ? null
      : history.last.rating.rounded -
            history[history.length - 2].rating.rounded;

  /// Poucas partidas: o rating ainda não diz muito.
  bool get provisional => history.length < provisionalGames;

  /// As partidas que contaram, da mais recente para a mais antiga.
  List<RatedGame> get games => [
    for (var index = history.length - 1; index >= 0; index--)
      RatedGame(
        entry: history[index],
        change: index == 0
            ? null
            : history[index].rating.rounded - history[index - 1].rating.rounded,
        attempt: attempts[history[index].gameId],
      ),
  ];

  /// Até quantas partidas o rating é provisório.
  static const provisionalGames = 5;
}

class RatingCubit extends Cubit<RatingState> {
  RatingCubit(
    this._rating, {
    this._progress,
    this._achievements,
    this._speedruns,
    this._journey,
    this._now = const SystemNow(),
  }) : super(const RatingState());

  final RatingRepository _rating;

  // Com ele, cada ponto do histórico vem com a partida e a tela ganha os
  // números do jogador (tela de detalhes).
  final ProgressRepository? _progress;
  final AchievementsRepository? _achievements;
  final SpeedrunRepository? _speedruns;
  final JourneyRepository? _journey;
  final Now _now;

  Future<void> load() async {
    final current = await _rating.current();
    final history = await _rating.history();
    final progress = _progress;
    final attempts =
        await progress?.attemptsById({
          for (final entry in history) ?entry.gameId,
        }) ??
        const <int, Attempt>{};
    final achievements = _achievements;
    final numbers = progress == null
        ? null
        : PlayerNumbers(
            stats: PlayerStats.of(await progress.allAttempts(), _now()),
            achievementsUnlocked: achievements == null
                ? 0
                : (await achievements.unlocked()).length,
            achievementsTotal: achievements == null
                ? 0
                : (await achievements.all()).length,
            bestSpeedrun: await _bestSpeedrun(),
          );
    if (isClosed) return;
    emit(
      RatingState(
        current: current,
        history: history,
        attempts: attempts,
        numbers: numbers,
      ),
    );
  }

  // O melhor tempo entre todos os speedruns, em qualquer ritmo.
  Future<Duration?> _bestSpeedrun() async {
    final speedruns = _speedruns;
    final journey = _journey;
    if (speedruns == null || journey == null) return null;
    Duration? best;
    for (final base in await journey.speedruns()) {
      for (final time in SpeedrunPaces.all) {
        final speedrun = SpeedrunPaces.withTime(base, time);
        final attempts = await speedruns.attempts(speedrun.id);
        if (attempts.isEmpty) continue;
        final record = SpeedrunScore.records(speedrun, attempts).best;
        if (record != null && (best == null || record < best)) best = record;
      }
    }
    return best;
  }
}
