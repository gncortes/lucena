import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/onboarding/onboarding_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/domain/models/account.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/account/widgets/account_screen.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeAccountRepository accounts;
  late FakeOnboardingRepository onboarding;

  setUp(() {
    accounts = FakeAccountRepository();
    onboarding = FakeOnboardingRepository();
  });

  Future<void> pumpAccount(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final scheduler = SyncScheduler(accounts, FakeSyncRepository());
    addTearDown(scheduler.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AccountRepository>.value(value: accounts),
              RepositoryProvider<OnboardingRepository>.value(value: onboarding),
              RepositoryProvider<SyncScheduler>.value(value: scheduler),
            ],
            child: const AccountScreen(),
          ),
        ),
        GoRoute(
          path: Routes.accountEmail,
          builder: (_, state) =>
              Scaffold(body: Text('rota-email ${state.uri}')),
        ),
        GoRoute(
          path: Routes.accountData,
          builder: (_, state) =>
              Scaffold(body: Text('rota-dados ${state.uri}')),
        ),
        GoRoute(
          path: Routes.goal,
          builder: (_, _) => const Scaffold(body: Text('rota-objetivo')),
        ),
      ],
    );
    await tester.pumpWidget(TestApp(router: router, child: const SizedBox()));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra o convite, o que se ganha e que é opcional', (
    tester,
  ) async {
    await pumpAccount(tester);
    expect(find.text('Want to keep your progress?'), findsOneWidget);
    expect(find.textContaining('optional'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    expect(find.byIcon(Icons.devices_other), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
  });

  testWidgets('entrar com o Google (conta vazia) segue para "Seu perfil"', (
    tester,
  ) async {
    await pumpAccount(tester);
    await tester.tap(find.byKey(AccountKeys.google));
    await tester.pumpAndSettle();
    expect(accounts.current, FakeAccountRepository.google);
    expect(
      find.text('rota-dados /conta/dados?from=tour&novo=1'),
      findsOneWidget,
    );
  });

  testWidgets('fechar a escolha do Google fica na tela, sem aviso', (
    tester,
  ) async {
    accounts.canceled = true;
    await pumpAccount(tester);
    await tester.tap(find.byKey(AccountKeys.google));
    await tester.pumpAndSettle();
    expect(find.byKey(AccountKeys.screen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  for (final (failure, message) in [
    (
      AccountFailure.network,
      'No internet. Try again when the connection is back.',
    ),
    (AccountFailure.unknown, 'Could not sign in now. Try again.'),
    (AccountFailure.unavailable, 'Signing in is coming soon.'),
  ]) {
    testWidgets('Google com falha ${failure.name} avisa e fica na tela', (
      tester,
    ) async {
      accounts.failure = failure;
      await pumpAccount(tester);
      await tester.tap(find.byKey(AccountKeys.google));
      await tester.pump();
      expect(find.text(message), findsOneWidget);
      expect(find.byKey(AccountKeys.screen), findsOneWidget);
    });
  }

  testWidgets('e-mail abre Criar conta; o link, Entrar; e os termos', (
    tester,
  ) async {
    await pumpAccount(tester);
    expect(find.text('Create account with email'), findsOneWidget);
    expect(find.byKey(AccountKeys.legal), findsOneWidget);
    await tester.tap(find.byKey(AccountKeys.email));
    await tester.pumpAndSettle();
    expect(find.text('rota-email /conta/email?from=tour'), findsOneWidget);
  });

  testWidgets('"Já tem conta? Entrar" abre Entrar', (tester) async {
    await pumpAccount(tester);
    await tester.tap(find.byKey(AccountKeys.toSignIn));
    await tester.pumpAndSettle();
    expect(
      find.text('rota-email /conta/email?from=tour&entrar=1'),
      findsOneWidget,
    );
  });

  for (final key in [AccountKeys.later, AccountKeys.close]) {
    testWidgets('${key.toString()} segue para o objetivo', (tester) async {
      await pumpAccount(tester);
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.text('rota-objetivo'), findsOneWidget);
    });
  }

  testWidgets('na primeira abertura, o app fechado aqui volta aqui', (
    tester,
  ) async {
    onboarding = FakeOnboardingRepository(const Onboarding());
    await pumpAccount(tester);
    expect(onboarding.saved.stage, OnboardingStage.account);
  });

  testWidgets('com a primeira abertura feita, não mexe nela', (tester) async {
    await pumpAccount(tester);
    expect(onboarding.saved.stage, OnboardingStage.tour);
  });
}
