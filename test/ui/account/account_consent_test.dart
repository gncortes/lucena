import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/legal/legal_consent_repository.dart';
import 'package:lucena/data/repositories/onboarding/onboarding_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/routing/launch_location.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/account/widgets/account_consent_screen.dart';
import 'package:lucena/ui/account/widgets/account_screen.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/legal_keys.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_cloud_store_service.dart';
import '../../../testing/fakes/fake_legal_consent_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/test_app.dart';

/// H-CON-08: "Termos e privacidade" logo depois de criar a conta.
void main() {
  late FakeAccountRepository accounts;
  late FakeLegalConsentRepository consent;
  late FakeAnalyticsRepository analytics;

  setUp(() {
    accounts = FakeAccountRepository();
    consent = FakeLegalConsentRepository();
    analytics = FakeAnalyticsRepository();
  });

  /// A entrada da conta ([start] `enter`) ou o aceite direto.
  Future<GoRouter> pump(WidgetTester tester, {String? start}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final scheduler = SyncScheduler(accounts, FakeSyncRepository());
    addTearDown(scheduler.dispose);
    Widget withRepos(Widget child) => MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AccountRepository>.value(value: accounts),
        RepositoryProvider<OnboardingRepository>.value(
          value: FakeOnboardingRepository(),
        ),
        RepositoryProvider<SyncScheduler>.value(value: scheduler),
      ],
      child: child,
    );
    final router = GoRouter(
      initialLocation: start ?? Routes.accountEnterFrom('profile'),
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('rota-inicio')),
        ),
        GoRoute(
          path: Routes.accountEnter,
          builder: (_, state) => withRepos(
            AccountScreen(from: state.uri.queryParameters['from']!),
          ),
        ),
        GoRoute(
          path: Routes.accountConsent,
          builder: (_, state) => withRepos(
            AccountConsentScreen(
              from: state.uri.queryParameters['from']!,
              offline: state.uri.queryParameters['offline'] == '1',
            ),
          ),
        ),
        GoRoute(
          path: Routes.accountData,
          builder: (_, state) =>
              Scaffold(body: Text('rota-dados ${state.uri}')),
        ),
        GoRoute(
          path: Routes.settingsProfile,
          builder: (_, _) => const Scaffold(body: Text('rota-perfil')),
        ),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        router: router,
        locale: const Locale('pt'),
        legalConsentRepository: consent,
        analytics: analytics,
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> openConsent(WidgetTester tester) async {
    accounts.account = FakeAccountRepository.google;
    await pump(tester, start: Routes.accountConsentFrom('profile'));
  }

  bool continueEnabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(AccountKeys.acceptContinue),
              matching: find.byType(FilledButton),
              matchRoot: true,
            ),
          )
          .onPressed !=
      null;

  bool checked(WidgetTester tester) =>
      tester
          .widget<IconButton>(find.byKey(AccountKeys.acceptCheck))
          .isSelected ??
      false;

  group('depois de criar a conta', () {
    testWidgets(
      '1. Google abre "Termos e privacidade" com Continuar desligado',
      (tester) async {
        await pump(tester);
        await tester.tap(find.byKey(AccountKeys.google));
        await tester.pumpAndSettle();
        expect(find.byKey(AccountKeys.acceptScreen), findsOneWidget);
        expect(find.text('Termos e privacidade'), findsOneWidget);
        expect(continueEnabled(tester), isFalse);
        expect(consent.pendingUid, FakeAccountRepository.google.uid);
      },
    );

    testWidgets('5. quem já aceitou não vê o aceite de novo', (tester) async {
      consent.acceptedUids.add(FakeAccountRepository.google.uid);
      await pump(tester);
      await tester.tap(find.byKey(AccountKeys.google));
      await tester.pumpAndSettle();
      expect(find.byKey(AccountKeys.acceptScreen), findsNothing);
      expect(find.textContaining('rota-dados'), findsOneWidget);
    });
  });

  group('o aceite', () {
    testWidgets('mostra o que fica salvo, os direitos e o aviso de dados', (
      tester,
    ) async {
      await openConsent(tester);
      for (final text in [
        'O que fica salvo na conta',
        'Nome, e-mail e foto da conta',
        'Progresso nas lições, partidas, rating e conquistas',
        'Como você usa o app, para melhorar as lições',
        'Seus direitos pela LGPD',
        'Ver e baixar seus dados',
        'Corrigir seus dados',
        'Excluir a conta quando quiser',
        'Você encontra tudo isso em Configurações, Privacidade e dados.',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      // 4. A linha dos dados de uso é obrigatória.
      expect(
        find.text(
          'Usamos dados de uso e relatórios de erro para melhorar o Lucena. '
          'Você desliga quando quiser em Configurações, Privacidade e dados.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
      expect(
        find.textContaining(
          'Li e aceito os Termos de uso e a Política de '
          'privacidade',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('2. marcar liga Continuar, que grava e leva a "Seu perfil"', (
      tester,
    ) async {
      await openConsent(tester);
      await tester.tap(find.byKey(AccountKeys.acceptCheck));
      await tester.pumpAndSettle();
      expect(checked(tester), isTrue);
      expect(find.byIcon(Icons.check_box), findsOneWidget);
      expect(continueEnabled(tester), isTrue);
      // Desmarcar desliga de novo.
      await tester.tap(find.byKey(AccountKeys.acceptCheck));
      await tester.pumpAndSettle();
      expect(continueEnabled(tester), isFalse);
      await tester.tap(find.byKey(AccountKeys.acceptCheck));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AccountKeys.acceptContinue));
      await tester.pumpAndSettle();
      expect(
        find.text('rota-dados /conta/dados?from=profile&novo=1'),
        findsOneWidget,
      );
      expect(consent.acceptedUids, {FakeAccountRepository.google.uid});
      final events = analytics.eventsNamed('aceite_termos');
      expect(events, hasLength(1));
      expect(events.single.params, {'versao': LegalConsentRepository.version});
    });

    testWidgets(
      'sem rede: o aceite fica no aparelho e segue sem "Seu perfil"',
      (tester) async {
        accounts.account = FakeAccountRepository.google;
        await pump(
          tester,
          start: Routes.accountConsentFrom('profile', offline: true),
        );
        await tester.tap(find.byKey(AccountKeys.acceptCheck));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(AccountKeys.acceptContinue));
        await tester.pumpAndSettle();
        expect(find.text('rota-perfil'), findsOneWidget);
      },
    );

    testWidgets(
      '3. "Termos de uso" abre a folha; o X volta com a caixa igual',
      (tester) async {
        await openConsent(tester);
        await tester.tap(find.byKey(AccountKeys.acceptCheck));
        await tester.pumpAndSettle();
        await tester.tapOnText(find.textRange.ofSubstring('Termos de uso'));
        await tester.pumpAndSettle();
        expect(find.byKey(LegalKeys.sheet), findsOneWidget);
        await tester.tap(find.byKey(LegalKeys.close));
        await tester.pumpAndSettle();
        expect(find.byKey(LegalKeys.sheet), findsNothing);
        expect(find.byKey(AccountKeys.acceptScreen), findsOneWidget);
        expect(checked(tester), isTrue);
        await tester.tapOnText(
          find.textRange.ofSubstring('Política de privacidade'),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(LegalKeys.sheet), findsOneWidget);
      },
    );

    testWidgets('erro ao gravar: erro padrão e a caixa continua marcada', (
      tester,
    ) async {
      consent.failAccept = true;
      await openConsent(tester);
      await tester.tap(find.byKey(AccountKeys.acceptCheck));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AccountKeys.acceptContinue));
      await tester.pumpAndSettle();
      expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
      expect(find.byKey(AccountKeys.acceptScreen), findsOneWidget);
      expect(checked(tester), isTrue);
      expect(analytics.eventsNamed('aceite_termos'), isEmpty);
    });

    testWidgets('voltar sem aceitar volta à entrada da conta', (tester) async {
      await openConsent(tester);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(AccountKeys.acceptScreen), findsNothing);
      expect(find.byKey(AccountKeys.google), findsOneWidget);
    });
  });

  group('fechar à força antes de Continuar', () {
    test('a abertura volta ao aceite', () {
      expect(
        launchLocation(consentPending: true),
        Routes.accountConsentFrom('home'),
      );
      expect(launchLocation(), Routes.home);
      expect(Routes.afterAccount('home'), Routes.home);
    });
  });

  group('LocalLegalConsentRepository', () {
    late FakeCloudStoreService cloud;
    late LocalLegalConsentRepository repository;

    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      cloud = FakeCloudStoreService();
      repository = LocalLegalConsentRepository(
        PreferencesService(),
        cloud,
        now: FakeNow(DateTime.utc(2026, 11, 4, 9)),
      );
    });

    test(
      'pendente até aceitar; o aceite grava versão e data na conta',
      () async {
        expect(await repository.accepted('u1'), isFalse);
        await repository.markPending('u1');
        expect(await repository.pending(), 'u1');
        await repository.accept('u1');
        expect(await repository.accepted('u1'), isTrue);
        expect(await repository.pending(), isNull);
        expect(cloud.users['u1'], {
          'legal': {
            'acceptedVersion': LegalConsentRepository.version,
            'acceptedAt': '2026-11-04T09:00:00.000Z',
          },
        });
      },
    );

    test('sem rede o aceite fica no aparelho', () async {
      cloud.offline = true;
      await repository.accept('u1');
      expect(await repository.accepted('u1'), isTrue);
    });
  });
}
