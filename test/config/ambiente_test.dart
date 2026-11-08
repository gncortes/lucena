import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/config/ambiente.dart';

void main() {
  test('--flavor prod vira Ambiente.prod (isProd)', () {
    expect(Ambiente.atual(flavor: 'prod'), Ambiente.prod);
    expect(Ambiente.atual(flavor: 'prod').isProd, isTrue);
  });

  test('flavor dev, ausente ou desconhecido vira Ambiente.dev', () {
    expect(Ambiente.atual(flavor: 'dev'), Ambiente.dev);
    expect(Ambiente.atual(flavor: null), Ambiente.dev);
    expect(Ambiente.atual(flavor: 'hml'), Ambiente.dev);
    expect(Ambiente.dev.isProd, isFalse);
  });

  test('sem flavor no teste, o ambiente atual é dev', () {
    expect(Ambiente.atual(), Ambiente.dev);
  });

  test('cada ambiente tem o seu site', () {
    expect(Ambiente.dev.siteHost, 'dev.playlucenachess.com');
    expect(Ambiente.prod.siteHost, 'playlucenachess.com');
  });

  group('AdMob (E1.22)', () {
    test('dev usa sempre o bloco de teste do Google, com ou sem id do CI', () {
      expect(
        AdMob.interstitialId(define: '', ambiente: Ambiente.dev),
        AdMob.testInterstitialId,
      );
      expect(
        AdMob.interstitialId(define: 'ca-app-pub-1/2', ambiente: Ambiente.dev),
        AdMob.testInterstitialId,
      );
    });

    test('prod usa o bloco do CI', () {
      expect(
        AdMob.interstitialId(
          define: ' ca-app-pub-1/2 ',
          ambiente: Ambiente.prod,
        ),
        'ca-app-pub-1/2',
      );
    });

    test('prod sem id do CI fica sem anúncio, nunca com o de teste', () {
      expect(AdMob.interstitialId(define: '', ambiente: Ambiente.prod), isNull);
      expect(
        AdMob.interstitialId(define: '  ', ambiente: Ambiente.prod),
        isNull,
      );
      expect(
        AdMob.interstitialId(
          define: AdMob.testInterstitialId,
          ambiente: Ambiente.prod,
        ),
        isNull,
      );
    });

    test('sem define no teste, o build é dev com o bloco de teste', () {
      expect(AdMob.interstitialId(), AdMob.testInterstitialId);
    });

    test('os ids de teste são os oficiais do Google', () {
      expect(AdMob.testAppId, 'ca-app-pub-3940256099942544~3347511713');
      expect(
        AdMob.testInterstitialId,
        'ca-app-pub-3940256099942544/1033173712',
      );
    });
  });
}
