import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// O ID do bloco intersticial do AdMob, passado pelo CI na versão final
/// (`--dart-define=ADMOB_INTERSTITIAL_ID=...`). Fora dela vale o de teste do
/// Google.
const _interstitialId = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');
const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

/// O consentimento do Google (UMP) e o intersticial do AdMob (E1.25).
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

/// `google_mobile_ads` com o UMP do próprio pacote.
class GoogleAdsService extends AdsService {
  /// Com [testAds] verdadeiro (o Modo equipe da E1.03), o anúncio é o de
  /// teste do Google.
  GoogleAdsService({String? interstitialId, this.testAds})
    : _unitId =
          interstitialId ??
          (kReleaseMode && _interstitialId.isNotEmpty
              ? _interstitialId
              : _testInterstitialId);

  final String _unitId;
  final Future<bool> Function()? testAds;
  InterstitialAd? _ad;
  bool _loading = false;
  bool _initialized = false;

  @override
  Future<void> updateConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      done.complete,
      (_) => done.complete(),
    );
    return done.future;
  }

  @override
  Future<void> showConsentFormIfRequired() =>
      ConsentForm.loadAndShowConsentFormIfRequired((_) {});

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  @override
  Future<void> showPrivacyOptions() {
    final done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((_) => done.complete());
    return done.future;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await MobileAds.instance.initialize();
  }

  @override
  void preload() {
    if (!_initialized || _loading || _ad != null) return;
    _loading = true;
    unawaited(_load());
  }

  Future<void> _load() async {
    final test = await testAds?.call() ?? false;
    await InterstitialAd.load(
      adUnitId: test ? _testInterstitialId : _unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
        },
        onAdFailedToLoad: (_) => _loading = false,
      ),
    );
  }

  @override
  bool get ready => _ad != null;

  @override
  Future<bool> show() {
    final ad = _ad;
    if (ad == null) return Future.value(false);
    _ad = null;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        unawaited(ad.dispose());
        done.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        unawaited(ad.dispose());
        done.complete(false);
      },
    );
    unawaited(ad.show());
    return done.future;
  }
}

/// Sem anúncio (F-Droid, sem Firebase, testes): nada é pedido nem mostrado.
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
