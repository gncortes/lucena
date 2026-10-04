import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/config/dependencies.dart';
import 'package:lucena/domain/use_cases/now.dart';

import '../../testing/e2e_dependencies.dart';
import '../../testing/fakes/fake_now.dart';

void main() {
  test('composição normal usa o relógio do sistema', () {
    const dependencies = Dependencies.normal();

    expect(dependencies.now, isA<SystemNow>());
  });

  test('composição E2E usa um relógio que só anda quando o teste manda', () {
    final dependencies = e2eDependencies();
    final now = dependencies.now as FakeNow;
    final inicio = now();

    expect(now(), inicio);

    now.advance(const Duration(seconds: 5));

    expect(dependencies.now().difference(inicio), const Duration(seconds: 5));
  });
}
