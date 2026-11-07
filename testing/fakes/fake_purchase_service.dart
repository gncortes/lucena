import 'dart:async';

import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/data/services/purchase_service.dart';
import 'package:lucena/domain/models/pilares_access.dart';

/// A Play falsa: o teste manda as atualizações de compra por [send] e diz o
/// que a conta tem por [ownedPurchases].
class FakePurchaseService implements PurchaseService {
  FakePurchaseService({
    this.prices = const {
      pilaresLifetimeProductId: 'R\$ 89,90',
      pilaresMonthlyProductId: 'R\$ 17,90',
    },
    this.isAvailable = true,
    this.offers = const [],
  });

  final Map<String, String> prices;

  /// As ofertas com desconto do vitalício.
  List<StoreOffer> offers;
  bool isAvailable;

  /// O `owned()` lança [StoreOfflineException].
  bool offline = false;
  List<StorePurchase> ownedPurchases = [];

  final _purchases = StreamController<StorePurchase>.broadcast();
  final completed = <StorePurchase>[];
  final bought = <StoreProduct>[];
  int ownedCalls = 0;

  void send(StorePurchase purchase) => _purchases.add(purchase);

  @override
  Stream<StorePurchase> get purchases => _purchases.stream;

  @override
  Future<bool> available() async => isAvailable;

  @override
  Future<StoreProduct?> product(String id) async {
    final price = prices[id];
    return price == null
        ? null
        : StoreProduct(
            id: id,
            price: price,
            rawPrice: 89.9,
            currency: 'BRL',
            offers: id == pilaresLifetimeProductId ? offers : const [],
          );
  }

  /// A oferta e a conta de cada [bought].
  final boughtOffers = <StoreOffer?>[];
  final boughtAccounts = <String?>[];

  @override
  Future<void> buy(
    StoreProduct product, {
    StoreOffer? offer,
    String? accountId,
  }) async {
    bought.add(product);
    boughtOffers.add(offer);
    boughtAccounts.add(accountId);
  }

  @override
  Future<void> complete(StorePurchase purchase) async =>
      completed.add(purchase);

  @override
  Future<List<StorePurchase>> owned() async {
    ownedCalls++;
    if (offline) throw const StoreOfflineException();
    return ownedPurchases;
  }
}

/// A compra pelo site falsa.
class FakeSitePurchaseService implements SitePurchaseService {
  DateTime? purchasedAt;

  @override
  Future<DateTime?> pilaresPurchasedAt() async => purchasedAt;
}

/// O Pilares com o estado dado pelo teste.
class FakePurchaseRepository implements PurchaseRepository {
  FakePurchaseRepository([this._state = const PurchaseState()]);

  final _changes = StreamController<PurchaseState>.broadcast();
  final buys = <PilaresPlan>[];
  RestoreResult restoreResult = RestoreResult.notFound;
  int restores = 0;
  int refreshes = 0;

  @override
  PurchaseState get state => _state;
  PurchaseState _state;

  set state(PurchaseState value) {
    _state = value;
    _changes.add(value);
  }

  @override
  Stream<PurchaseState> get changes => _changes.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> refresh() async => refreshes++;

  @override
  Future<void> buy(PilaresPlan plan) async => buys.add(plan);

  @override
  Future<RestoreResult> restore() async {
    restores++;
    return restoreResult;
  }

  @override
  void clearOutcome() => state = _state.copyWith(clearOutcome: true);

  @override
  Future<void> markEndedSeen() async =>
      state = _state.copyWith(access: _state.access.copyWith(endedSeen: true));

  final offerCodes = <String>[];
  int linkNoticesDismissed = 0;

  @override
  Future<void> useOfferCode(String code) async => offerCodes.add(code);

  @override
  Future<void> dismissLinkNotice() async {
    linkNoticesDismissed++;
    state = _state.copyWith(linkGone: false);
  }
}
