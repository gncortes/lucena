import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/crowd/crowd_repository.dart';
import 'package:lucena/domain/models/crowd_stat.dart';

import '../../../../testing/fakes/fake_cloud_store_service.dart';

void main() {
  late FakeCloudStoreService store;
  late CloudCrowdRepository crowd;

  setUp(() {
    store = FakeCloudStoreService();
    crowd = CloudCrowdRepository(store);
  });

  test('lê daily/{dia} e featured/{id}', () async {
    store.public['daily/2026-10-21'] = {'pct': 63, 'total': 4812};
    store.public['featured/carlsen-2024'] = {'pct': 41, 'total': 1284};

    expect(
      await crowd.daily('2026-10-21'),
      const CrowdStat(percent: 63, total: 4812),
    );
    expect(
      await crowd.featured('carlsen-2024'),
      const CrowdStat(percent: 41, total: 1284),
    );
    expect(await crowd.daily('2026-10-20'), isNull);
  });

  test('sem rede: sem número', () async {
    store.public['daily/2026-10-21'] = {'pct': 63, 'total': 4812};
    store.offline = true;

    expect(await crowd.daily('2026-10-21'), isNull);
  });
}
