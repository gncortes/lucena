import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/config/remote_defaults.dart';
import 'package:lucena/data/repositories/config/remote_flags_repository.dart';
import 'package:lucena/data/services/firebase/remote_config_service.dart';

import '../../../../testing/fakes/fake_remote_config_service.dart';

void main() {
  test('sem Firebase, valem os padrões do remote_defaults.dart', () async {
    final flags = RemoteConfigFlagsRepository(NoRemoteConfigService());
    addTearDown(flags.dispose);

    // Antes de start também.
    expect(flags.adsEnabled, remoteDefaults[RemoteKeys.adsEnabled]);
    await flags.start();
    await flags.refresh();

    expect(flags.updateMinBuild, 0);
    expect(flags.updateRecommendedBuild, 0);
    expect(flags.adsEnabled, isTrue);
    expect(flags.adsFreeLessons, 2);
    expect(flags.adsMinGapSeconds, 180);
  });

  test('com o serviço falso, vale o valor buscado e avisa', () async {
    final service = FakeRemoteConfigService(
      fetched: {RemoteKeys.updateMinBuild: 120, RemoteKeys.adsEnabled: false},
    );
    final flags = RemoteConfigFlagsRepository(service);
    addTearDown(flags.dispose);
    final changes = <Set<String>>[];
    flags.changes.listen(changes.add);

    await flags.start();
    expect(flags.updateMinBuild, 0);
    await flags.refresh();
    await pumpEventQueue();

    expect(flags.updateMinBuild, 120);
    expect(flags.adsEnabled, isFalse);
    expect(flags.adsFreeLessons, 2);
    expect(changes, hasLength(1));
    expect(changes.single, contains(RemoteKeys.updateMinBuild));
  });

  test('sem rede, fica o padrão', () async {
    final service = FakeRemoteConfigService(
      fetched: {RemoteKeys.updateMinBuild: 120},
    )..failFetch = true;
    final flags = RemoteConfigFlagsRepository(service);
    addTearDown(flags.dispose);

    await flags.refresh();

    expect(flags.updateMinBuild, 0);
  });

  test('a mudança em tempo real chega pelo Stream', () async {
    final service = FakeRemoteConfigService();
    final flags = RemoteConfigFlagsRepository(service);
    addTearDown(flags.dispose);
    await flags.start();
    final next = flags.changes.first;

    service.update({RemoteKeys.updateRecommendedBuild: 130});

    expect(await next, {RemoteKeys.updateRecommendedBuild});
    expect(flags.updateRecommendedBuild, 130);
  });
}
