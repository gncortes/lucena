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
///
/// A V1 sai sem "Remover anúncios": só há o [NoPurchaseService]. O
/// `PlayPurchaseService`, com o `in_app_purchase`, está no commit b3fa571e.
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

/// Sem Play (V1, F-Droid, testes): nada à venda.
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
