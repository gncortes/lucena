import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/sync/sync_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/domain/models/account.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/progress_summary.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/account/widgets/account_data_screen.dart';
import 'package:lucena/ui/account/widgets/account_email_screen.dart';
import 'package:lucena/ui/account/widgets/account_restored_screen.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/test_app.dart';

/// "Continuar com e-mail", "Seus dados" e "Bem-vindo de volta" (E1.13).
void main() {
  late FakeAccountRepository accounts;
  late FakeSyncRepository sync;
  late FakeProfileRepository profiles;

  setUp(() {
    accounts = FakeAccountRepository();
    sync = FakeSyncRepository();
  });

  Future<void> pump(
    WidgetTester tester,
    String location, {
    UserProfile profile = const UserProfile(),
    Object? extra,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 1200);
    addTearDown(tester.view.reset);
    profiles = FakeProfileRepository(profile);
    final cubit = ProfileCubit(profiles);
    addTearDown(cubit.close);
    await cubit.load();
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings(languageCode: 'pt')),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final scheduler = SyncScheduler(accounts, sync);
    addTearDown(scheduler.dispose);
    String from(GoRouterState state) =>
        state.uri.queryParameters['from'] ?? 'tour';
    Widget stub(String text) => Scaffold(body: Text(text));
    final router = GoRouter(
      initialLocation: location,
      initialExtra: extra,
      routes: [
        GoRoute(path: Routes.home, builder: (_, _) => stub('rota-inicio')),
        GoRoute(
          path: Routes.accountEmail,
          builder: (_, state) => AccountEmailScreen(
            from: from(state),
            reauth: state.uri.queryParameters['reauth'] == '1',
          ),
        ),
        GoRoute(
          path: Routes.accountData,
          builder: (_, state) => AccountDataScreen(from: from(state)),
        ),
        GoRoute(
          path: Routes.accountRestored,
          builder: (_, state) => AccountRestoredScreen(
            result: state.extra! as SyncResult,
            from: from(state),
          ),
        ),
        GoRoute(path: Routes.goal, builder: (_, _) => stub('rota-objetivo')),
        GoRoute(
          path: Routes.settingsProfile,
          builder: (_, _) => stub('rota-perfil'),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AccountRepository>.value(value: accounts),
          RepositoryProvider<SyncScheduler>.value(value: scheduler),
        ],
        child: TestApp(
          router: router,
          profileCubit: cubit,
          settingsCubit: settings,
          locale: const Locale('pt', 'BR'),
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String email, String password) async {
    await tester.enterText(find.byKey(AccountKeys.emailField), email);
    await tester.enterText(find.byKey(AccountKeys.passwordField), password);
    await tester.tap(find.byKey(AccountKeys.emailSubmit));
    await tester.pumpAndSettle();
  }

  group('e-mail', () {
    testWidgets('criar a conta segue para "Seus dados"', (tester) async {
      await pump(tester, Routes.accountEmailFrom('tour'));
      await fill(tester, ' ana@example.com ', '12345678');

      expect(accounts.current?.email, 'ana@example.com');
      expect(find.byKey(AccountKeys.dataScreen), findsOneWidget);
    });

    testWidgets('senha curta avisa e não cria', (tester) async {
      await pump(tester, Routes.accountEmailFrom('tour'));
      await fill(tester, 'ana@example.com', '1234');

      expect(
        find.text('A senha precisa de pelo menos 8 caracteres.'),
        findsOneWidget,
      );
      expect(accounts.current, isNull);
      expect(find.byKey(AccountKeys.emailScreen), findsOneWidget);
    });

    testWidgets('entrar numa conta com progresso mostra "Bem-vindo de volta"', (
      tester,
    ) async {
      sync.remote = const ProgressSummary(
        profile: UserProfile(nickname: 'Ana', rating: 1500),
        challenges: {'a', 'b'},
      );
      await pump(tester, Routes.accountEmailFrom('profile'));
      await tester.tap(find.byKey(AccountKeys.emailHaveAccount));
      await tester.pump();
      await fill(tester, 'ana@example.com', 'segredo123');

      expect(find.byKey(AccountKeys.restoredScreen), findsOneWidget);
      expect(find.text('Bem-vindo de volta, Ana'), findsOneWidget);
      expect(find.text('2 desafios'), findsOneWidget);

      await tester.tap(find.byKey(AccountKeys.restoredContinue));
      await tester.pumpAndSettle();
      expect(find.text('rota-perfil'), findsOneWidget);
    });

    testWidgets('e-mail ou senha errados avisam e ficam na tela', (
      tester,
    ) async {
      accounts.failure = AccountFailure.wrongCredentials;
      await pump(tester, Routes.accountEmailFrom('tour'));
      await tester.tap(find.byKey(AccountKeys.emailSegSignIn));
      await tester.pump();
      await fill(tester, 'ana@example.com', 'errada123');

      expect(find.text('E-mail ou senha errados.'), findsOneWidget);
      expect(find.byKey(AccountKeys.emailScreen), findsOneWidget);
    });

    testWidgets('sem rede ao ler a conta segue direto', (tester) async {
      sync.offline = true;
      await pump(tester, Routes.accountEmailFrom('tour'));
      await tester.tap(find.byKey(AccountKeys.emailSegSignIn));
      await tester.pump();
      await fill(tester, 'ana@example.com', 'segredo123');

      expect(find.text('rota-objetivo'), findsOneWidget);
    });

    testWidgets('para apagar a conta, só entrar (sem criar)', (tester) async {
      await pump(tester, Routes.accountEmailFrom('profile', reauth: true));
      expect(find.byKey(AccountKeys.emailSegCreate), findsNothing);
      expect(find.byKey(AccountKeys.emailHaveAccount), findsNothing);
    });
  });

  group('Seus dados', () {
    testWidgets('sem apelido, vem o nome da conta', (tester) async {
      accounts.account = FakeAccountRepository.google;
      await pump(tester, Routes.accountDataFrom('tour'));

      expect(
        find.descendant(
          of: find.byKey(AccountKeys.nickname),
          matching: find.text('Teste'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('salvar grava apelido e cor, sobe e segue', (tester) async {
      accounts.account = FakeAccountRepository.google;
      await pump(tester, Routes.accountDataFrom('profile'));
      await tester.enterText(find.byKey(AccountKeys.nickname), 'Bia');
      await tester.tap(find.byKey(AccountKeys.avatar(2)));
      await tester.pump();
      await tester.tap(find.byKey(AccountKeys.dataSave));
      await tester.pumpAndSettle();

      expect(profiles.profile.nickname, 'Bia');
      expect(profiles.profile.avatarColor, 2);
      expect(accounts.names, ['Bia']);
      expect(sync.synced, contains('google-uid'));
      expect(find.text('rota-perfil'), findsOneWidget);
    });

    testWidgets('sem conta, salvar só grava no aparelho', (tester) async {
      await pump(tester, Routes.accountDataFrom('profile'));
      await tester.enterText(find.byKey(AccountKeys.nickname), 'Bia');
      await tester.tap(find.byKey(AccountKeys.dataSave));
      await tester.pumpAndSettle();

      expect(profiles.profile.nickname, 'Bia');
      expect(accounts.names, isEmpty);
      expect(sync.synced, isEmpty);
    });

    testWidgets('a foto do Google só aparece com foto na conta', (
      tester,
    ) async {
      accounts.account = FakeAccountRepository.google;
      await pump(tester, Routes.accountDataFrom('tour'));
      expect(find.byKey(AccountKeys.avatarGoogle), findsNothing);
    });
  });
}
