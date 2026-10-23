import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/analytics/analytics_repository.dart';
import 'package:lucena/data/services/firebase/analytics_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/analytics_event.dart';
import 'package:lucena/domain/use_cases/analytics_rules.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _FakeService implements AnalyticsService {
  final events = <(String, Map<String, Object>)>[];
  final properties = <(String, String?)>[];
  final collection = <bool>[];
  var resets = 0;
  (bool, bool)? consent;
  var fail = false;

  @override
  bool get available => true;

  @override
  Future<void> logEvent(String name, Map<String, Object> params) async {
    if (fail) throw StateError('sem rede');
    events.add((name, params));
  }

  @override
  Future<void> setUserProperty(String name, String? value) async =>
      properties.add((name, value));

  @override
  Future<void> setCollectionEnabled(bool enabled) async =>
      collection.add(enabled);

  @override
  Future<void> resetData() async => resets++;

  @override
  Future<void> setConsent({required bool analytics, required bool ads}) async =>
      consent = (analytics, ads);

  List<String> get names => [for (final (name, _) in events) name];
}

void main() {
  late _FakeService service;
  late PreferencesService preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    service = _FakeService();
    preferences = PreferencesService();
  });

  ServiceAnalyticsRepository repository({
    AnalyticsMode mode = AnalyticsMode.normal,
  }) => ServiceAnalyticsRepository(service, preferences, mode: mode);

  final event = AnalyticsEvents.aulaConcluida(
    aulaId: 'lucena',
    tipoAula: 'final',
  );

  test('ligada por padrão: o evento sai e a coleta liga na abertura', () async {
    final analytics = repository();
    await analytics.start();
    await analytics.log(event);

    expect(await analytics.enabled(), isTrue);
    expect(service.collection, [true]);
    expect(service.names, ['aula_concluida']);
    expect(service.events.single.$2.containsKey('traffic_type'), isFalse);
  });

  test('desligar manda o último aviso e depois nada sai', () async {
    final analytics = repository();
    await analytics.start();
    await analytics.setEnabled(false);
    await analytics.log(event);
    await analytics.setTrait(AnalyticsTrait.goal, 'finais');

    expect(service.names, ['privacidade_analytics']);
    expect(service.events.single.$2['ligado'], 'nao');
    expect(service.collection.last, isFalse);
    expect(service.resets, 1);
    expect(service.properties, isEmpty);
    // Fica salvo para a próxima abertura.
    expect(await repository().enabled(), isFalse);
  });

  test('religar liga a coleta e conta o ligado', () async {
    final analytics = repository();
    await analytics.setEnabled(false);
    await analytics.setEnabled(true);
    await analytics.log(event);

    expect(service.names, [
      'privacidade_analytics',
      'privacidade_analytics',
      'aula_concluida',
    ]);
    expect(service.events[1].$2['ligado'], 'sim');
  });

  test('o Modo equipe desliga a coleta e zera os dados uma vez', () async {
    final analytics = repository();
    await analytics.start();
    await analytics.setTeamMode(true);
    await analytics.setTeamMode(true);
    await analytics.log(event);

    expect(await analytics.teamMode(), isTrue);
    expect(service.resets, 1);
    expect(service.collection.last, isFalse);
    expect(service.events, isEmpty);

    await analytics.setTeamMode(false);
    await analytics.log(event);
    expect(service.collection.last, isTrue);
    expect(service.names, ['aula_concluida']);
  });

  test('a QA sai com traffic_type=internal', () async {
    final analytics = repository(mode: AnalyticsMode.internal);
    await analytics.log(event);
    expect(service.events.single.$2['traffic_type'], 'internal');
  });

  test('o build que não mede não manda nada', () async {
    final analytics = repository(mode: AnalyticsMode.off);
    await analytics.start();
    await analytics.log(event);
    expect(analytics.measures, isFalse);
    expect(service.collection, [false]);
    expect(service.events, isEmpty);
  });

  test(
    'a propriedade só vai quando o valor muda, mesmo noutra abertura',
    () async {
      final analytics = repository();
      await analytics.setTrait(AnalyticsTrait.goal, 'finais');
      await analytics.setTrait(AnalyticsTrait.goal, 'finais');
      await repository().setTrait(AnalyticsTrait.goal, 'finais');
      await analytics.setTrait(AnalyticsTrait.goal, 'aberturas');

      expect(service.properties, [
        ('objetivo', 'finais'),
        ('objetivo', 'aberturas'),
      ]);
    },
  );

  test('a origem da 1ª abertura é gravada uma vez', () async {
    final analytics = repository();
    expect(
      await analytics.recordOrigin(
        first: 'link',
        source: 'instagram',
        campaign: 'lancamento',
      ),
      isTrue,
    );
    expect(await repository().recordOrigin(first: 'direto'), isFalse);

    expect(service.properties, [
      ('origem_primeira', 'link'),
      ('origem_fonte', 'instagram'),
      ('origem_campanha', 'lancamento'),
      ('origem_post', 'nenhum'),
      ('origem_link', 'nenhum'),
    ]);
  });

  test('a origem gravada é a do feedback', () async {
    expect(await repository().origin(), isNull);
    await repository().recordOrigin(first: 'organico');
    expect(await repository().origin(), 'organico');
  });

  test('o último link fica guardado entre aberturas', () async {
    expect(await repository().lastLink(), isNull);
    await repository().rememberLink(
      const LinkTrail(code: 'k7Qe2', generation: 2),
    );
    final trail = await repository().lastLink();
    expect(trail?.code, 'k7Qe2');
    expect(LinkTrail.next(trail), 3);
    expect(LinkTrail.next(null), 1);
  });

  test('erro do Firebase não derruba a tela', () async {
    service.fail = true;
    await expectLater(repository().log(event), completes);
  });

  test('o screen_view leva só o nome da rota', () async {
    await repository().screen('/featured/:id');
    expect(service.names, ['screen_view']);
    expect(service.events.single.$2.values, isNot(contains('42')));
  });

  test('o consentimento vai para o Consent Mode', () async {
    await repository().setConsent(analytics: true, ads: false);
    expect(service.consent, (true, false));
  });
}
