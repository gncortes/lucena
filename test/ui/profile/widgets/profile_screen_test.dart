import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/lichess/lichess_repository.dart';
import 'package:lucena/data/repositories/profile/profile_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/domain/models/account.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/level_source.dart';
import 'package:lucena/domain/models/platform_rating.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/goal_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/profile/widgets/profile_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_account_repository.dart';
import '../../../../testing/fakes/fake_lichess_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_store_listing_repository.dart';
import '../../../../testing/fakes/fake_sync_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FakeProfileRepository profiles;
  late FakeAccountRepository accounts;
  late FakeSyncRepository sync;
  late FakeLichessRepository lichess;

  final now = DateTime(2026, 10, 22, 15);
  final lichessRating = PlatformRating(
    user: 'ana_finais',
    readAt: DateTime(2026, 10, 20),
    blitz: const ModeRating(rating: 1620, games: 40),
  );

  setUp(() {
    accounts = FakeAccountRepository();
    sync = FakeSyncRepository();
    lichess = FakeLichessRepository(rating: lichessRating);
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    UserProfile profile = const UserProfile(),
    PurchaseRepository? purchases,
    FakeStoreListingRepository? store,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 1400);
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
    Widget stub(String text) => Scaffold(body: Text(text));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AccountRepository>.value(value: accounts),
              RepositoryProvider<SyncScheduler>.value(value: scheduler),
              RepositoryProvider<LichessRepository>.value(value: lichess),
              RepositoryProvider<ProfileRepository>.value(value: profiles),
              RepositoryProvider<Now>.value(value: FakeNow(now)),
            ],
            child: const ProfileScreen(),
          ),
        ),
        GoRoute(
          path: Routes.accountEnter,
          builder: (_, state) => stub('rota-conta ${state.uri}'),
        ),
        GoRoute(
          path: Routes.accountData,
          builder: (_, state) => stub('rota-dados ${state.uri}'),
        ),
        GoRoute(
          path: Routes.level,
          builder: (_, state) => stub('rota-nivel ${state.uri}'),
        ),
        GoRoute(
          path: Routes.privacy,
          builder: (_, state) => stub('rota-privacidade'),
        ),
        GoRoute(
          path: Routes.feedback,
          builder: (_, state) => stub('rota-feedback'),
        ),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        router: router,
        profileCubit: cubit,
        settingsCubit: settings,
        locale: const Locale('pt', 'BR'),
        purchaseRepository: purchases,
        storeListingRepository: store,
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder inRow(Key row, String text) =>
      find.descendant(of: find.byKey(row), matching: find.text(text));

  group('sem conta', () {
    testWidgets('o cabeçalho diz "Sem conta" e o cartão chama para criar', (
      tester,
    ) async {
      await pumpScreen(tester, profile: const UserProfile(nickname: 'Ana'));

      expect(
        find.descendant(
          of: find.byKey(ProfileKeys.header),
          matching: find.text('Sem conta'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(ProfileKeys.headerName), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.byKey(ProfileKeys.localCard), findsOneWidget);
      expect(find.byKey(ProfileKeys.syncCard), findsNothing);
      expect(find.byKey(ProfileKeys.signOut), findsNothing);
      expect(find.byKey(ProfileKeys.delete), findsNothing);

      await tester.tap(find.byKey(ProfileKeys.createAccount));
      await tester.pumpAndSettle();
      expect(find.text('rota-conta /conta?from=profile'), findsOneWidget);
    });

    testWidgets('sem apelido, o nome é o padrão', (tester) async {
      await pumpScreen(tester);
      expect(
        tester.widget<Text>(find.byKey(ProfileKeys.headerName)).data,
        'Jogador',
      );
    });

    testWidgets('o lápis abre "Seus dados" vindo do Perfil', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(ProfileKeys.editData));
      await tester.pumpAndSettle();
      expect(find.text('rota-dados /conta/dados?from=profile'), findsOneWidget);
    });
  });

  testWidgets('as linhas mostram país, objetivo, nível e Lichess gravados', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      profile: const UserProfile(
        country: 'BR',
        rating: 1450,
        levelSource: LevelSource.test,
      ),
    );

    expect(inRow(ProfileKeys.rowCountry, '🇧🇷 Brasil'), findsOneWidget);
    expect(inRow(ProfileKeys.rowGoal, 'Não escolhido'), findsOneWidget);
    expect(
      inRow(
        ProfileKeys.rowRegion,
        'Opcional · para ver torneios perto de você',
      ),
      findsOneWidget,
    );
    expect(inRow(ProfileKeys.rowLevel, '1450 · pelo teste'), findsOneWidget);
    expect(inRow(ProfileKeys.rowLichess, 'Não conectado'), findsOneWidget);
  });

  testWidgets('"Nível" abre "Seu nível" vindo do Perfil', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(ProfileKeys.rowLevel));
    await tester.pumpAndSettle();
    expect(find.text('rota-nivel /tour/nivel?from=profile'), findsOneWidget);
  });

  testWidgets('o objetivo: a folha troca e grava na hora', (tester) async {
    await pumpScreen(
      tester,
      profile: const UserProfile(nickname: 'Ana', goal: GoalPreference.learn),
    );
    expect(inRow(ProfileKeys.rowGoal, 'Aprender a jogar'), findsOneWidget);

    await tester.tap(find.byKey(ProfileKeys.rowGoal));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(GoalKeys.option(GoalPreference.train)));
    await tester.pump();
    await tester.tap(find.byKey(GoalKeys.sheetSave));
    await tester.pumpAndSettle();

    expect(find.byKey(GoalKeys.sheet), findsNothing);
    expect(profiles.profile.goal, GoalPreference.train);
    expect(profiles.profile.nickname, 'Ana');
  });

  group('Lichess conectado', () {
    setUp(() => lichess.connected = true);

    testWidgets('a linha mostra a conta e a folha os ratings', (tester) async {
      await pumpScreen(
        tester,
        profile: const UserProfile(lichessUser: 'ana_finais'),
      );
      expect(inRow(ProfileKeys.rowLichess, 'ana_finais'), findsOneWidget);

      await tester.tap(find.byKey(ProfileKeys.rowLichess));
      await tester.pumpAndSettle();
      expect(find.byKey(ProfileKeys.lichessSheet), findsOneWidget);
      expect(find.text('1620'), findsOneWidget);
    });

    testWidgets('desconectar fecha a folha e tira o vínculo', (tester) async {
      await pumpScreen(
        tester,
        profile: const UserProfile(lichessUser: 'ana_finais', rating: 1620),
      );
      await tester.tap(find.byKey(ProfileKeys.rowLichess));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ProfileKeys.lichessDisconnect));
      await tester.pumpAndSettle();

      expect(find.byKey(ProfileKeys.lichessSheet), findsNothing);
      expect(lichess.connected, isFalse);
      expect(profiles.profile.lichessUser, isNull);
      expect(profiles.profile.rating, 1620);
    });
  });

  group('com conta', () {
    setUp(() => accounts.account = FakeAccountRepository.google);

    testWidgets('o cabeçalho mostra o e-mail e o cartão a sincronização', (
      tester,
    ) async {
      sync.at = DateTime(2026, 10, 22, 9, 5);
      await pumpScreen(tester);

      expect(find.text('teste@example.com · Google'), findsOneWidget);
      expect(find.byKey(ProfileKeys.localCard), findsNothing);
      expect(find.byKey(ProfileKeys.syncCard), findsOneWidget);
      expect(find.text('Última sincronização: hoje, 09:05'), findsOneWidget);
      // Abrir o Perfil com conta sobe o que estiver pendente.
      expect(sync.synced, contains('google-uid'));
    });

    testWidgets('sair volta ao cartão sem conta', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(ProfileKeys.signOut));
      await tester.pumpAndSettle();

      expect(accounts.current, isNull);
      expect(find.byKey(ProfileKeys.localCard), findsOneWidget);
    });

    Future<void> openDelete(WidgetTester tester) async {
      await tester.scrollUntilVisible(find.byKey(ProfileKeys.delete), 200);
      await tester.tap(find.byKey(ProfileKeys.delete));
      await tester.pumpAndSettle();
    }

    testWidgets('caso 42: a folha diz o que se perde e avisa da assinatura', (
      tester,
    ) async {
      await pumpScreen(tester);
      await openDelete(tester);

      expect(find.byKey(AccountKeys.deleteSheet), findsOneWidget);
      expect(find.text('Excluir sua conta?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(AccountKeys.deleteLose),
          matching: find.byType(Icon),
        ),
        findsNWidgets(3),
      );
      for (final text in [
        'Progresso nas lições e na Jornada',
        'Rating, histórico de partidas e conquistas',
        'Perfil e foto',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(
        find.descendant(
          of: find.byKey(AccountKeys.deletePlayWarning),
          matching: find.textContaining('Google Play'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(AccountKeys.deleteNotice), findsNothing);
    });

    testWidgets('cancelar não apaga', (tester) async {
      await pumpScreen(tester);
      await openDelete(tester);
      await tester.tap(find.byKey(AccountKeys.deleteCancel));
      await tester.pumpAndSettle();

      expect(find.byKey(AccountKeys.deleteSheet), findsNothing);
      expect(accounts.deletedUids, isEmpty);
      expect(find.byKey(ProfileKeys.syncCard), findsOneWidget);
    });

    testWidgets('excluir confirmado fecha a folha e avisa', (tester) async {
      await pumpScreen(tester);
      await openDelete(tester);
      await tester.tap(find.byKey(AccountKeys.deleteConfirm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(AccountKeys.deleteSheet), findsNothing);
      expect(
        find.text('Conta excluída. Neste celular, tudo continua sem conta.'),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(accounts.current, isNull);
      expect(find.byKey(ProfileKeys.localCard), findsOneWidget);
    });

    testWidgets('Conta1 trocar de conta com a folha aberta não apaga B', (
      tester,
    ) async {
      await pumpScreen(tester);
      await openDelete(tester);
      await accounts.signInWithEmail('outra@example.com', 'password');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AccountKeys.deleteConfirm));
      await tester.pumpAndSettle();

      expect(accounts.deletedUids, isEmpty);
      expect(
        find.text('Essa não é a conta que você ia excluir. Nada foi excluído.'),
        findsOneWidget,
      );
      expect(
        find.text('Conta excluída. Neste celular, tudo continua sem conta.'),
        findsNothing,
      );
    });

    testWidgets('caso 48: sem internet a folha fica e diz que nada saiu', (
      tester,
    ) async {
      await pumpScreen(tester);
      accounts.failure = AccountFailure.network;
      await openDelete(tester);
      await tester.tap(find.byKey(AccountKeys.deleteConfirm));
      await tester.pumpAndSettle();

      expect(find.byKey(AccountKeys.deleteSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(AccountKeys.deleteNotice),
          matching: find.text(
            'Sem internet não dá para excluir a conta. Nada foi excluído.',
          ),
        ),
        findsOneWidget,
      );
      expect(accounts.current, FakeAccountRepository.google);
    });

    testWidgets('erro inesperado: Tentar de novo na própria folha', (
      tester,
    ) async {
      await pumpScreen(tester);
      accounts.failure = AccountFailure.unknown;
      await openDelete(tester);
      await tester.tap(find.byKey(AccountKeys.deleteConfirm));
      await tester.pumpAndSettle();

      expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
      accounts.failure = null;
      await tester.tap(find.byKey(AccountKeys.deleteConfirm));
      await tester.pumpAndSettle();
      expect(accounts.current, isNull);
    });
  });

  testWidgets('o rating de finais fica no histórico: só o botão para ele', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.byKey(ProfileKeys.ratingCard), findsOneWidget);
  });

  testWidgets('"Estado e cidade" mostra o nome do estado e a cidade', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      profile: const UserProfile(country: 'BR', state: 'PR', city: 'Curitiba'),
    );

    expect(inRow(ProfileKeys.rowRegion, 'Paraná · Curitiba'), findsOneWidget);
  });

  testWidgets('H-AJU-01: privacidade, feedback e avaliar saem do Perfil', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.scrollUntilVisible(find.byKey(ProfileKeys.ratingCard), 200);
    for (final text in [
      'Privacidade e anúncios',
      'Enviar feedback',
      'Avaliar o Lucena',
      'Remover anúncios',
    ]) {
      expect(find.text(text), findsNothing, reason: text);
    }
  });
}
