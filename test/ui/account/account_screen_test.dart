import 'dart:async';

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
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/theme/canvas_symbols.dart';

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
  Future<void> pumpAccount(
    WidgetTester tester, {
    String? from,
    Locale locale = const Locale('en'),
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
              RepositoryProvider<OnboardingRepository>.value(value: onboarding),
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
    await tester.pumpWidget(
      TestApp(router: router, locale: locale, child: const SizedBox()),
    );
    await tester.pumpAndSettle();
    if (from != null) {
      unawaited(router.push(Routes.accountEnterFrom(from)));
      await tester.pumpAndSettle();
    }
  }

  BuildContext top(WidgetTester tester) =>
      tester.element(find.byType(Scaffold).last);

  group('H-CON-04: o convite do link (PropV1LinkConta)', () {
    const lesson = '/aula/rook.lucena';

    testWidgets('1. "Quer salvar seu progresso?", os dois benefícios, as 4 '
        'ações e o X à esquerda', (tester) async {
      await pumpAccount(tester, from: lesson, locale: const Locale('pt'));
      expect(
        tester.widget<Text>(find.byKey(AccountKeys.enterTitle)).data,
        'Quer salvar seu progresso?',
      );
      expect(
        tester.widget<Text>(find.byKey(AccountKeys.enterText)).data,
        'Dá para criar a conta depois, no Perfil.',
      );
      expect(find.byIcon(Icons.cloud_sync), findsOneWidget);
      expect(
        find.text('Seu progresso fica salvo e aparece em qualquer celular'),
        findsOneWidget,
      );
      expect(
        find.text('O app funciona sem conta, só neste celular'),
        findsOneWidget,
      );
      expect(find.text('Criar conta com Google'), findsOneWidget);
      expect(find.text('Criar conta com e-mail'), findsOneWidget);
      expect(find.byKey(AccountKeys.toSignIn), findsOneWidget);
      expect(find.text('Agora não'), findsOneWidget);
      final close = tester.getRect(find.byKey(AccountKeys.close));
      expect(close.left, lessThan(56));
    });

    testWidgets('2. "Agora não" (sem o tour feito) vai à pergunta do '
        'objetivo, sem conta', (tester) async {
      onboarding.saved = const Onboarding();
      await pumpAccount(tester, from: lesson, locale: const Locale('pt'));
      await tester.tap(find.byKey(AccountKeys.later));
      await tester.pumpAndSettle();
      expect(find.text('rota-objetivo'), findsOneWidget);
      expect(accounts.current, isNull);
    });

    testWidgets('"Agora não" com o tour feito volta para quem abriu', (
      tester,
    ) async {
      await pumpAccount(tester, from: lesson, locale: const Locale('pt'));
      await tester.tap(find.byKey(AccountKeys.later));
      await tester.pumpAndSettle();
      expect(find.text('base'), findsOneWidget);
    });

    testWidgets('o X vale como "Agora não"', (tester) async {
      onboarding.saved = const Onboarding();
      await pumpAccount(tester, from: lesson, locale: const Locale('pt'));
      await tester.tap(find.byKey(AccountKeys.close));
      await tester.pumpAndSettle();
      expect(find.text('rota-objetivo'), findsOneWidget);
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

  group('H-CON-06: a Entrada (PropV1ContaEntrada)', () {
    testWidgets('1. "Salve seu progresso", os benefícios e os 3 botões', (
      tester,
    ) async {
      await pumpAccount(tester, locale: const Locale('pt'));
      for (final text in [
        'Salve seu progresso',
        'É de graça e leva menos de um minuto.',
        'Seu progresso fica salvo e aparece em qualquer celular',
        'O app funciona sem conta, só neste celular',
        'Criar conta com Google',
        'Criar conta com e-mail',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.byIcon(Icons.devices_other), findsNothing);
      expect(find.byKey(AccountKeys.toSignIn), findsOneWidget);
      // O aceite vem depois, na tela própria (H-CON-08): sem a nota legal.
      expect(find.textContaining('concorda', findRichText: true), findsNothing);
    });

    testWidgets('5. erro inesperado libera os botões e oferece '
        '"Tentar de novo" (gap 4)', (tester) async {
      accounts.failure = AccountFailure.unknown;
      await pumpAccount(tester, locale: const Locale('pt'));
      await tester.tap(find.byKey(AccountKeys.google));
      await tester.pumpAndSettle();
      expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
      expect(find.byKey(AccountKeys.failureRetry), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
      expect(
        tester
            .widget<ButtonStyleButton>(find.byKey(AccountKeys.google))
            .onPressed,
        isNotNull,
      );
      accounts.failure = null;
      await tester.tap(find.byKey(AccountKeys.failureRetry));
      await tester.pumpAndSettle();
      expect(accounts.current, FakeAccountRepository.google);
      expect(
        find.text('rota-dados /conta/dados?from=tour&novo=1'),
        findsOneWidget,
      );
    });
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

  group('H-CON-09: criar conta sem internet', () {
    testWidgets('1. Google sem rede abre a tela de erro padrão', (
      tester,
    ) async {
      accounts.failure = AccountFailure.network;
      await pumpAccount(tester);
      await tester.tap(find.byKey(AccountKeys.google));
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      expect(find.byIcon(CanvasSymbols.wifiOff), findsOneWidget);
      expect(
        find.text('You need an internet connection to create the account.'),
        findsOneWidget,
      );
      expect(find.byKey(LoadErrorKeys.action), findsOneWidget);
      expect(find.byKey(LoadErrorKeys.back), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('2. a rede volta: "Tentar novamente" abre o Google e segue', (
      tester,
    ) async {
      accounts.failure = AccountFailure.network;
      await pumpAccount(tester);
      await tester.tap(find.byKey(AccountKeys.google));
      await tester.pumpAndSettle();
      accounts.failure = null;
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pumpAndSettle();
      expect(accounts.current, FakeAccountRepository.google);
      expect(
        find.text('rota-dados /conta/dados?from=tour&novo=1'),
        findsOneWidget,
      );
    });

    testWidgets('outro erro na nova tentativa vira o erro genérico', (
      tester,
    ) async {
      accounts.failure = AccountFailure.network;
      await pumpAccount(tester);
      await tester.tap(find.byKey(AccountKeys.google));
      await tester.pumpAndSettle();
      accounts.failure = AccountFailure.unknown;
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      expect(find.text('An unexpected error occurred'), findsOneWidget);
    });

    testWidgets('3. "Voltar" volta à tela do convite', (tester) async {
      accounts.failure = AccountFailure.network;
      await pumpAccount(tester);
      await tester.tap(find.byKey(AccountKeys.google));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LoadErrorKeys.back));
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsNothing);
      expect(find.byKey(AccountKeys.enterScreen), findsOneWidget);
    });
  });

  for (final (failure, message) in [
    (AccountFailure.unknown, 'An unexpected error occurred'),
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

  testWidgets('e-mail abre Criar conta', (tester) async {
    await pumpAccount(tester);
    expect(find.text('Create account with email'), findsOneWidget);
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

  group('H-CON-05: a conta pedida na compra do Pilares', () {
    const offer = '/pilares/offer?plano=mensal';

    testWidgets('1. "Criar conta" na app bar, o porquê da conta e sem '
        '"Agora não"', (tester) async {
      await pumpAccount(tester, from: offer, locale: const Locale('pt'));
      expect(find.byKey(AccountKeys.purchaseScreen), findsOneWidget);
      final bar = tester.widget<AppBar>(find.byType(AppBar).last);
      expect(bar.bottom, isNull);
      expect(
        find.descendant(
          of: find.byType(AppBar).last,
          matching: find.text('Criar conta'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Crie sua conta para ver o Pilares do Xadrez'),
        findsOneWidget,
      );
      expect(find.text('Agora não'), findsNothing);
      expect(find.byKey(AccountKeys.purchaseBack), findsOneWidget);
    });

    testWidgets('2. voltar fecha a conta e volta para a oferta', (
      tester,
    ) async {
      await pumpAccount(tester, from: offer, locale: const Locale('pt'));
      await tester.tap(find.byKey(AccountKeys.purchaseBack));
      await tester.pumpAndSettle();
      expect(find.byKey(AccountKeys.purchaseScreen), findsNothing);
      expect(find.text('base'), findsOneWidget);
    });
  });
}
