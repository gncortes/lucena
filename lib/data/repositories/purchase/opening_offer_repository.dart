import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/training/demo_offer_rules.dart';
import '../../services/preferences_service.dart';

/// A oferta do Pilares ao abrir o app (H-INI-14 / H-VEN-15): quantas vezes
/// já apareceu e quando (gravado no aparelho) e o que aconteceu nesta
/// abertura (em memória: some quando o app fecha de verdade).
abstract interface class OpeningOfferRepository {
  Future<DemoOfferState> load();

  /// Conta uma vez agora. Vale ao abrir a oferta: fechar à força com ela
  /// aberta já conta como vista.
  Future<void> markShown();

  /// O tour abriu nesta abertura: a oferta espera a próxima.
  void markTour();

  bool get tourThisOpening;

  /// A oferta já apareceu nesta abertura (a folha da sequência perdida
  /// espera a próxima).
  bool get shownThisOpening;
}

class LocalOpeningOfferRepository implements OpeningOfferRepository {
  LocalOpeningOfferRepository(this._preferences, this._now);

  final PreferencesService _preferences;
  final Now _now;

  static const timesKey = 'venda.oferta.vezes';
  static const lastKey = 'venda.oferta.ultima';

  @override
  bool tourThisOpening = false;

  @override
  bool shownThisOpening = false;

  @override
  Future<DemoOfferState> load() async {
    final times = int.tryParse(await _preferences.getString(timesKey) ?? '');
    final last = DateTime.tryParse(await _preferences.getString(lastKey) ?? '');
    return DemoOfferState(count: times ?? 0, lastShown: last);
  }

  @override
  Future<void> markShown() async {
    shownThisOpening = true;
    final next = DemoOfferRules.shown(await load(), _now());
    await _preferences.setString(timesKey, '${next.count}');
    await _preferences.setString(lastKey, next.lastShown!.toIso8601String());
  }

  @override
  void markTour() => tourThisOpening = true;
}

/// Sem oferta ao abrir (testes, E2E): já conta as vezes todas.
class NoOpeningOfferRepository implements OpeningOfferRepository {
  const NoOpeningOfferRepository();

  @override
  Future<DemoOfferState> load() async =>
      const DemoOfferState(count: DemoOfferRules.maxOffers);

  @override
  Future<void> markShown() async {}

  @override
  void markTour() {}

  @override
  bool get tourThisOpening => false;

  @override
  bool get shownThisOpening => false;
}
