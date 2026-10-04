import 'package:lucena/config/dependencies.dart';

import 'fakes/fake_now.dart';

/// Composição dos cenários Patrol e dos testes de widget: tudo falso e determinístico.
Dependencies e2eDependencies({FakeNow? now}) {
  return Dependencies(now: now ?? FakeNow(DateTime.utc(2026, 1, 1, 12)));
}
