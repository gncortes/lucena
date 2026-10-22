import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// O id do produto "Remover anúncios" na Play Console (não consumível).
const removeAdsProductId = String.fromEnvironment(
  'REMOVE_ADS_PRODUCT',
  defaultValue: 'remove_ads',
);

/// Um produto da loja, com o preço já formatado no país da conta.
class StoreProduct {
  const StoreProduct({required this.id, required this.price});

  final String id;
  final String price;
}

enum StorePurchaseStatus { pending, purchased, restored, canceled, error }

/// Uma atualização de compra vinda da loja. [needsCompletion]: a compra tem
/// que ser reconhecida (acknowledge), senão a Play devolve o dinheiro.
class StorePurchase {
  const StorePurchase({
    required this.productId,
    required this.status,
    this.needsCompletion = false,
  });

  final String productId;
  final StorePurchaseStatus status;
  final bool needsCompletion;
}

/// A Play Billing atrás de interface (E1.25).
abstract class PurchaseService {
  /// As atualizações de compra (comprar, restaurar, pendente que confirmou).
  Stream<StorePurchase> get purchases;

  Future<bool> available();

  /// O produto [id], ou nulo se a loja não o conhece.
  Future<StoreProduct?> product(String id);

  /// Abre a janela de pagamento da Play.
  Future<void> buy(StoreProduct product);

  /// Reconhece a compra.
  Future<void> complete(StorePurchase purchase);

  /// Pede de novo as compras da conta; chegam por [purchases].
  Future<void> restore();
}

/// `in_app_purchase` (Play Billing).
class PlayPurchaseService implements PurchaseService {
  PlayPurchaseService([InAppPurchase? store])
    : _store = store ?? InAppPurchase.instance;

  final InAppPurchase _store;
  final _products = <String, ProductDetails>{};
  final _raw = <StorePurchase, PurchaseDetails>{};

  @override
  Stream<StorePurchase> get purchases => _store.purchaseStream.expand(
    (list) => list.map((details) {
      final purchase = StorePurchase(
        productId: details.productID,
        status: switch (details.status) {
          PurchaseStatus.pending => StorePurchaseStatus.pending,
          PurchaseStatus.purchased => StorePurchaseStatus.purchased,
          PurchaseStatus.restored => StorePurchaseStatus.restored,
          PurchaseStatus.canceled => StorePurchaseStatus.canceled,
          PurchaseStatus.error => StorePurchaseStatus.error,
        },
        needsCompletion: details.pendingCompletePurchase,
      );
      if (details.pendingCompletePurchase) _raw[purchase] = details;
      return purchase;
    }),
  );

  @override
  Future<bool> available() => _store.isAvailable();

  @override
  Future<StoreProduct?> product(String id) async {
    final response = await _store.queryProductDetails({id});
    if (response.productDetails.isEmpty) return null;
    final details = response.productDetails.first;
    _products[details.id] = details;
    return StoreProduct(id: details.id, price: details.price);
  }

  @override
  Future<void> buy(StoreProduct product) async {
    final details = _products[product.id];
    if (details == null) return;
    await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  @override
  Future<void> complete(StorePurchase purchase) async {
    final details = _raw.remove(purchase);
    if (details != null) await _store.completePurchase(details);
  }

  @override
  Future<void> restore() => _store.restorePurchases();
}

/// Sem Play (F-Droid, testes): nada à venda.
class NoPurchaseService implements PurchaseService {
  const NoPurchaseService();

  @override
  Stream<StorePurchase> get purchases => const Stream.empty();

  @override
  Future<bool> available() async => false;

  @override
  Future<StoreProduct?> product(String id) async => null;

  @override
  Future<void> buy(StoreProduct product) async {}

  @override
  Future<void> complete(StorePurchase purchase) async {}

  @override
  Future<void> restore() async {}
}
