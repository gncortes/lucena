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
  });

  final String id;
  final String price;

  /// O valor e a moeda, para o evento `purchase`.
  final double? rawPrice;
  final String? currency;
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
  });

  final String productId;
  final StorePurchaseStatus status;
  final bool needsCompletion;
  final DateTime? purchasedAt;

  /// A próxima renovação (só na assinatura).
  final DateTime? renewsAt;

  /// A loja não conseguiu cobrar e dá até esta data para regularizar.
  final DateTime? graceUntil;
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

  /// Abre a janela de pagamento (ou de assinatura) da Play.
  Future<void> buy(StoreProduct product);

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
  Future<void> buy(StoreProduct product) async {}

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
