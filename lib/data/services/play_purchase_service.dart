import 'dart:async';

import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'purchase_service.dart';

/// A Play Billing de verdade (flavor `prod`, E1.22), pelo `in_app_purchase`.
///
/// Limite do plugin (in_app_purchase_android 0.5.x): as ofertas com desconto
/// do produto avulso (one-time product offers) não chegam ao Dart, sem id,
/// tag nem token. Por isso o vitalício sai sempre sem [StoreProduct.offers] e
/// a compra vai pelo preço cheio.
class PlayPurchaseService implements PurchaseService {
  /// [_pastPurchases] existe para o teste; o padrão pergunta à Play as
  /// compras da conta (`queryPastPurchases`).
  PlayPurchaseService({InAppPurchase? store, this._pastPurchases})
    : _injected = store;

  final InAppPurchase? _injected;

  // Pedido só no primeiro uso: criar o serviço não sobe o plugin.
  InAppPurchase get _store => _injected ?? InAppPurchase.instance;

  final Future<List<PurchaseDetails>> Function()? _pastPurchases;
  final _products = <String, ProductDetails>{};

  /// O detalhe cru de cada compra que ainda falta reconhecer.
  final _raw = <String, PurchaseDetails>{};

  @override
  Stream<StorePurchase> get purchases =>
      _store.purchaseStream.expand((list) => list.map(_toStore));

  @override
  Future<bool> available() => _store.isAvailable();

  @override
  Future<StoreProduct?> product(String id) async {
    final response = await _store.queryProductDetails({id});
    final details = _basePlan(
      response.productDetails.where((d) => d.id == id).toList(),
    );
    if (details == null) return null;
    _products[id] = details;
    return StoreProduct(
      id: id,
      price: details.price,
      rawPrice: details.rawPrice,
      currency: details.currencyCode,
    );
  }

  /// A assinatura vem uma vez por plano e oferta: vale o plano base (sem
  /// oferta). O avulso vem uma vez só.
  static ProductDetails? _basePlan(List<ProductDetails> all) {
    for (final details in all) {
      if (details is! GooglePlayProductDetails) continue;
      final index = details.subscriptionIndex;
      if (index == null) return details;
      final offers = details.productDetails.subscriptionOfferDetails;
      if (offers != null && offers[index].offerId == null) return details;
    }
    return all.firstOrNull;
  }

  @override
  Future<void> buy(
    StoreProduct product, {
    StoreOffer? offer,
    String? accountId,
  }) async {
    final details = _products[product.id];
    if (details == null) return;
    // O offerToken do plano base vai sozinho (GooglePlayProductDetails); a
    // oferta do avulso não tem token no plugin (ver a classe).
    await _store.buyNonConsumable(
      purchaseParam: GooglePlayPurchaseParam(
        productDetails: details,
        applicationUserName: accountId,
      ),
    );
  }

  @override
  Future<void> complete(StorePurchase purchase) async {
    final key = purchase.token ?? purchase.productId;
    final details = _raw.remove(key);
    if (details != null) await _store.completePurchase(details);
  }

  @override
  Future<List<StorePurchase>> owned() async {
    final List<PurchaseDetails> past;
    try {
      past = await (_pastPurchases ?? _queryPastPurchases)();
    } on PlatformException {
      throw const StoreOfflineException();
    }
    return [for (final details in past) _toStore(details, owned: true)];
  }

  Future<List<PurchaseDetails>> _queryPastPurchases() async {
    final response = await _store
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
        .queryPastPurchases();
    if (response.error != null) throw const StoreOfflineException();
    return response.pastPurchases;
  }

  StorePurchase _toStore(PurchaseDetails details, {bool owned = false}) {
    final status = switch (details.status) {
      PurchaseStatus.pending => StorePurchaseStatus.pending,
      // A compra que a conta já tem conta como restaurada.
      PurchaseStatus.purchased when owned => StorePurchaseStatus.restored,
      PurchaseStatus.purchased => StorePurchaseStatus.purchased,
      PurchaseStatus.restored => StorePurchaseStatus.restored,
      PurchaseStatus.canceled => StorePurchaseStatus.canceled,
      PurchaseStatus.error => StorePurchaseStatus.error,
    };
    final token = details.verificationData.serverVerificationData;
    final paid =
        status == StorePurchaseStatus.purchased ||
        status == StorePurchaseStatus.restored;
    final needsCompletion = paid && details.pendingCompletePurchase;
    if (needsCompletion) {
      _raw[token.isEmpty ? details.productID : token] = details;
    }
    final millis = int.tryParse(details.transactionDate ?? '');
    return StorePurchase(
      productId: details.productID,
      status: status,
      needsCompletion: needsCompletion,
      purchasedAt: millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis),
      token: token.isEmpty ? null : token,
    );
  }
}
