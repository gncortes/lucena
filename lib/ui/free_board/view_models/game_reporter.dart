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
import '../../../domain/models/clock.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/achievement_rules.dart';
import '../../../domain/use_cases/game_feedback.dart';
import '../../../domain/use_cases/mastery.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/marathon.dart';
import '../../../domain/use_cases/speedrun_score.dart';
import '../../achievements/view_models/achievement_facts_loader.dart';

/// O que uma partida terminada mudou: o rating, as mensagens de evolução e as
/// conquistas novas.
class GameReport {
  const GameReport({
    this.before,
    this.after,
    this.feedback = const [],
    this.achievements = const [],
    this.unlocked = const {},
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

  /// As mesmas conquistas como ficaram gravadas (instante e origem), pelo id:
  /// o aviso abre o detalhe delas.
  final Map<String, UnlockedAchievement> unlocked;

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
    this.userTime,
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

  /// Na Maratona, o relógio do jogador na etapa seguinte: o que sobrou no
  /// banco, com o acréscimo do ritmo.
  final TimeControl? userTime;

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
    final facts = await AchievementFactsLoader(
      journey: _journey,
      progress: _progress,
      speedruns: _speedruns,
      positions: _positions,
    ).load();
    final games = facts.games;
    final ladder = facts.ladder;
    final speedruns = facts.speedruns;
    final feedback = [
      ...GameFeedbackRules.afterGame(
        game: game,
        // A partida já está gravada: é a última.
        before: games.isEmpty ? games : games.sublist(0, games.length - 1),
        ladder: ladder,
      ),
      ...await _speedrunFeedback(game, speedruns),
    ];
    final unlocked = await _achievements.unlocked();
    final earned = AchievementRules.newlyEarned(
      await _achievements.all(),
      facts,
      unlocked.keys.toSet(),
    );
    // A origem fica gravada (T51, A6): esta partida e, numa etapa de
    // speedrun, a tentativa.
    final at = _now();
    final recorded = {
      for (final achievement in earned)
        achievement.id: UnlockedAchievement(
          id: achievement.id,
          at: at,
          gameId: gameId,
          speedrunAttemptId: game.speedrunAttemptId,
        ),
    };
    if (recorded.isNotEmpty) await _achievements.unlock(recorded.values);
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
      unlocked: recorded,
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
    if (speedrun.kind == SpeedrunKind.marathon) {
      return _marathonStep(game, speedrun, attempt);
    }
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

  // Na Maratona não há pausa: vencer leva à etapa seguinte, com o que sobrou
  // no banco. Perder, empatar ou o banco acabar encerra a tentativa, até
  // onde ela chegou; tentar de novo é uma tentativa nova, da primeira etapa.
  Future<SpeedrunStep> _marathonStep(
    Attempt game,
    Speedrun speedrun,
    SpeedrunAttempt attempt,
  ) async {
    final run = SpeedrunScore.run(speedrun, attempt);
    final bank = Marathon.bank(run, speedrun.time);
    if (!game.fulfilled || (!run.completed && bank <= Duration.zero)) {
      await _speedruns.abandon(attempt.id, _now());
      return SpeedrunStep(
        speedrunId: speedrun.id,
        attemptId: attempt.id,
        stage: 0,
        challenge: speedrun.stages.first,
        lost: true,
      );
    }
    final stage = run.currentStage;
    return SpeedrunStep(
      speedrunId: speedrun.id,
      attemptId: attempt.id,
      stage: run.completed ? null : stage,
      challenge: run.completed ? null : speedrun.stages[stage],
      userTime: run.completed ? null : Marathon.stageTime(speedrun.time, bank),
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
