import 'dart:async';

import '../../services/preferences_service.dart';
import '../../services/purchase_service.dart';

/// "Remover anúncios" (E1.25, itens 4 a 6). [price] é o da Play, no país da
/// conta; nulo enquanto a loja não respondeu (ou sem Play).
class PurchaseState {
  const PurchaseState({
    this.adFree = false,
    this.pending = false,
    this.price,
    this.error = false,
  });

  final bool adFree;

  /// Compra feita, pagamento ainda não confirmado (cartão, boleto).
  final bool pending;
  final String? price;

  /// A última tentativa de compra falhou.
  final bool error;

  PurchaseState copyWith({
    bool? adFree,
    bool? pending,
    String? price,
    bool? error,
  }) => PurchaseState(
    adFree: adFree ?? this.adFree,
    pending: pending ?? this.pending,
    price: price ?? this.price,
    error: error ?? this.error,
  );

  @override
  bool operator ==(Object other) =>
      other is PurchaseState &&
      other.adFree == adFree &&
      other.pending == pending &&
      other.price == price &&
      other.error == error;

  @override
  int get hashCode => Object.hash(adFree, pending, price, error);
}

abstract class PurchaseRepository {
  PurchaseState get state;

  Stream<PurchaseState> get changes;

  /// Lê o que está guardado, escuta a loja e, sem esperar, restaura as
  /// compras da conta e busca o preço. Chamar uma vez, na abertura.
  Future<void> start();

  /// Abre a janela de pagamento da Play. O resultado chega por [changes].
  Future<void> buy();
}

/// Play Billing, com o estado guardado no aparelho: sem rede, vale o
/// guardado.
class PlayPurchaseRepository implements PurchaseRepository {
  PlayPurchaseRepository(
    this._service,
    this._preferences, {
    this._productId = removeAdsProductId,
  });

  final PurchaseService _service;
  final PreferencesService _preferences;
  final String _productId;

  static const adFreeKey = 'purchase.removeAds';
  static const pendingKey = 'purchase.pending';

  final _changes = StreamController<PurchaseState>.broadcast();
  StreamSubscription<StorePurchase>? _subscription;
  StoreProduct? _product;
  Future<void>? _started;

  @override
  PurchaseState get state => _state;
  PurchaseState _state = const PurchaseState();

  @override
  Stream<PurchaseState> get changes => _changes.stream;

  void _emit(PurchaseState next) {
    if (next == _state) return;
    _state = next;
    _changes.add(next);
  }

  @override
  Future<void> start() => _started ??= _start();

  Future<void> _start() async {
    final adFree = await _preferences.getBool(adFreeKey) ?? false;
    final pending = await _preferences.getBool(pendingKey) ?? false;
    _emit(_state.copyWith(adFree: adFree, pending: pending && !adFree));
    _subscription = _service.purchases.listen(_onPurchase);
    unawaited(_query());
  }

  Future<void> _query() async {
    try {
      if (!await _service.available()) return;
      await _service.restore();
      final product = await _service.product(_productId);
      if (product == null) return;
      _product = product;
      _emit(_state.copyWith(price: product.price));
    } on Exception {
      // Sem rede ou sem Play: vale o guardado, sem preço (a linha some).
    }
  }

  Future<void> _onPurchase(StorePurchase purchase) async {
    if (purchase.productId != _productId) return;
    switch (purchase.status) {
      case StorePurchaseStatus.purchased:
      case StorePurchaseStatus.restored:
        await _preferences.setBool(adFreeKey, value: true);
        await _preferences.remove(pendingKey);
        _emit(_state.copyWith(adFree: true, pending: false, error: false));
      case StorePurchaseStatus.pending:
        await _preferences.setBool(pendingKey, value: true);
        _emit(_state.copyWith(pending: true, error: false));
      case StorePurchaseStatus.canceled:
        await _preferences.remove(pendingKey);
        _emit(_state.copyWith(pending: false));
      case StorePurchaseStatus.error:
        await _preferences.remove(pendingKey);
        _emit(_state.copyWith(pending: false, error: true));
    }
    // O acknowledge: sem ele a Play devolve o dinheiro em 3 dias.
    if (purchase.needsCompletion) await _service.complete(purchase);
  }

  @override
  Future<void> buy() async {
    final product = _product;
    if (product == null || _state.adFree) return;
    _emit(_state.copyWith(error: false));
    try {
      await _service.buy(product);
    } on Exception {
      _emit(_state.copyWith(error: true));
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _changes.close();
  }
}

/// Sem Play (F-Droid, testes): nada à venda, os anúncios ficam.
class NoPurchaseRepository implements PurchaseRepository {
  const NoPurchaseRepository();

  @override
  PurchaseState get state => const PurchaseState();

  @override
  Stream<PurchaseState> get changes => const Stream.empty();

  @override
  Future<void> start() async {}

  @override
  Future<void> buy() async {}
}
