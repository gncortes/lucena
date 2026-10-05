import '../models/attempt.dart';
import '../models/game_setup.dart';
import '../models/journey.dart';
import '../models/speedrun.dart';
import 'achievement_rules.dart';
import 'mastery.dart';

/// Os tipos de mensagem do fim da partida.
enum FeedbackKind {
  firstWinAgainstLevel,
  firstWinAgainstStockfish,
  rungCompleted,
  journeyCompleted,
  newSpeedrunRecord,
  speedrunImproved,
  stageRecord,
  achievement,
}

/// Uma mensagem do fim da partida, com o que ela mostra.
class GameFeedback {
  const GameFeedback(
    this.kind, {
    this.level,
    this.rungId,
    this.improvedBy,
    this.time,
    this.achievementId,
  });

  final FeedbackKind kind;

  /// O nível do Maia vencido pela primeira vez (ou o da etapa).
  final int? level;
  final String? rungId;

  /// Quanto o recorde do speedrun melhorou.
  final Duration? improvedBy;

  /// O tempo do recorde (total ou da etapa).
  final Duration? time;
  final String? achievementId;

  @override
  bool operator ==(Object other) =>
      other is GameFeedback &&
      other.kind == kind &&
      other.level == level &&
      other.rungId == rungId &&
      other.improvedBy == improvedBy &&
      other.time == time &&
      other.achievementId == achievementId;

  @override
  int get hashCode =>
      Object.hash(kind, level, rungId, improvedBy, time, achievementId);

  @override
  String toString() =>
      'GameFeedback($kind, level: $level, rungId: $rungId, '
      'improvedBy: $improvedBy, time: $time, achievementId: $achievementId)';
}

/// O que dizer no fim de uma partida ou etapa, comparando com o histórico de
/// antes dela.
abstract final class GameFeedbackRules {
  /// As mensagens depois de [game]. [before] é o histórico sem ela.
  static List<GameFeedback> afterGame({
    required Attempt game,
    required List<Attempt> before,
    required List<Rung> ladder,
  }) {
    if (!game.fulfilled) return const [];
    final feedback = <GameFeedback>[];
    final previous = before.where((other) => other.fulfilled);
    switch (game.opponent) {
      case OpponentKind.maia:
        final level = game.opponentLevel;
        if (level != null &&
            !previous.any(
              (other) =>
                  other.opponent == OpponentKind.maia &&
                  other.opponentLevel == level,
            )) {
          feedback.add(
            GameFeedback(FeedbackKind.firstWinAgainstLevel, level: level),
          );
        }
      case OpponentKind.stockfish:
        if (!previous.any(
          (other) => other.opponent == OpponentKind.stockfish,
        )) {
          feedback.add(
            const GameFeedback(FeedbackKind.firstWinAgainstStockfish),
          );
        }
      case OpponentKind.twoPlayers:
        break;
    }

    final challengeId = game.challengeId;
    if (challengeId != null) {
      final doneBefore = before.fulfilledChallenges;
      final doneNow = {...doneBefore, challengeId};
      final progressBefore = Mastery.of(ladder, doneBefore);
      final progressNow = Mastery.of(ladder, doneNow);
      for (final (index, rung) in progressNow.rungs.indexed) {
        if (!rung.rung.challenges.any((c) => c.id == challengeId)) continue;
        if (_complete(rung) && !_complete(progressBefore.rungs[index])) {
          feedback.add(
            GameFeedback(FeedbackKind.rungCompleted, rungId: rung.rung.id),
          );
          if (progressNow.rungs.every(_complete)) {
            feedback.add(const GameFeedback(FeedbackKind.journeyCompleted));
          }
        }
      }
    }
    return feedback;
  }

  /// Todos os desafios do degrau concluídos, trancado ou não.
  static bool _complete(RungProgress rung) => rung.remaining == 0;

  /// As mensagens depois de a etapa [stage] de [run] terminar.
  /// [previousCompleted] são as tentativas concluídas antes desta.
  static List<GameFeedback> afterSpeedrunStage({
    required SpeedrunRun run,
    required List<SpeedrunRun> previousCompleted,
    required int stage,
  }) {
    final feedback = <GameFeedback>[];
    final others = previousCompleted.where(
      (other) => other.completed && other.attempt.id != run.attempt.id,
    );
    if (stage >= 0 && stage < run.stages.length && run.stages[stage].done) {
      final time = run.stages[stage].time;
      Duration? best;
      for (final other in others) {
        if (stage >= other.stages.length) continue;
        final previous = other.stages[stage].time;
        if (best == null || previous < best) best = previous;
      }
      if (best != null && time < best) {
        feedback.add(GameFeedback(FeedbackKind.stageRecord, time: time));
      }
    }
    if (run.completed) {
      final total = run.total;
      Duration? best;
      for (final other in others) {
        if (best == null || other.total < best) best = other.total;
      }
      if (best == null || total < best) {
        feedback.add(GameFeedback(FeedbackKind.newSpeedrunRecord, time: total));
      }
      if (best != null && total < best) {
        feedback.add(
          GameFeedback(FeedbackKind.speedrunImproved, improvedBy: best - total),
        );
      }
    }
    return feedback;
  }
}
