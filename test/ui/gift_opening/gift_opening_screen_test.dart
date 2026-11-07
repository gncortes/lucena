import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/gift_opening_keys.dart';
import 'package:lucena/ui/gift_opening/view_models/gift_opening_cubit.dart';
import 'package:lucena/ui/gift_opening/widgets/gift_opening_screen.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_course_grants.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  const gift = CourseGrants(
    courses: {'pilares': CourseGrant(origin: GrantOrigin.gift)},
  );

  Future<void> pump(
    WidgetTester tester, {
    required FakeAccountRepository accounts,
    required FakeCourseGrantsRepository grants,
    String? account,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final scheduler = SyncScheduler(accounts, FakeSyncRepository());
    addTearDown(scheduler.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('inicio')),
        ),
        GoRoute(
          path: D2Paths.pilaresGiftOpening,
          builder: (_, _) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AccountRepository>.value(value: accounts),
              RepositoryProvider<SyncScheduler>.value(value: scheduler),
            ],
            child: BlocProvider(
              create: (_) => GiftOpeningCubit(
                accounts: accounts,
                grants: grants,
                course: 'pilares',
                uid: 'google-uid',
                now: FakeNow(DateTime(2026, 11, 7)),
                timeout: const Duration(milliseconds: 50),
              )..start(),
              child: GiftOpeningScreen(course: 'pilares', account: account),
            ),
          ),
        ),
        GoRoute(
          path: D2Paths.pilaresGiftDone,
          builder: (_, _) => const Scaffold(body: Text('curso-liberado')),
        ),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        router: router,
        locale: const Locale('pt'),
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(
      router.push(D2Paths.giftOpening(course: 'pilares', uid: 'google-uid')),
    );
    await tester.pump();
  }

  testWidgets('abrindo e depois o Curso liberado no lugar', (tester) async {
    final grants = FakeCourseGrantsRepository();
    await pump(
      tester,
      accounts: FakeAccountRepository(account: FakeAccountRepository.google),
      grants: grants,
    );
    await tester.pump();
    expect(find.byKey(GiftOpeningKeys.opening), findsOneWidget);
    expect(find.text('Abrindo o seu presente…'), findsOneWidget);
    grants.current = gift;
    await tester.pumpAndSettle();
    expect(find.text('curso-liberado'), findsOneWidget);
    expect(find.byKey(GiftOpeningKeys.opening), findsNothing);
  });

  testWidgets('o acesso não chega: a falha com Tentar novamente', (
    tester,
  ) async {
    final grants = FakeCourseGrantsRepository();
    await pump(
      tester,
      accounts: FakeAccountRepository(account: FakeAccountRepository.google),
      grants: grants,
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(GiftOpeningKeys.failed), findsOneWidget);
    expect(
      find.text('Não foi possível abrir o presente agora.'),
      findsOneWidget,
    );
    grants.current = gift;
    await tester.tap(find.byKey(GiftOpeningKeys.retry));
    await tester.pumpAndSettle();
    expect(find.text('curso-liberado'), findsOneWidget);
  });

  testWidgets('sem conta: entrar, com o e-mail mascarado', (tester) async {
    await pump(
      tester,
      accounts: FakeAccountRepository(),
      grants: FakeCourseGrantsRepository(gift),
      account: 'ra***@gmail.com',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(GiftOpeningKeys.signIn), findsOneWidget);
    expect(find.text('Entre para ver o seu presente'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(GiftOpeningKeys.signInText)).data,
      'Você ganhou o Pilares do Xadrez. O presente está na conta '
      'ra***@gmail.com.',
    );
    await tester.tap(find.byKey(GiftOpeningKeys.google));
    await tester.pumpAndSettle();
    expect(find.text('curso-liberado'), findsOneWidget);
  });
}
