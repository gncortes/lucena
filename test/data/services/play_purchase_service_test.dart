import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:lucena/data/services/play_purchase_service.dart';
import 'package:lucena/data/services/purchase_service.dart';

import '../../../testing/fakes/fake_in_app_purchase.dart';

void main() {
  late FakeInAppPurchase store;
  late List<PurchaseDetails> past;
  late PlayPurchaseService service;

  setUp(() {
    store = FakeInAppPurchase(
      products: [
        fakeProduct(pilaresLifetimeProductId),
        fakeProduct(pilaresMonthlyProductId, price: 'R\$ 17,90'),
      ],
    );
    past = [];
    service = PlayPurchaseService(
      store: store,
      pastPurchases: () async => past,
    );
  });

  test('a loja disponível vem do plugin', () async {
    expect(await service.available(), isTrue);
    store.isAvailableValue = false;
    expect(await service.available(), isFalse);
  });

  test('produto: preço, valor e moeda; o avulso sai sem ofertas', () async {
    final product = await service.product(pilaresLifetimeProductId);

    expect(product!.id, pilaresLifetimeProductId);
    expect(product.price, 'R\$ 89,90');
    expect(product.rawPrice, 89.9);
    expect(product.currency, 'BRL');
    expect(product.offers, isEmpty);
  });

  test('produto que a loja não conhece é nulo', () async {
    expect(await service.product('outro'), isNull);
  });

  test('comprar abre a Play com o produto e a conta', () async {
    final product = await service.product(pilaresMonthlyProductId);

    await service.buy(product!, accountId: 'uid-1');

    expect(store.bought, hasLength(1));
    final param = store.bought.single;
    expect(param, isA<GooglePlayPurchaseParam>());
    expect(param.productDetails.id, pilaresMonthlyProductId);
    expect(param.applicationUserName, 'uid-1');
  });

  test('comprar um produto que não veio da loja não abre nada', () async {
    await service.buy(const StoreProduct(id: 'x', price: ''));

    expect(store.bought, isEmpty);
  });

  test(
    'a compra paga chega com token e data e é reconhecida uma vez',
    () async {
      final received = <StorePurchase>[];
      final sub = service.purchases.listen(received.add);

      final details = fakePurchase(pilaresLifetimeProductId, token: 'tok');
      store.send([details]);
      await pumpEventQueue();

      final purchase = received.single;
      expect(purchase.productId, pilaresLifetimeProductId);
      expect(purchase.status, StorePurchaseStatus.purchased);
      expect(purchase.needsCompletion, isTrue);
      expect(purchase.token, 'tok');
      expect(
        purchase.purchasedAt,
        DateTime.fromMillisecondsSinceEpoch(1762560000000),
      );

      await service.complete(purchase);
      await service.complete(purchase);

      expect(store.completed, [details]);
      await sub.cancel();
    },
  );

  test('cada estado da Play vira o seu', () async {
    final received = <StorePurchase>[];
    final sub = service.purchases.listen(received.add);

    store.send([
      fakePurchase('a', status: PurchaseStatus.pending, token: '1'),
      fakePurchase('b', status: PurchaseStatus.restored, token: '2'),
      fakePurchase('c', status: PurchaseStatus.canceled, token: '3'),
      fakePurchase('d', status: PurchaseStatus.error, token: '4'),
    ]);
    await pumpEventQueue();

    expect(received.map((p) => p.status), [
      StorePurchaseStatus.pending,
      StorePurchaseStatus.restored,
      StorePurchaseStatus.canceled,
      StorePurchaseStatus.error,
    ]);
    // Só a compra paga se reconhece.
    expect(received.map((p) => p.needsCompletion), [false, true, false, false]);
    await sub.cancel();
  });

  test('as compras da conta: a paga conta como restaurada', () async {
    past = [
      fakePurchase(
        pilaresLifetimeProductId,
        token: 'a',
        pendingComplete: false,
      ),
      fakePurchase(
        pilaresMonthlyProductId,
        status: PurchaseStatus.pending,
        token: 'b',
      ),
    ];

    final owned = await service.owned();

    expect(owned.map((p) => p.status), [
      StorePurchaseStatus.restored,
      StorePurchaseStatus.pending,
    ]);
    expect(owned.first.needsCompletion, isFalse);
    expect(owned.map((p) => p.token), ['a', 'b']);
  });

  test('a compra antiga ainda sem reconhecer é reconhecida', () async {
    final details = fakePurchase(pilaresLifetimeProductId, token: 'velha');
    past = [details];

    final owned = await service.owned();
    await service.complete(owned.single);

    expect(owned.single.needsCompletion, isTrue);
    expect(store.completed, [details]);
  });

  test('sem rede, as compras da conta lançam StoreOfflineException', () async {
    service = PlayPurchaseService(
      store: store,
      pastPurchases: () async =>
          throw PlatformException(code: 'SERVICE_UNAVAILABLE'),
    );

    expect(service.owned(), throwsA(isA<StoreOfflineException>()));
  });
}
