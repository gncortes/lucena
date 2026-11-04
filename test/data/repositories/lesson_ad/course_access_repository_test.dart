import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/lesson_ad/course_access_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/domain/models/pilares_access.dart';

import '../../../../testing/fakes/fake_purchase_service.dart';

PurchaseState _state(PilaresAccessKind kind) =>
    PurchaseState(access: PilaresAccess(kind: kind));

void main() {
  test('H-LIC-06 a 15: o acesso da lição vem da compra do Pilares '
      '(H-VEN-16)', () {
    final purchases = FakePurchaseRepository();
    final access = PurchaseCourseAccessRepository(purchases);
    const expected = {
      PilaresAccessKind.demo: CourseAccess.demo,
      PilaresAccessKind.lifetime: CourseAccess.owned,
      PilaresAccessKind.monthlyActive: CourseAccess.owned,
      PilaresAccessKind.monthlyGrace: CourseAccess.owned,
      PilaresAccessKind.monthlyEnded: CourseAccess.subscriptionEnded,
    };
    for (final MapEntry(:key, :value) in expected.entries) {
      purchases.state = _state(key);
      expect(access.access, value, reason: '$key');
    }
  });

  test('a compra confirmada libera o curso sem reabrir a tela', () async {
    final purchases = FakePurchaseRepository();
    final access = PurchaseCourseAccessRepository(purchases);
    final next = access.changes.first;
    purchases.state = _state(PilaresAccessKind.lifetime);
    expect(await next, CourseAccess.owned);
  });

  test(
    'a mudança que não troca o acesso (preço, processando) não avisa',
    () async {
      final purchases = FakePurchaseRepository();
      final access = PurchaseCourseAccessRepository(purchases);
      final seen = <CourseAccess>[];
      final sub = access.changes.listen(seen.add);
      purchases.state = const PurchaseState(processing: true);
      purchases.state = _state(PilaresAccessKind.monthlyActive);
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [CourseAccess.owned]);
    },
  );
}
