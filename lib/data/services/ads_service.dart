/// O consentimento do Google (UMP) e o intersticial do AdMob (E1.25).
///
/// A V1 sai sem anúncios: só há o [NoAdsService]. O `GoogleAdsService`, com o
/// `google_mobile_ads`, está no commit b3fa571e (branch tarefa/E1.25-anuncios).
abstract class AdsService {
  /// Pede ao Google as informações de consentimento. Sem rede, termina sem
  /// erro.
  Future<void> updateConsent();

  /// Mostra o formulário do Google se ele for exigido.
  Future<void> showConsentFormIfRequired();

  /// O SDK diz que já pode pedir anúncio (consentimento resolvido).
  Future<bool> canRequestAds();

  /// As opções de privacidade ("Escolhas de anúncios") são exigidas.
  Future<bool> privacyOptionsRequired();

  /// Reabre as opções de privacidade do Google.
  Future<void> showPrivacyOptions();

  /// Sobe o SDK de anúncios. Só depois disto [preload] carrega.
  Future<void> initialize();

  /// Carrega o próximo intersticial em segundo plano, sem esperar.
  void preload();

  /// Há um intersticial carregado.
  bool get ready;

  /// Mostra o carregado e termina quando ele fecha. `false`: não exibiu.
  Future<bool> show();

  /// O anúncio é desenhado pelo app (o falso do modo E2E), não pelo SDK.
  bool get drawsInApp => false;
}

/// Sem anúncio (V1, F-Droid, testes): nada é pedido nem mostrado.
class NoAdsService extends AdsService {
  NoAdsService();

  @override
  Future<void> updateConsent() async {}

  @override
  Future<void> showConsentFormIfRequired() async {}

  @override
  Future<bool> canRequestAds() async => false;

  @override
  Future<bool> privacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<void> initialize() async {}

  @override
  void preload() {}

  @override
  bool get ready => false;

  @override
  Future<bool> show() async => false;
}
