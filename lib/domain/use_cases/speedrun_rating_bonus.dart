import '../models/pace.dart';
import '../models/speedrun.dart';
import '../models/speedrun_pace.dart';
import 'speedrun_category.dart';

/// Onde uma conclusão de speedrun entra na cadeia do bônus: o final, a
/// modalidade (clássico ou Maratona) e o grupo de ritmo.
class SpeedrunBonusSlot {
  const SpeedrunBonusSlot({
    required this.ending,
    required this.marathon,
    required this.group,
    required this.category,
  });

  /// O final, igual no clássico e na Maratona (`rook` em `ending.rook` e
  /// `marathon.rook`): a cadeia.
  final String ending;
  final bool marathon;
  final PaceCategory group;
  final SpeedrunCategory category;

  /// Mesmo final, modalidade e grupo: o bônus já foi pago.
  bool sameAs(SpeedrunBonusSlot other) =>
      other.ending == ending &&
      other.marathon == marathon &&
      other.group == group;
}

/// O bônus de rating por concluir pela primeira vez um speedrun de final num
/// grupo de ritmo (regra em `docs/tasks/T65-regra-rating-speedrun.md` §2–3).
/// A etapa não mexe no rating; só a conclusão, uma vez por final × modalidade
/// × grupo.
abstract final class SpeedrunRatingBonus {
  /// Teto de uma conclusão no clássico e na Maratona.
  static const classicCap = 200;
  static const marathonCap = 300;

  static const _endingPrefix = 'ending.';
  static const _marathonPrefix = 'marathon.';

  /// A parte do rating que cada grupo paga, em %: mais rápido paga mais.
  static int? percent(PaceCategory group) => switch (group) {
    PaceCategory.rapid => 5,
    PaceCategory.blitz => 10,
    PaceCategory.bullet => 15,
    PaceCategory.ultraBullet => 20,
    PaceCategory.classical => null,
  };

  /// O nível (N) do speedrun: o piso da faixa.
  static int level(SpeedrunCategory category) => switch (category) {
    SpeedrunCategory.beginner => 1000,
    SpeedrunCategory.intermediate => 1300,
    SpeedrunCategory.advanced => 1900,
  };

  /// A posição de [speedrun] na cadeia. Nula se ele não dá bônus: só os de
  /// final e as Maratonas deles, fora os só da Jornada.
  static SpeedrunBonusSlot? slotOf(Speedrun speedrun) {
    if (speedrun.journeyOnly) return null;
    final marathon = speedrun.kind == SpeedrunKind.marathon;
    if (!marathon && speedrun.kind != SpeedrunKind.ending) return null;
    final category = SpeedrunCategories.of(speedrun);
    final group = PaceCategory.of(speedrun.time);
    if (category == null || percent(group) == null) return null;
    final (baseId, _) = SpeedrunPaces.parse(speedrun.id);
    final prefix = marathon ? _marathonPrefix : _endingPrefix;
    return SpeedrunBonusSlot(
      ending: baseId.startsWith(prefix)
          ? baseId.substring(prefix.length)
          : baseId,
      marathon: marathon,
      group: group,
      category: category,
    );
  }

  /// O valor cheio de [slot] para quem tinha [rating] no início da tentativa:
  /// `R × p(grupo) × f × m`, em múltiplo de 5 e limitado ao teto.
  static int full(SpeedrunBonusSlot slot, {required int rating}) {
    // f = 1 − (R − N)/400, entre 0 e 1,5: em quatrocentos avos.
    final f = (400 - (rating - level(slot.category))).clamp(0, 600);
    // m: 1 no clássico, 1,5 na Maratona: em metades.
    final m = slot.marathon ? 3 : 2;
    final value = _round5(rating * percent(slot.group)! * f * m, 100 * 400 * 2);
    return value.clamp(0, slot.marathon ? marathonCap : classicCap);
  }

  /// O que a conclusão de [slot] paga, depois das conclusões [previous] da
  /// mesma cadeia: nada se o grupo já foi concluído naquela modalidade; 75%
  /// do cheio se outro grupo ou modalidade do mesmo final já foi; senão o
  /// cheio. Menos de 5 pontos: nada.
  static int of(
    SpeedrunBonusSlot slot, {
    required int rating,
    Iterable<SpeedrunBonusSlot> previous = const [],
  }) {
    final chain = [
      for (final other in previous)
        if (other.ending == slot.ending) other,
    ];
    if (chain.any(slot.sameAs)) return 0;
    final value = full(slot, rating: rating);
    final paid = chain.isEmpty ? value : _round5(value * 3, 4);
    return paid < 5 ? 0 : paid;
  }

  // numerator/denominator no múltiplo de 5 mais próximo, o meio para cima.
  static int _round5(int numerator, int denominator) =>
      (2 * numerator + 5 * denominator) ~/ (10 * denominator) * 5;
}
