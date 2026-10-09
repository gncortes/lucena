/// A tela de conclusão aberta (T51, B4): fechar o app nela e voltar reabre a
/// mesma, sem contar a partida de novo.
abstract class ConclusionRepository {
  /// A partida da conclusão que estava na tela. Nula: nenhuma.
  Future<int?> pending();

  /// A conclusão da partida [gameId] está na tela.
  Future<void> open(int gameId);

  /// O jogador saiu da conclusão.
  Future<void> clear();
}
