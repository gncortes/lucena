import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ambiente.dart';
import 'ads_service.dart';

/// O UMP e o intersticial do AdMob pelo `google_mobile_ads` (E1.22). O
/// bloco vem de [AdMob.interstitialId]; o App ID, do manifest.
///
/// O pedido sai sem personalização para todos (`nonPersonalizedAds`, que o
/// plugin manda como `npa=1`; a Privacidade diz "Anúncios sem
/// personalização"), com conteúdo até PG. O formulário do UMP só aparece
/// onde o Google exige (EEE e Reino Unido). Quem está no modo equipe ([testAds]) vê o bloco de teste
/// do Google, para não gerar tráfego inválido.
class GoogleAdsService extends AdsService {
  GoogleAdsService({required String interstitialId, this._testAds})
    : _unitId = interstitialId;

  final String _unitId;
  final Future<bool> Function()? _testAds;
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
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(maxAdContentRating: MaxAdContentRating.pg),
    );
  }

  @override
  void preload() {
    if (!_initialized || _loading || _ad != null) return;
    _loading = true;
    unawaited(_load());
  }

  Future<void> _load() async {
    final test = await (_testAds?.call() ?? Future.value(false)).catchError(
      (Object _) => false,
    );
    await InterstitialAd.load(
      adUnitId: test ? AdMob.testInterstitialId : _unitId,
      request: const AdRequest(nonPersonalizedAds: true),
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
