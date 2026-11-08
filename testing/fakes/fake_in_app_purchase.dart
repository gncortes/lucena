import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// O `InAppPurchase` falso para o `PlayPurchaseService`: o teste diz os
/// produtos da loja ([products]), manda as compras por [send] e confere o
/// que foi comprado ([bought]) e reconhecido ([completed]).
///
/// O resto da interface (`getPlatformAddition`) fica sem implementar: o
/// serviço recebe as compras da conta por `pastPurchases` no teste.
class FakeInAppPurchase extends Fake implements InAppPurchase {
  FakeInAppPurchase({this.products = const [], this.isAvailableValue = true});

  List<ProductDetails> products;
  bool isAvailableValue;

  final _stream = StreamController<List<PurchaseDetails>>.broadcast();
  final bought = <PurchaseParam>[];
  final completed = <PurchaseDetails>[];

  void send(List<PurchaseDetails> purchases) => _stream.add(purchases);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _stream.stream;

  @override
  Future<bool> isAvailable() async => isAvailableValue;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: products.where((p) => identifiers.contains(p.id)).toList(),
    notFoundIDs: identifiers
        .where((id) => products.every((p) => p.id != id))
        .toList(),
  );

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    bought.add(purchaseParam);
    return true;
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    bought.add(purchaseParam);
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase);

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}

  @override
  Future<String> countryCode() async => 'BR';
}

/// Um produto da loja falsa.
ProductDetails fakeProduct(String id, {String price = 'R\$ 89,90'}) =>
    ProductDetails(
      id: id,
      title: id,
      description: '',
      price: price,
      rawPrice: 89.9,
      currencyCode: 'BRL',
    );

/// Uma compra da loja falsa, com o token [token].
PurchaseDetails fakePurchase(
  String productId, {
  PurchaseStatus status = PurchaseStatus.purchased,
  String token = 'token-1',
  bool pendingComplete = true,
  String? transactionDate = '1762560000000',
}) => PurchaseDetails(
  productID: productId,
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: token,
    source: 'google_play',
  ),
  transactionDate: transactionDate,
  status: status,
)..pendingCompletePurchase = pendingComplete;
