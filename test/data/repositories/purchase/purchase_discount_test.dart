import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/data/services/coupon_service.dart';
import 'package:lucena/data/services/dev_store.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/data/services/purchase_service.dart';
import 'package:lucena/domain/models/offer_discount.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_purchase_service.dart';

/// H-R5-66: o desconto do vitalício (contrato de promoções, regras 2, 5, 6
/// e 10) com a Play e o servidor simulados.
void main() {
  late FakePurchaseService play;
  late DevCouponService coupons;
  late FakeNow now;
  String? uid;

  final blackFriday = StoreOffer(
    id: 'black-friday-2026',
    price: 'R\$ 62,90',
    percent: 30,
    token: 'tok-bf',
    startsAt: DateTime(2026, 11, 27),
    endsAt: DateTime(2026, 11, 30, 23, 59, 59),
    name: 'Black Friday',
  );
  const link20 = StoreOffer(
    id: 'link-20',
    price: 'R\$ 71,90',
    percent: 20,
    token: 'tok-20',
    tags: [linkOfferTag],
  );
  const link30 = StoreOffer(
    id: 'link-30',
    price: 'R\$ 62,90',
    percent: 30,
    token: 'tok-30',
    tags: [linkOfferTag],
  );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    play = FakePurchaseService(offers: [blackFriday, link20, link30]);
    now = FakeNow(DateTime(2026, 11, 7, 10));
    coupons = DevCouponService(now: now);
    uid = 'u1';
  });

  Future<PlayPurchaseRepository> open() async {
    final repository = PlayPurchaseRepository(
      play,
      PreferencesService(),
      now: now,
      coupons: coupons,
      uid: () => uid,
    );
    await repository.start();
    await pumpEventQueue();
    return repository;
  }

  test('sem promoção nem link, sem desconto', () async {
    final repository = await open();
    expect(repository.state.discount, null);
    expect(repository.state.linkGone, false);
  });

  test(
    'a promoção para todos vale só na janela, com o preço da loja',
    () async {
      now.value = DateTime(2026, 11, 28, 9);
      final repository = await open();
      final discount = repository.state.discount!;
      expect(discount.kind, DiscountKind.everyone);
      expect(discount.price, 'R\$ 62,90');
      expect(discount.fullPrice, 'R\$ 89,90');
      expect(discount.name, 'Black Friday');
      expect(discount.endsAt, DateTime(2026, 11, 30, 23, 59, 59));
    },
  );

  test('o link vale com conta e mostra o fim que o servidor deu', () async {
    final repository = await open();
    await repository.useOfferCode('cxc20');
    final discount = repository.state.discount!;
    expect(discount.kind, DiscountKind.link);
    expect(discount.offerId, 'link-20');
    expect(discount.percent, 20);
    expect(discount.endsAt, DateTime(2026, 12, 31, 23, 59, 59));
  });

  test('sem conta, o código espera; ao entrar, vira desconto', () async {
    uid = null;
    final repository = await open();
    await repository.useOfferCode('CXC20');
    expect(repository.state.discount, null);
    uid = 'u1';
    await repository.refresh();
    expect(repository.state.discount?.offerId, 'link-20');
  });

  test('o código guardado vale 30 dias e sobrevive a fechar o app', () async {
    await (await open()).useOfferCode('CXC30');
    now.advance(const Duration(days: 29));
    expect((await open()).state.discount?.offerId, 'link-30');
    now.advance(const Duration(days: 2));
    expect((await open()).state.discount, null);
  });

  test('link que não vale: preço cheio e o aviso, uma vez', () async {
    final repository = await open();
    await repository.useOfferCode('FIM20');
    expect(repository.state.discount, null);
    expect(repository.state.linkGone, true);
    // Fechou o app antes de ver: o aviso volta.
    expect((await open()).state.linkGone, true);
    await repository.dismissLinkNotice();
    expect(repository.state.linkGone, false);
    expect((await open()).state.linkGone, false);
  });

  test('promoção e link valendo: vence o maior (regra 5)', () async {
    now.value = DateTime(2026, 11, 28, 9);
    final repository = await open();
    await repository.useOfferCode('CXC20');
    expect(repository.state.discount?.offerId, 'black-friday-2026');
    await repository.useOfferCode('CXC30');
    // Empate em 30%: vence o que termina primeiro (o link não tem fim).
    expect(repository.state.discount?.offerId, 'black-friday-2026');
  });

  test('a compra leva a oferta e a conta; o token vai ao servidor', () async {
    final repository = await open();
    await repository.useOfferCode('CXC20');
    await repository.buy(PilaresPlan.lifetime);
    expect(play.boughtOffers.single?.id, 'link-20');
    expect(play.boughtAccounts.single, 'u1');
    play.send(
      StorePurchase(
        productId: pilaresLifetimeProductId,
        status: StorePurchaseStatus.purchased,
        token: 'teste:compra:link-20:u1',
        offerId: 'link-20',
      ),
    );
    await pumpEventQueue();
    expect(coupons.confirmed, ['teste:compra:link-20:u1']);
    expect(repository.state.access.owns, true);
    // O código foi usado: não volta.
    expect((await open()).state.discount, null);
  });

  test('o mensal não leva desconto', () async {
    final repository = await open();
    await repository.useOfferCode('CXC20');
    await repository.buy(PilaresPlan.monthly);
    expect(play.boughtOffers.single, null);
  });

  test(
    'vagas esgotadas na compra: não abre a Play, preço cheio e o aviso',
    () async {
      final repository = await open();
      await repository.useOfferCode('ESGOTADO');
      expect(repository.state.discount?.kind, DiscountKind.link);
      await repository.buy(PilaresPlan.lifetime);
      expect(play.bought, isEmpty);
      expect(repository.state.processing, false);
      expect(repository.state.discount, null);
      expect(repository.state.linkGone, true);
    },
  );

  test('sem rede para conferir, o código fica guardado', () async {
    final repository = PlayPurchaseRepository(
      play,
      PreferencesService(),
      now: now,
      coupons: const NoCouponService(),
      uid: () => uid,
    );
    await repository.start();
    await pumpEventQueue();
    await repository.useOfferCode('CXC20');
    expect(repository.state.discount, null);
    expect(repository.state.linkGone, false);
    expect(
      await PreferencesService().getString(PlayPurchaseRepository.offerCodeKey),
      isNotNull,
    );
  });

  group('DevPurchaseService', () {
    test('preço, ofertas do Console e compra com o token de teste', () async {
      final store = DevPurchaseService(PreferencesService(), now: now);
      final product = (await store.product(pilaresLifetimeProductId))!;
      expect(product.price, 'R\$ 99,90');
      expect(product.offers.map((o) => o.id), [
        'black-friday-2026',
        'link-20',
        'link-30',
      ]);
      final bought = store.purchases.first;
      await store.buy(product, offer: product.offers[1], accountId: 'u1');
      final purchase = await bought;
      expect(purchase.status, StorePurchaseStatus.purchased);
      expect(purchase.token, 'teste:compra:link-20:u1');
      expect((await store.owned()).single.productId, pilaresLifetimeProductId);
    });

    test('sem oferta, o token leva "-"', () async {
      final store = DevPurchaseService(PreferencesService(), now: now);
      final product = (await store.product(pilaresMonthlyProductId))!;
      final bought = store.purchases.first;
      await store.buy(product, accountId: 'u1');
      expect((await bought).token, 'teste:compra:-:u1');
    });
  });
}
