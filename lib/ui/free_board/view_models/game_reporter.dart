import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/character.dart';

import 'package:dartchess/dartchess.dart';

import '../../../data/repositories/achievements/achievements_repository.dart';
import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/positions/positions_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../data/repositories/speedrun/speedrun_repository.dart';
import '../../../domain/models/achievement.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/player_rating.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/models/speedrun_pace.dart';
import '../../../domain/use_cases/achievement_rules.dart';
import '../../../domain/use_cases/game_feedback.dart';
import '../../../domain/use_cases/mastery.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/speedrun_score.dart';

/// O que uma partida terminada mudou: o rating, as mensagens de evolução e as
/// conquistas novas.
class GameReport {
  const GameReport({
    this.before,
    this.after,
    this.feedback = const [],
    this.achievements = const [],
    this.characters = const [],
    this.next,
    this.speedrun,
  });

  /// O rating antes e depois. Nulos se a partida não conta.
  final PlayerRating? before;
  final PlayerRating? after;

  /// Os personagens, para as mensagens dizerem o nome do adversário.
  final List<Character> characters;

  /// "Primeira vitória contra a Zuri", "Novo recorde"...
  final List<GameFeedback> feedback;

  /// As conquistas que a partida liberou.
  final List<Achievement> achievements;

  /// Num desafio da Jornada, o desafio para jogar em seguida.
  final NextChallenge? next;

  /// Numa etapa de speedrun, o que vem depois dela.
  final SpeedrunStep? speedrun;
}

/// O passo seguinte de um speedrun, depois de uma etapa: a mesma etapa de
/// novo (se foi perdida), a próxima ou, com todas vencidas, o fim.
class SpeedrunStep {
  const SpeedrunStep({
    required this.speedrunId,
    required this.attemptId,
    this.stage,
    this.challenge,
    this.lost = false,
  });

  final String speedrunId;
  final int attemptId;

  /// A etapa a jogar em seguida e o desafio dela. Nulos com o speedrun
  /// concluído.
  final int? stage;
  final Challenge? challenge;

  /// A etapa foi perdida: a tentativa terminou ali, e tentar de novo é uma
  /// tentativa nova, desde a primeira etapa ([challenge]).
  final bool lost;

  bool get finished => challenge == null;
}

/// Monta o [GameReport] de uma partida já gravada, a partir do histórico.
class GameReporter {
  GameReporter({
    required this._rating,
    required this._achievements,
    required this._journey,
    required this._progress,
    required this._speedruns,
    required this._positions,
    required this._now,
    this._onboarding,
    this._characters,
  });

  final CharacterRepository? _characters;

  final RatingRepository _rating;
  final AchievementsRepository _achievements;
  final JourneyRepository _journey;
  final ProgressRepository _progress;
  final SpeedrunRepository _speedruns;
  final PositionsRepository _positions;
  final Now _now;

  /// O degrau de início do tour: os de baixo já começam liberados.
  final OnboardingRepository? _onboarding;

  Future<GameReport> report(
    Attempt game, {
    required int gameId,
    required Side userSide,
    required bool drawGoal,
  }) async {
    final before = await _rating.current();
    final rated = await _rating.rate(
      game,
      userSide: userSide,
      drawGoal: drawGoal,
      gameId: gameId,
    );
    final games = await _progress.allAttempts();
    final ladder = await _journey.ladder();
    // Cada ritmo é um speedrun próprio, com os seus recordes.
    final speedruns = {
      for (final base in await _journey.speedruns())
        for (final time in SpeedrunPaces.all)
          SpeedrunPaces.idFor(base.id, time): SpeedrunPaces.withTime(
            base,
            time,
          ),
    };
    final feedback = [
      ...GameFeedbackRules.afterGame(
        game: game,
        // A partida já está gravada: é a última.
        before: games.isEmpty ? games : games.sublist(0, games.length - 1),
        ladder: ladder,
      ),
      ...await _speedrunFeedback(game, speedruns),
    ];

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
    final facts = AchievementFacts(
      games: games,
      ladder: ladder,
      subcategoryOf: subcategoryOf,
      runs: runs,
      speedruns: speedruns,
    );
    final unlocked = await _achievements.unlocked();
    final earned = AchievementRules.newlyEarned(
      await _achievements.all(),
      facts,
      unlocked.keys.toSet(),
    );
    if (earned.isNotEmpty) {
      await _achievements.unlock([for (final a in earned) a.id], _now());
    }
    final challengeId = game.challengeId;
    final next = challengeId == null
        ? null
        : Mastery.nextChallenge(
            ladder,
            await _progress.fulfilledChallenges(),
            challengeId,
            startRung: (await _onboarding?.load())?.startRung,
          );
    return GameReport(
      next: next,
      before: rated == null ? null : before,
      after: rated?.rating,
      feedback: [
        ...feedback,
        for (final achievement in earned)
          GameFeedback(FeedbackKind.achievement, achievementId: achievement.id),
      ],
      achievements: earned,
      characters: await _characters?.characters() ?? const [],
      speedrun: await _speedrunStep(game, speedruns),
    );
  }

  // Depois de uma etapa de speedrun: a mesma de novo, a próxima ou o fim.
  Future<SpeedrunStep?> _speedrunStep(
    Attempt game,
    Map<String, Speedrun> speedruns,
  ) async {
    final attemptId = game.speedrunAttemptId;
    if (attemptId == null) return null;
    final attempt = await _speedruns.attempt(attemptId);
    final speedrun = speedruns[attempt?.speedrunId];
    if (attempt == null || speedrun == null) return null;
    // O speedrun é uma fileira só: perder uma etapa encerra a tentativa,
    // que fica no histórico até onde chegou.
    if (!game.fulfilled) {
      await _speedruns.abandon(attemptId, _now());
      return SpeedrunStep(
        speedrunId: speedrun.id,
        attemptId: attemptId,
        stage: 0,
        challenge: speedrun.stages.first,
        lost: true,
      );
    }
    final run = SpeedrunScore.run(speedrun, attempt);
    final stage = run.currentStage;
    return SpeedrunStep(
      speedrunId: speedrun.id,
      attemptId: attemptId,
      stage: run.completed ? null : stage,
      challenge: run.completed ? null : speedrun.stages[stage],
    );
  }

  // Os recordes da etapa e da tentativa, quando a partida é de speedrun.
  Future<List<GameFeedback>> _speedrunFeedback(
    Attempt game,
    Map<String, Speedrun> speedruns,
  ) async {
    final attemptId = game.speedrunAttemptId;
    final stage = game.speedrunStage;
    if (attemptId == null || stage == null || !game.fulfilled) return const [];
    final attempt = await _speedruns.attempt(attemptId);
    final speedrun = speedruns[attempt?.speedrunId];
    if (attempt == null || speedrun == null) return const [];
    final run = SpeedrunScore.run(speedrun, attempt);
    final previous = [
      for (final other in await _speedruns.attempts(speedrun.id))
        if (other.id != attempt.id) SpeedrunScore.run(speedrun, other),
    ];
    final opponent = stage < speedrun.stages.length
        ? speedrun.stages[stage].opponent
        : null;
    return [
      for (final item in GameFeedbackRules.afterSpeedrunStage(
        run: run,
        previousCompleted: previous,
        stage: stage,
      ))
        // A etapa diz contra quem foi o recorde.
        item.kind == FeedbackKind.stageRecord
            ? GameFeedback(
                item.kind,
                level: opponent?.level,
                rungId: opponent?.kind == OpponentKind.stockfish
                    ? OpponentKind.stockfish.code
                    : null,
                time: item.time,
              )
            : item,
    ];
  }
}
