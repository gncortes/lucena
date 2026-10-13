import 'package:dartchess/dartchess.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/ui/history/view_models/history_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_game_review_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';

/// Os fakes do Histórico e as jogadas que os testes repetem.
class HistoryWorld {
  HistoryWorld() {
    progress = FakeProgressRepository();
    rating = FakeRatingRepository();
    speedruns = FakeSpeedrunRepository(progress);
    settings = FakeSettingsRepository();
    now = FakeNow(DateTime.utc(2026, 10, 10, 13));
  }

  late final FakeProgressRepository progress;
  late final FakeRatingRepository rating;
  late final FakeSpeedrunRepository speedruns;
  late FakeSettingsRepository settings;
  late final FakeNow now;
  final journey = FakeJourneyRepository();
  final CharacterRepository characters = FakeCharacterRepository();
  final reviews = FakeGameReviewRepository();

  /// Um cubit novo sobre os mesmos dados (como reabrir a tela).
  HistoryCubit cubit({int? highlightedGame}) => HistoryCubit(
    rating: rating,
    progress: progress,
    speedruns: speedruns,
    journey: journey,
    characters: characters,
    reviews: reviews,
    settings: settings,
    now: now,
    highlightedGame: highlightedGame,
  );

  /// Joga [outcomes] contra o Maia 1000, da mais antiga para a mais recente,
  /// uma por hora, a última 1 h antes de "agora" (ou [daysAgo] dias antes).
  Future<List<int>> play(
    List<AttemptOutcome> outcomes, {
    int daysAgo = 0,
    TimeControl? time,
  }) async {
    final ids = <int>[];
    for (final (index, outcome) in outcomes.indexed) {
      final game = Attempt(
        positionId: 'basic.queen.0001',
        playedAt: now().subtract(
          Duration(days: daysAgo, hours: outcomes.length - index),
        ),
        outcome: outcome,
        fulfilled: outcome == AttemptOutcome.win,
        opponent: OpponentKind.maia,
        opponentLevel: 1000,
        userTime: time,
      );
      final id = await progress.addAttempt(game);
      ids.add(id);
      await rating.rate(
        game,
        userSide: Side.white,
        drawGoal: false,
        gameId: id,
      );
    }
    return ids;
  }

  /// Uma tentativa do final da dama (3 etapas) no ritmo [time], que ganhou as
  /// primeiras [stages] etapas em [seconds] cada. Devolve o id da tentativa.
  Future<int> speedrun({
    required TimeControl time,
    int stages = 3,
    int seconds = 20,
    int daysAgo = 0,
  }) async {
    final speedrun = SpeedrunPaces.resolve(sampleSpeedruns, 'ending.queen')!;
    final id = SpeedrunPaces.idFor(speedrun.id, time);
    final at = now().subtract(Duration(days: daysAgo, hours: 2));
    final attempt = await speedruns.start(id, at);
    for (var stage = 0; stage < stages; stage++) {
      await progress.addAttempt(
        Attempt(
          positionId: speedrun.stages[stage].position.id,
          playedAt: at.add(Duration(minutes: stage + 1)),
          outcome: AttemptOutcome.win,
          fulfilled: true,
          opponent: OpponentKind.maia,
          userClock: Duration(seconds: seconds),
          speedrunAttemptId: attempt.id,
          speedrunStage: stage,
        ),
      );
    }
    return attempt.id;
  }
}
