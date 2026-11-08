import 'package:lucena/data/repositories/purchase/opening_offer_repository.dart';
import 'package:lucena/domain/use_cases/training/demo_offer_rules.dart';

import 'fake_now.dart';

/// O contador da oferta ao abrir o app, em memória.
class FakeOpeningOfferRepository implements OpeningOfferRepository {
  FakeOpeningOfferRepository({this.state = const DemoOfferState(), this._now});

  DemoOfferState state;
  final FakeNow? _now;

  @override
  bool tourThisOpening = false;

  @override
  bool shownThisOpening = false;

  @override
  Future<DemoOfferState> load() async => state;

  @override
  void markTour() => tourThisOpening = true;

  @override
  Future<void> markShown() async {
    shownThisOpening = true;
    state = DemoOfferRules.shown(state, _now?.call() ?? DateTime(2026));
  }
}
