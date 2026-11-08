import 'dart:async';

import '../../domain/use_cases/now.dart';
import 'coupon_service.dart';
import 'preferences_service.dart';
import 'purchase_service.dart';

/// A Play simulada do flavor dev e do E2E (decisão do Gabriel, H-R5-66):
/// os preços e as ofertas que o Console terá, a compra na hora com o token
/// de teste `teste:compra:<offerId|->:<uid>` que o `conferirCompra` aceita.
class DevPurchaseService implements PurchaseService {
  DevPurchaseService(this._preferences, {this._now = const SystemNow()});

  final PreferencesService _preferences;
  final Now _now;

  /// O que a conta comprou no dev: sobrevive a fechar o app.
  static const ownedKey = 'dev.store.owned';

  final _purchases = StreamController<StorePurchase>.broadcast();

  @override
  Stream<StorePurchase> get purchases => _purchases.stream;

  @override
  Future<bool> available() async => true;

  @override
  Future<StoreProduct?> product(String id) async => switch (id) {
    pilaresLifetimeProductId => StoreProduct(
      id: id,
      price: r'R$ 99,90',
      rawPrice: 99.9,
      currency: 'BRL',
      offers: _lifetimeOffers(_now().year),
    ),
    pilaresMonthlyProductId => StoreProduct(
      id: id,
      price: r'R$ 19,90',
      rawPrice: 19.9,
      currency: 'BRL',
    ),
    _ => null,
  };

  static List<StoreOffer> _lifetimeOffers(int year) => [
    StoreOffer(
      id: 'black-friday-$year',
      price: r'R$ 69,90',
      percent: 30,
      token: 'dev-offer-black-friday',
      startsAt: DateTime(year, 11, 27),
      endsAt: DateTime(year, 11, 30, 23, 59, 59),
      name: 'Black Friday',
    ),
    const StoreOffer(
      id: 'link-20',
      price: r'R$ 79,90',
      percent: 20,
      token: 'dev-offer-link-20',
      tags: [linkOfferTag],
    ),
    const StoreOffer(
      id: 'link-30',
      price: r'R$ 69,90',
      percent: 30,
      token: 'dev-offer-link-30',
      tags: [linkOfferTag],
    ),
  ];

  @override
  Future<void> buy(
    StoreProduct product, {
    StoreOffer? offer,
    String? accountId,
  }) async {
    final owned = await _owned();
    await _preferences.setString(ownedKey, {...owned, product.id}.join(','));
    // A janela da Play fecha na hora, com a compra aprovada.
    scheduleMicrotask(
      () => _purchases.add(
        StorePurchase(
          productId: product.id,
          status: StorePurchaseStatus.purchased,
          purchasedAt: _now(),
          token: 'teste:compra:${offer?.id ?? '-'}:${accountId ?? '-'}',
          offerId: offer?.id,
        ),
      ),
    );
  }

  @override
  Future<void> complete(StorePurchase purchase) async {}

  @override
  Future<List<StorePurchase>> owned() async => [
    for (final id in await _owned())
      StorePurchase(productId: id, status: StorePurchaseStatus.restored),
  ];

  Future<Set<String>> _owned() async {
    final stored = await _preferences.getString(ownedKey);
    if (stored == null || stored.isEmpty) return {};
    return stored.split(',').toSet();
  }
}

/// O `validarCupom` e o `reservarVaga` simulados do dev, com um código de
/// cada caso: `CXC20` (20% até 31/12), `CXC30` (30% sem fim), `FIM20`
/// (encerrado), `ESGOTADO` (vale, mas a vaga acaba na compra).
class DevCouponService implements CouponService {
  DevCouponService({this._now = const SystemNow()});

  final Now _now;

  /// Os tokens que o "servidor" recebeu.
  final confirmed = <String>[];

  @override
  Future<CouponCheck?> validate(String code) async {
    final year = _now().year;
    return switch (code) {
      'CXC20' => CouponValid(
        promotionId: 'dev-cxc20',
        code: code,
        offerId: 'link-20',
        endsAt: DateTime(year, 12, 31, 23, 59, 59),
      ),
      'CXC30' => CouponValid(
        promotionId: 'dev-cxc30',
        code: code,
        offerId: 'link-30',
      ),
      'ESGOTADO' => CouponValid(
        promotionId: 'dev-esgotado',
        code: code,
        offerId: 'link-20',
      ),
      'FIM20' => const CouponInvalid(CouponInvalidReason.ended),
      _ => const CouponInvalid(CouponInvalidReason.notFound),
    };
  }

  @override
  Future<void> reserve(String code) async {
    if (code == 'ESGOTADO') throw const CouponGoneException();
  }

  @override
  Future<void> confirmPurchase(String token) async => confirmed.add(token);
}
