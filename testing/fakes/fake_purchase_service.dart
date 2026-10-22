import 'dart:async';

import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/data/services/purchase_service.dart';

/// A Play falsa: o teste manda as atualizações de compra por [send].
class FakePurchaseService implements PurchaseService {
  FakePurchaseService({this.price = 'R\$ 9,90', this.isAvailable = true});

  final String? price;
  final bool isAvailable;

  final _purchases = StreamController<StorePurchase>.broadcast();
  final completed = <StorePurchase>[];
  final bought = <StoreProduct>[];
  int restores = 0;

  void send(StorePurchase purchase) => _purchases.add(purchase);

  @override
  Stream<StorePurchase> get purchases => _purchases.stream;

  @override
  Future<bool> available() async => isAvailable;

  @override
  Future<StoreProduct?> product(String id) async {
    final price = this.price;
    return price == null ? null : StoreProduct(id: id, price: price);
  }

  @override
  Future<void> buy(StoreProduct product) async => bought.add(product);

  @override
  Future<void> complete(StorePurchase purchase) async =>
      completed.add(purchase);

  @override
  Future<void> restore() async => restores++;
}

/// O "Remover anúncios" com o estado dado pelo teste.
class FakePurchaseRepository implements PurchaseRepository {
  FakePurchaseRepository([this._state = const PurchaseState()]);

  final _changes = StreamController<PurchaseState>.broadcast();
  int buys = 0;

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
  Future<void> buy() async => buys++;
}
