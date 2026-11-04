/// O que aparece por cima do Início ao abrir o app. Uma só por abertura, nesta
/// ordem: o tour, a oferta (tela de venda) e o aviso da sequência perdida.
enum OpeningOverlay {
  tour,
  offer,
  lostStreak,
  none;

  /// A que vale agora. As outras esperam a próxima abertura (o aviso da
  /// sequência perdida só é marcado como visto quando sai).
  static OpeningOverlay of({
    required bool tourPending,
    required bool offerPending,
    required bool streakLost,
  }) {
    if (tourPending) return tour;
    if (offerPending) return offer;
    if (streakLost) return lostStreak;
    return none;
  }
}
