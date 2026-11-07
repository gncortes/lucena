/// Os ids do Pilares na Play Console (H-VEN-16): o acesso vitalício (não
/// consumível) e a assinatura mensal. São os únicos produtos que o app pede.
const pilaresLifetimeProductId = String.fromEnvironment(
  'PILARES_LIFETIME_PRODUCT',
  defaultValue: 'pilares_vitalicio',
);
const pilaresMonthlyProductId = String.fromEnvironment(
  'PILARES_MONTHLY_PRODUCT',
  defaultValue: 'pilares_mensal',
);

/// Um produto da loja, com o preço já formatado no país da conta.
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.price,
    this.rawPrice,
    this.currency,
    this.offers = const [],
  });

  final String id;
  final String price;

  /// O valor e a moeda, para o evento `purchase`.
  final double? rawPrice;
  final String? currency;

  /// As ofertas com desconto do produto (só o vitalício tem, regra 10).
  final List<StoreOffer> offers;
}

/// A tag das ofertas que só o link libera (contrato de promoções, R23).
const linkOfferTag = 'lucena-link';

/// Uma oferta com desconto da Play (one-time product offer): id, tags,
/// percentual, janela de validade e o preço já formatado pela loja.
class StoreOffer {
  const StoreOffer({
    required this.id,
    required this.price,
    required this.percent,
    required this.token,
    this.tags = const [],
    this.startsAt,
    this.endsAt,
    this.name,
  });

  final String id;
  final String price;
  final int percent;

  /// O `offerToken` que vai no `launchBillingFlow`.
  final String token;
  final List<String> tags;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// O nome da promoção para todos ("Black Friday").
  final String? name;

  /// Só o link libera esta oferta.
  bool get onlyByLink => tags.contains(linkOfferTag);

  bool activeAt(DateTime now) {
    final start = startsAt;
    final end = endsAt;
    if (start != null && now.isBefore(start)) return false;
    return end == null || now.isBefore(end);
  }
}

enum StorePurchaseStatus { pending, purchased, restored, canceled, error }

/// Uma compra vinda da loja. [needsCompletion]: a compra tem que ser
/// reconhecida (acknowledge), senão a Play devolve o dinheiro.
class StorePurchase {
  const StorePurchase({
    required this.productId,
    required this.status,
    this.needsCompletion = false,
    this.purchasedAt,
    this.renewsAt,
    this.graceUntil,
    this.token,
    this.offerId,
  });

  final String productId;
  final StorePurchaseStatus status;
  final bool needsCompletion;
  final DateTime? purchasedAt;

  /// A próxima renovação (só na assinatura).
  final DateTime? renewsAt;

  /// A loja não conseguiu cobrar e dá até esta data para regularizar.
  final DateTime? graceUntil;

  /// O token da compra, que o servidor confere (`conferirCompra`).
  final String? token;

  /// A oferta com desconto usada na compra.
  final String? offerId;
}

/// A loja não respondeu por falta de rede.
class StoreOfflineException implements Exception {
  const StoreOfflineException();
}

/// A Play Billing atrás de interface (E1.25, H-VEN-16).
abstract class PurchaseService {
  /// O resultado das compras abertas por [buy] (e o pendente que confirmou).
  Stream<StorePurchase> get purchases;

  Future<bool> available();

  /// O produto [id], ou nulo se a loja não o conhece.
  Future<StoreProduct?> product(String id);

  /// Abre a janela de pagamento (ou de assinatura) da Play, com a
  /// [offer] com desconto e a conta [accountId] (`obfuscatedAccountId`).
  Future<void> buy(
    StoreProduct product, {
    StoreOffer? offer,
    String? accountId,
  });

  /// Reconhece a compra.
  Future<void> complete(StorePurchase purchase);

  /// As compras ativas da conta da loja (restaurar, conferir ao abrir).
  /// Lança [StoreOfflineException] sem rede.
  Future<List<StorePurchase>> owned();
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
  Future<void> buy(
    StoreProduct product, {
    StoreOffer? offer,
    String? accountId,
  }) async {}

  @override
  Future<void> complete(StorePurchase purchase) async {}

  @override
  Future<List<StorePurchase>> owned() async => const [];
}

/// A compra feita pelo site, que chega pela conta (H-VEN-08).
abstract class SitePurchaseService {
  /// A data da compra do Pilares pela conta que está entrada, ou nulo.
  /// Lança [StoreOfflineException] sem rede.
  Future<DateTime?> pilaresPurchasedAt();
}

/// Sem o servidor das compras do site.
class NoSitePurchaseService implements SitePurchaseService {
  const NoSitePurchaseService();

  @override
  Future<DateTime?> pilaresPurchasedAt() async => null;
}
