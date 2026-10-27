import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/onboarding/onboarding_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/domain/models/account.dart';
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

  /// [from] uma rota (a aula do link, T84): a conta abre por cima de uma
  /// tela de base, pelo `push`.
  Future<void> pumpAccount(WidgetTester tester, {String? from}) async {
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
            child: from == null
                ? const AccountScreen()
                : const Scaffold(body: Text('base')),
          ),
        ),
        GoRoute(
          path: Routes.accountEnter,
          builder: (_, state) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AccountRepository>.value(value: accounts),
              RepositoryProvider<SyncScheduler>.value(value: scheduler),
            ],
            child: AccountScreen(from: state.uri.queryParameters['from']!),
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
    if (from != null) {
      unawaited(router.push(Routes.accountEnterFrom(from)));
      await tester.pumpAndSettle();
    }
  }

  BuildContext top(WidgetTester tester) =>
      tester.element(find.byType(Scaffold).last);

  group('aberta de uma rota (a aula do link, T84)', () {
    const lesson = '/aula/rook.lucena';

    testWidgets('o título fala da aula e some o "sem conta, tudo continua"', (
      tester,
    ) async {
      await pumpAccount(tester, from: lesson);
      expect(
        find.text('Create your account to access the free lesson'),
        findsOneWidget,
      );
      expect(find.text('It takes less than a minute.'), findsOneWidget);
      expect(find.text('Save your progress'), findsNothing);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.byIcon(Icons.devices_other), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsNothing);
    });

    testWidgets('o e-mail toma o lugar da conta: voltar volta à base', (
      tester,
    ) async {
      await pumpAccount(tester, from: lesson);
      await tester.tap(find.byKey(AccountKeys.toSignIn));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'rota-email /conta/email?from=%2Faula%2Frook.lucena&entrar=1',
        ),
        findsOneWidget,
      );
      GoRouter.of(top(tester)).pop();
      await tester.pumpAndSettle();
      expect(find.text('base'), findsOneWidget);
    });

    testWidgets('Google: "Seu perfil" toma o lugar da conta', (tester) async {
      await pumpAccount(tester, from: lesson);
      await tester.tap(find.byKey(AccountKeys.google));
      await tester.pumpAndSettle();
      expect(
        find.text('rota-dados /conta/dados?from=%2Faula%2Frook.lucena&novo=1'),
        findsOneWidget,
      );
      GoRouter.of(top(tester)).pop();
      await tester.pumpAndSettle();
      expect(find.text('base'), findsOneWidget);
    });
  });

  testWidgets('mostra o título, o que se ganha e que é grátis, sem vender '
      'o "sem conta"', (tester) async {
    await pumpAccount(tester);
    expect(find.text('Save your progress'), findsOneWidget);
    expect(find.textContaining('free'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    expect(find.byIcon(Icons.devices_other), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsNothing);
    expect(find.textContaining('without an account'), findsNothing);
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
    expect(find.byKey(AccountKeys.enterScreen), findsOneWidget);
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
      expect(find.byKey(AccountKeys.enterScreen), findsOneWidget);
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

  testWidgets('fechar segue para o objetivo e não há "Agora não"', (
    tester,
  ) async {
    await pumpAccount(tester);
    expect(find.byKey(AccountKeys.later), findsNothing);
    await tester.tap(find.byKey(AccountKeys.close));
    await tester.pumpAndSettle();
    expect(find.text('rota-objetivo'), findsOneWidget);
  });
}
