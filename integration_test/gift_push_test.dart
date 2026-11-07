import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/push_alert.dart';
import 'package:lucena/ui/core/keys/course_unlocked_keys.dart';
import 'package:lucena/ui/core/keys/gift_opening_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_account_repository.dart';
import '../testing/fakes/fake_course_grants.dart';
import '../testing/fakes/fake_push_repository.dart';
import 'robots/app_robot.dart';

// O toque no push do presente (H-R5-63, roteiro R19): "Abrindo o seu
// presente…" até o acesso chegar e o Curso liberado no lugar, com o app
// fechado e em segundo plano; sem conta, entrar para ver o presente. O push
// é simulado (FakePushRepository), o acesso chega pelo FakeCourseGrants.
void main() {
  final gift = PushOpening(
    kind: PushKind.gift,
    course: 'pilares',
    uid: FakeAccountRepository.google.uid,
    account: 'ra***@gmail.com',
  );
  const granted = CourseGrants(
    courses: {'pilares': CourseGrant(origin: GrantOrigin.gift)},
  );

  Future<void> opensWhenGranted(
    PatrolIntegrationTester $,
    FakeCourseGrantsRepository grants,
  ) async {
    await $(GiftOpeningKeys.opening).waitUntilVisible();
    grants.current = granted;
    await $(CourseUnlockedKeys.screen).waitUntilVisible();
    expect($(GiftOpeningKeys.opening), findsNothing);
    expect(grants.seen, ['pilares']);
  }

  patrolTest('H-R5-63 push do presente com o app fechado', ($) async {
    final grants = FakeCourseGrantsRepository();
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      signedIn: true,
      push: FakePushRepository(allowed: true, initial: gift),
      courseGrants: grants,
    );
    await opensWhenGranted($, grants);
  });

  patrolTest('H-R5-63 push do presente com o app em segundo plano', ($) async {
    final grants = FakeCourseGrantsRepository();
    final push = FakePushRepository(allowed: true);
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      signedIn: true,
      push: push,
      courseGrants: grants,
    );
    await $.platform.mobile.pressHome();
    push.tap(gift);
    await $.platform.mobile.openApp();
    await $.pumpAndSettle();
    await opensWhenGranted($, grants);
    // O X do Curso liberado volta para onde a pessoa estava.
    await $(CourseUnlockedKeys.close).tap();
    expect($(CourseUnlockedKeys.screen), findsNothing);
  });

  patrolTest('H-R5-63 push do presente sem conta pede para entrar', ($) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      push: FakePushRepository(allowed: true, initial: gift),
      courseGrants: FakeCourseGrantsRepository(granted),
    );
    await $(GiftOpeningKeys.signIn).waitUntilVisible();
    expect(
      $.tester.widget<Text>(find.byKey(GiftOpeningKeys.signInText)).data,
      contains('ra***@gmail.com'),
    );
    await $(GiftOpeningKeys.google).tap();
    await $(CourseUnlockedKeys.screen).waitUntilVisible();
  });
}
