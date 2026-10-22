import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/ads/ads_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/ads_state.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_ads_service.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_purchase_service.dart';
import '../../../../testing/fakes/fake_remote_flags_repository.dart';

void main() {
  late FakeAdsService service;
  late FakeNow now;
  late FakeRemoteFlagsRepository flags;
  late FakePurchaseRepository purchases;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    service = FakeAdsService();
    now = FakeNow(DateTime.utc(2026, 10, 22, 10));
    flags = FakeRemoteFlagsRepository(
      adsEnabled: true,
      adsFreeLessons: 2,
      adsMinGapSeconds: 180,
    );
    purchases = FakePurchaseRepository();
  });

  ServiceAdsRepository open() => ServiceAdsRepository(
    service: service,
    preferences: PreferencesService(),
    flags: flags,
    purchases: purchases,
    now: now,
  );

  // Uma abertura do app já com a pergunta respondida.
  Future<ServiceAdsRepository> session() async {
    final ads = open();
    await ads.start(fromLink: false, goalAnswered: true);
    await pumpEventQueue();
    return ads;
  }

  Future<AdOutcome> lesson(ServiceAdsRepository ads, String id) =>
      ads.beforeLesson(lessonId: id, kind: LessonKind.endgame);

  test('a 1ª sessão não tem anúncio; na 2ª, a partir da 3ª lição', () async {
    final first = await session();
    for (final id in ['a', 'b', 'c', 'd']) {
      expect(await lesson(first, id), AdOutcome.none);
    }
    final second = await session();
    expect(await lesson(second, 'e'), AdOutcome.showInApp);
    expect(second.shownThisSession, isTrue);
  });

  test('a carência conta as lições, não as sessões', () async {
    await session();
    final second = await session();
    expect(await lesson(second, 'a'), AdOutcome.none);
    expect(await lesson(second, 'b'), AdOutcome.none);
    expect(await lesson(second, 'c'), AdOutcome.showInApp);
  });

  test('intervalo mínimo e 1 por lição na sessão', () async {
    await session();
    final ads = await session();
    await lesson(ads, 'a');
    await lesson(ads, 'b');
    expect(await lesson(ads, 'c'), AdOutcome.showInApp);
    now.advance(const Duration(seconds: 60));
    expect(await lesson(ads, 'd'), AdOutcome.none);
    now.advance(const Duration(seconds: 200));
    expect(await lesson(ads, 'c'), AdOutcome.none);
    expect(await lesson(ads, 'd'), AdOutcome.showInApp);
  });

  test('30 minutos em segundo plano começa sessão nova', () async {
    await session();
    final ads = await session();
    await lesson(ads, 'a');
    await lesson(ads, 'b');
    expect(await lesson(ads, 'c'), AdOutcome.showInApp);
    ads.hidden();
    now.advance(const Duration(minutes: 10));
    ads.visible();
    now.advance(const Duration(minutes: 5));
    expect(await lesson(ads, 'c'), AdOutcome.none);
    ads.hidden();
    now.advance(const Duration(minutes: 30));
    ads.visible();
    expect(ads.shownThisSession, isFalse);
    expect(await lesson(ads, 'c'), AdOutcome.showInApp);
  });

  test('desafio por link nunca tem anúncio', () async {
    await session();
    final ads = await session();
    for (final id in ['a', 'b', 'c']) {
      expect(
        await ads.beforeLesson(lessonId: id, kind: LessonKind.challengeLink),
        AdOutcome.none,
      );
    }
  });

  test('sem consentimento, nem o SDK sobe', () async {
    service.consent = false;
    await session();
    final ads = await session();
    for (final id in ['a', 'b', 'c', 'd']) {
      expect(await lesson(ads, id), AdOutcome.none);
    }
    expect(service.initialized, isFalse);
  });

  test('anúncio não carregado: abre direto e pede outro', () async {
    await session();
    final ads = await session();
    service.adReady = false;
    final preloads = service.preloads;
    for (final id in ['a', 'b', 'c']) {
      expect(await lesson(ads, id), AdOutcome.none);
    }
    expect(service.preloads, greaterThan(preloads));
  });

  test('ads_enabled desligado no Remote Config, nada', () async {
    await session();
    final ads = await session();
    flags.adsEnabled = false;
    for (final id in ['a', 'b', 'c']) {
      expect(await lesson(ads, id), AdOutcome.none);
    }
  });

  test('sem anúncios comprado: nem consentimento nem anúncio', () async {
    purchases.state = const PurchaseState(adFree: true);
    await session();
    final ads = await session();
    for (final id in ['a', 'b', 'c']) {
      expect(await lesson(ads, id), AdOutcome.none);
    }
    expect(service.consentUpdates, 0);
    expect(await ads.privacyOptionsRequired(), isFalse);
  });

  test('primeira abertura: o formulário espera a pergunta', () async {
    final ads = open();
    await ads.start(fromLink: false, goalAnswered: false);
    await pumpEventQueue();
    expect(service.consentUpdates, 0);
    await ads.requestConsent();
    expect(service.formsShown, 1);
  });

  test('vindo de um link, o formulário fica para depois', () async {
    final ads = open();
    await ads.start(fromLink: true, goalAnswered: true);
    await pumpEventQueue();
    expect(service.consentUpdates, 1);
    expect(service.formsShown, 0);
  });
}
