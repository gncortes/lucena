import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/ui/gift_opening/view_models/gift_opening_cubit.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_course_grants.dart';
import '../../../testing/fakes/fake_now.dart';

void main() {
  final now = FakeNow(DateTime(2026, 11, 7));
  const gift = CourseGrants(
    courses: {'pilares': CourseGrant(origin: GrantOrigin.gift)},
  );
  const bought = CourseGrants(
    courses: {'pilares': CourseGrant(origin: GrantOrigin.paidOutside)},
  );

  GiftOpeningCubit cubit(
    FakeAccountRepository accounts,
    FakeCourseGrantsRepository grants, {
    String? uid = 'google-uid',
  }) => GiftOpeningCubit(
    accounts: accounts,
    grants: grants,
    course: 'pilares',
    uid: uid,
    now: now,
    timeout: const Duration(milliseconds: 50),
  );

  test('com o acesso já sincronizado: abre e marca como visto', () async {
    final grants = FakeCourseGrantsRepository(gift);
    final c = cubit(
      FakeAccountRepository(account: FakeAccountRepository.google),
      grants,
    );
    await c.start();
    expect(c.state.phase, GiftOpeningPhase.open);
    expect(c.state.gift, isTrue);
    expect(grants.seen, ['pilares']);
    await c.close();
  });

  test('espera o acesso chegar; compra de fora não é presente', () async {
    final grants = FakeCourseGrantsRepository();
    final c = cubit(
      FakeAccountRepository(account: FakeAccountRepository.google),
      grants,
    );
    final started = c.start();
    await Future<void>.delayed(Duration.zero);
    expect(c.state.phase, GiftOpeningPhase.opening);
    grants.current = bought;
    await started;
    expect(c.state.phase, GiftOpeningPhase.open);
    expect(c.state.gift, isFalse);
    await c.close();
  });

  test('o acesso não chega: falha; tentar de novo abre', () async {
    final grants = FakeCourseGrantsRepository();
    final c = cubit(
      FakeAccountRepository(account: FakeAccountRepository.google),
      grants,
    );
    await c.start();
    expect(c.state.phase, GiftOpeningPhase.failed);
    grants.current = gift;
    await c.retry();
    expect(c.state.phase, GiftOpeningPhase.open);
    await c.close();
  });

  test('sem conta: entrar; na conta do presente, abre', () async {
    final accounts = FakeAccountRepository();
    final c = cubit(accounts, FakeCourseGrantsRepository(gift));
    await c.start();
    expect(c.state.phase, GiftOpeningPhase.signIn);
    await pumpEventQueue();
    await accounts.signInWithGoogle();
    await pumpEventQueue();
    expect(c.state.phase, GiftOpeningPhase.open);
    await c.close();
  });

  test('entra em outra conta: o catálogo', () async {
    final accounts = FakeAccountRepository();
    final c = cubit(accounts, FakeCourseGrantsRepository(gift), uid: 'outro');
    await c.start();
    await pumpEventQueue();
    await accounts.signInWithEmail('a@b.com', 'x');
    await pumpEventQueue();
    expect(c.state.phase, GiftOpeningPhase.otherAccount);
    await c.close();
  });

  test('o push sem uid abre na conta que estiver', () async {
    final c = cubit(
      FakeAccountRepository(account: FakeAccountRepository.google),
      FakeCourseGrantsRepository(gift),
      uid: null,
    );
    await c.start();
    expect(c.state.phase, GiftOpeningPhase.open);
    await c.close();
  });
}
