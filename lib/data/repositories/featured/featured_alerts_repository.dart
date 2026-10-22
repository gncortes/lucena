/// O aviso de final novo e de torneio começando (E1.20 e E1.21). Hoje não há
/// canal de aviso: [available] é falso e a tela não mostra o interruptor.
/// Quando o backend existir, basta trocar esta implementação.
abstract class FeaturedAlertsRepository {
  /// Há como avisar? Sem isso, o interruptor "Avisar quando sair final novo"
  /// não aparece.
  bool get available;

  /// O jogador quer o aviso de final novo?
  Future<bool> enabled();

  Future<void> setEnabled({required bool value});

  /// O jogador quer o aviso deste torneio?
  Future<bool> tournamentEnabled(String tournamentId);

  Future<void> setTournamentEnabled(String tournamentId, {required bool value});
}

/// Sem canal de aviso ainda.
class NoFeaturedAlertsRepository implements FeaturedAlertsRepository {
  const NoFeaturedAlertsRepository();

  @override
  bool get available => false;

  @override
  Future<bool> enabled() async => false;

  @override
  Future<void> setEnabled({required bool value}) async {}

  @override
  Future<bool> tournamentEnabled(String tournamentId) async => false;

  @override
  Future<void> setTournamentEnabled(
    String tournamentId, {
    required bool value,
  }) async {}
}
