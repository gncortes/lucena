import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../data/repositories/speedrun/speedrun_repository.dart';
import '../../../domain/models/player_rating.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/models/speedrun_pace.dart';
import '../../../domain/use_cases/speedrun_rating_bonus.dart';
import '../../../domain/use_cases/speedrun_score.dart';

/// Paga o bônus de rating das conclusões de speedrun: na última etapa, pelo
/// `GameReporter`; e, em silêncio, ao abrir o resumo ou o Histórico, para a
/// tentativa concluída que fechou à força antes de o bônus ser gravado.
class SpeedrunBonusPayer {
  SpeedrunBonusPayer({
    required this._rating,
    required this._speedruns,
    required this._journey,
  });

  final RatingRepository _rating;
  final SpeedrunRepository _speedruns;
  final JourneyRepository _journey;

  /// Paga toda conclusão que dá bônus e ainda não recebeu, da mais antiga
  /// para a mais recente. Devolve os bônus gravados agora.
  Future<List<SpeedrunBonus>> payPending() async {
    final completions = await _completions(await _journey.speedruns());
    final paid = {
      for (final bonus in await _rating.speedrunBonuses()) bonus.attemptId,
    };
    final added = <SpeedrunBonus>[];
    for (final (index, completion) in completions.indexed) {
      if (paid.contains(completion.attempt.id)) continue;
      // O rating de quando a tentativa começou: o número que o detalhe
      // ofereceu.
      final rating = await _rating.at(completion.attempt.startedAt);
      final points = SpeedrunRatingBonus.of(
        completion.slot,
        rating: rating.rounded,
        previous: [
          for (final previous in completions.take(index)) previous.slot,
        ],
      );
      if (points == 0) continue;
      final bonus = await _rating.addSpeedrunBonus(
        attemptId: completion.attempt.id,
        points: points,
      );
      if (bonus != null) added.add(bonus);
    }
    return added;
  }

  /// O bônus da tentativa [attemptId], pagando antes o que faltar. Nulo se a
  /// conclusão dela não dá bônus.
  Future<SpeedrunBonus?> bonusOf(int attemptId) async {
    await payPending();
    return (await _rating.speedrunBonuses())
        .where((bonus) => bonus.attemptId == attemptId)
        .firstOrNull;
  }

  /// Quanto concluir [speedrun] agora daria: com o rating atual e as
  /// conclusões até aqui. Zero se ele não dá bônus ou se o grupo já foi
  /// concluído.
  Future<int> offer(Speedrun speedrun) async {
    final slot = SpeedrunRatingBonus.slotOf(speedrun);
    if (slot == null) return 0;
    final completions = await _completions(await _journey.speedruns());
    return SpeedrunRatingBonus.of(
      slot,
      rating: (await _rating.current()).rounded,
      previous: [for (final completion in completions) completion.slot],
    );
  }

  /// O bônus já pago no mesmo final, modalidade e grupo de [speedrun]: a
  /// data e os pontos do aviso de refazer. Nulo se ainda não pagou.
  Future<SpeedrunBonus?> paidFor(Speedrun speedrun) async {
    final slot = SpeedrunRatingBonus.slotOf(speedrun);
    if (slot == null) return null;
    final bases = await _journey.speedruns();
    return (await _rating.speedrunBonuses()).where((bonus) {
      final paid = SpeedrunPaces.resolve(bases, bonus.speedrunId);
      final other = paid == null ? null : SpeedrunRatingBonus.slotOf(paid);
      return other != null && other.sameAs(slot);
    }).firstOrNull;
  }

  // As tentativas concluídas que entram na cadeia do bônus, na ordem em que
  // terminaram. As de antes do bônus existir ficam de fora.
  Future<List<_Completion>> _completions(List<Speedrun> bases) async {
    final completions = <_Completion>[];
    for (final attempt in await _speedruns.allAttempts()) {
      if (!attempt.bonusEligible) continue;
      final speedrun = SpeedrunPaces.resolve(bases, attempt.speedrunId);
      if (speedrun == null) continue;
      final slot = SpeedrunRatingBonus.slotOf(speedrun);
      final finishedAt = SpeedrunScore.run(speedrun, attempt).finishedAt;
      if (slot == null || finishedAt == null) continue;
      completions.add(_Completion(attempt, slot, finishedAt));
    }
    return completions..sort((a, b) {
      final byTime = a.finishedAt.compareTo(b.finishedAt);
      return byTime != 0 ? byTime : a.attempt.id.compareTo(b.attempt.id);
    });
  }
}

class _Completion {
  const _Completion(this.attempt, this.slot, this.finishedAt);

  final SpeedrunAttempt attempt;
  final SpeedrunBonusSlot slot;
  final DateTime finishedAt;
}
