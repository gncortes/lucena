import '../models/offer_discount.dart';

/// Dois descontos valendo não somam (regra 5): vale o maior; no empate, o
/// que termina primeiro (sem fim conta como o último).
OfferDiscount? bestDiscount(Iterable<OfferDiscount> discounts) {
  OfferDiscount? best;
  for (final each in discounts) {
    if (best == null || _beats(each, best)) best = each;
  }
  return best;
}

bool _beats(OfferDiscount a, OfferDiscount b) {
  if (a.percent != b.percent) return a.percent > b.percent;
  final endA = a.endsAt;
  final endB = b.endsAt;
  if (endA == null) return false;
  if (endB == null) return true;
  return endA.isBefore(endB);
}
