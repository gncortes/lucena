import 'package:flutter/widgets.dart';

abstract final class AdsKeys {
  /// O anúncio falso do modo E2E (sem SDK, sem rede).
  static const fakeInterstitial = Key('ads.fakeInterstitial');
  static const fakeClose = Key('ads.fakeClose');
}
