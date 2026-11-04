/// Quantas vezes a oferta da demo aparece e o intervalo entre elas
/// (H-LIC-51: no máximo 2 vezes, com 3 dias entre elas).
final class DemoOfferState {
  const DemoOfferState({this.count = 0, this.lastShown});

  /// Quantas vezes a oferta já foi mostrada.
  final int count;
  final DateTime? lastShown;

  Map<String, Object?> toJson() => {
    'count': count,
    if (lastShown != null) 'lastShown': lastShown!.toIso8601String(),
  };

  factory DemoOfferState.fromJson(Map<String, Object?> json) => DemoOfferState(
    count: (json['count'] as int?) ?? 0,
    lastShown: DateTime.tryParse((json['lastShown'] as String?) ?? ''),
  );
}

abstract final class DemoOfferRules {
  static const maxOffers = 2;
  static const gap = Duration(days: 3);

  /// Só quem está na demo vê a oferta; comprador nunca.
  static bool shouldOffer(
    DemoOfferState state, {
    required bool demo,
    required DateTime now,
  }) {
    if (!demo || state.count >= maxOffers) return false;
    final last = state.lastShown;
    return last == null || !now.isBefore(last.add(gap));
  }

  static DemoOfferState shown(DemoOfferState state, DateTime now) =>
      DemoOfferState(count: state.count + 1, lastShown: now);
}
