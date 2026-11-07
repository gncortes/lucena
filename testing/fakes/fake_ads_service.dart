import 'package:lucena/data/services/ads_service.dart';

/// O anúncio e o UMP falsos (testes e modo E2E): sem SDK, sem rede. O
/// anúncio é desenhado pelo app ([drawsInApp]) e está sempre pronto.
class FakeAdsService extends AdsService {
  FakeAdsService({this.consent = true, this.adReady = true});

  /// O que o SDK responderia a "pode pedir anúncio".
  bool consent;
  bool adReady;

  int consentUpdates = 0;
  int formsShown = 0;
  int preloads = 0;
  int shows = 0;
  bool initialized = false;

  @override
  Future<void> updateConsent() async => consentUpdates++;

  @override
  Future<void> showConsentFormIfRequired() async => formsShown++;

  @override
  Future<bool> canRequestAds() async => consent;

  @override
  Future<void> initialize() async => initialized = true;

  @override
  void preload() => preloads++;

  @override
  bool get ready => adReady;

  @override
  Future<bool> show() async {
    shows++;
    return true;
  }

  @override
  bool get drawsInApp => true;
}
