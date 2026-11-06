import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/motion/lucena_motion.dart';
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
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/goal_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/purchase_keys.dart';
import 'package:lucena/ui/core/theme/app_colors.dart';
import 'package:lucena/ui/core/theme/canvas_symbols.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/profile/widgets/profile_rows.dart';
import 'package:lucena/ui/profile/widgets/profile_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_account_repository.dart';
import '../../../../testing/fakes/fake_lichess_repository.dart';
import '../../../../testing/fakes/fake_link_repository.dart';
import '../../../../testing/fakes/fake_purchase_service.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_store_listing_repository.dart';
import '../../../../testing/fakes/fake_sync_repository.dart';
import '../../../../testing/test_app.dart';

const _offlineNote =
    'Sem internet, o que você faz fica no celular e é salvo na conta '
    'quando a conexão voltar.';

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
    FakeLinkRepository? links,
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
          path: Routes.settingsLanguage,
          builder: (_, state) => stub('rota-idioma'),
        ),
        GoRoute(
          path: Routes.alerts,
          builder: (_, state) => stub('rota-avisos'),
        ),
        GoRoute(
          path: Routes.feedback,
          builder: (_, state) => stub('rota-feedback'),
        ),
        GoRoute(
          path: D2Paths.pilaresOffer,
          builder: (_, state) => stub('rota-oferta ${state.uri}'),
        ),
        GoRoute(
          path: D2Paths.pilaresAbout,
          builder: (_, state) => stub('rota-sobre'),
        ),
        GoRoute(
          path: D2Paths.pilaresRestore,
          builder: (_, state) => stub('rota-restaurar'),
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
        linkRepository: links,
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
    // H-CON-15: o texto do quadro PropV1PerfilObjetivo.
    expect(
      find.descendant(
        of: find.byKey(GoalKeys.sheet),
        matching: find.text('Seu objetivo'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Muda o primeiro cartão do Início. Os outros caminhos continuam lá.',
      ),
      findsOneWidget,
    );
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

    Future<void> openSheet(WidgetTester tester) async {
      await pumpScreen(
        tester,
        profile: const UserProfile(lichessUser: 'ana_finais', rating: 1620),
      );
      await tester.tap(find.byKey(ProfileKeys.rowLichess));
      await tester.pumpAndSettle();
    }

    testWidgets('H-CON-17 1. usuário, data da leitura, três ratings e textos', (
      tester,
    ) async {
      lichess.rating = PlatformRating(
        user: 'gabriel_finais',
        readAt: DateTime(2026, 10, 20),
        bullet: const ModeRating(rating: 1588, games: 40),
        blitz: const ModeRating(rating: 1712, games: 40),
        rapid: const ModeRating(rating: 1805, games: 40),
      );
      await openSheet(tester);
      final sheet = find.byKey(ProfileKeys.lichessSheet);
      for (final text in [
        'Conectado pelo login do Lichess. Só lemos seu perfil e seus ratings.',
        'gabriel_finais',
        'lido em 20/10',
        '1588',
        '1712',
        '1805',
        'Atualizar o rating',
        'Desconectar',
        'Desconectar remove o acesso do Lucena ao seu Lichess. Seu rating no '
            'Lucena não muda.',
      ]) {
        expect(
          find.descendant(of: sheet, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
    });

    testWidgets('gap 5: desconectar falhando avisa e a folha continua', (
      tester,
    ) async {
      await openSheet(tester);
      lichess.disconnectError = StateError('falhou');
      await tester.tap(find.byKey(ProfileKeys.lichessDisconnect));
      await tester.pumpAndSettle();
      // O aviso vem dentro da folha (o SnackBar ficaria atrás dela).
      expect(
        find.descendant(
          of: find.byKey(ProfileKeys.lichessNotice),
          matching: find.text('Ocorreu um erro inesperado'),
        ),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byKey(ProfileKeys.lichessSheet), findsOneWidget);
      expect(lichess.connected, isTrue);
      expect(profiles.profile.lichessUser, 'ana_finais');
    });

    testWidgets('3. sem rede, atualizar avisa e o rating antigo continua', (
      tester,
    ) async {
      await openSheet(tester);
      lichess.failure = LichessFailure.network;
      await tester.tap(find.byKey(ProfileKeys.lichessRefresh));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(ProfileKeys.lichessNotice),
          matching: find.text('Sem internet. O rating continua o de antes.'),
        ),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(ProfileKeys.lichessSheet),
          matching: find.text('1620'),
        ),
        findsOneWidget,
      );
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
      expect(find.text('Salvo agora'), findsOneWidget);
      // Abrir o Perfil com conta sobe o que estiver pendente.
      expect(sync.synced, contains('google-uid'));
    });

    testWidgets('S4: com rede, salvando e depois "Salvo agora"', (
      tester,
    ) async {
      final gate = sync.gate = Completer<void>();
      await pumpScreen(tester);
      expect(find.text('Salvando…'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.text(_offlineNote), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Salvo agora'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.text('Salvando…'), findsNothing);
      expect(find.text('Ainda não salvo'), findsNothing);
      expect(find.text(_offlineNote), findsNothing);
    });

    testWidgets('S4: sem rede, diz o que acontece e mantém a última vez', (
      tester,
    ) async {
      sync.offline = true;
      sync.at = DateTime(2026, 10, 22, 9, 5);
      await pumpScreen(tester);
      expect(find.text('Salvo hoje, 09:05'), findsOneWidget);
      expect(find.text(_offlineNote), findsOneWidget);
      expect(find.text('Salvo agora'), findsNothing);
    });

    testWidgets('H-CON-13: sem rede e nunca salvo diz "ainda não"', (
      tester,
    ) async {
      sync.offline = true;
      await pumpScreen(tester);
      expect(find.text('Ainda não salvo'), findsOneWidget);
      // Critério 4: o cartão diz o que acontece sem internet.
      expect(find.text(_offlineNote), findsOneWidget);
    });

    testWidgets('H-CON-13: sincronizou noutro dia mostra a data', (
      tester,
    ) async {
      sync.offline = true;
      sync.at = DateTime(2026, 10, 20, 21, 40);
      await pumpScreen(tester);
      expect(find.text('Salvo em 20/10'), findsOneWidget);
    });

    testWidgets('H-CON-13 gap 5: sair falhando avisa e a conta fica', (
      tester,
    ) async {
      accounts.signOutError = Exception('falhou');
      await pumpScreen(tester);
      await tester.scrollUntilVisible(find.byKey(ProfileKeys.signOut), 200);
      await tester.tap(find.byKey(ProfileKeys.signOut));
      await tester.pumpAndSettle();

      expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
      expect(accounts.current, isNotNull);
      expect(find.byKey(ProfileKeys.syncCard), findsOneWidget);
      expect(find.byKey(ProfileKeys.signOut), findsOneWidget);
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
      // A folha fecha em LucenaMotion.folha (400 ms) e sai no quadro seguinte.
      await tester.pump(LucenaMotion.folha);
      await tester.pump(const Duration(milliseconds: 16));

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

  testWidgets('PropV1PerfilSemConta: um grupo de linhas e um de avisos', (
    tester,
  ) async {
    await pumpScreen(tester);
    final order = [
      ProfileKeys.rowCountry,
      ProfileKeys.rowRegion,
      ProfileKeys.rowLanguage,
      ProfileKeys.rowGoal,
      ProfileKeys.rowLevel,
      ProfileKeys.rowLichess,
      ProfileKeys.rowNotices,
    ].map((key) => tester.getTopLeft(find.byKey(key)).dy).toList();
    for (var i = 1; i < order.length; i++) {
      expect(order[i], greaterThan(order[i - 1]), reason: 'linha $i');
    }
    // Sem títulos de seção e sem o botão do histórico do rating (o rating
    // abre pela Home e por Todos os modos).
    expect(find.text('Seu xadrez'), findsNothing);
    expect(find.text('Região'), findsNothing);
    expect(find.text('Histórico do rating'), findsNothing);
    expect(inRow(ProfileKeys.rowLanguage, 'Idioma'), findsOneWidget);
    expect(inRow(ProfileKeys.rowNotices, 'Notificações'), findsOneWidget);
  });

  // O canvas desenha as linhas com Material Symbols Rounded contornados
  // (CompOpcaoLista, FILL 0): o app usa a mesma fonte.
  testWidgets('as linhas do Perfil têm os ícones do canvas', (tester) async {
    await pumpScreen(tester);
    final icons = {
      ProfileKeys.rowCountry: CanvasSymbols.public,
      ProfileKeys.rowRegion: CanvasSymbols.locationOn,
      ProfileKeys.rowLanguage: CanvasSymbols.language,
      ProfileKeys.rowGoal: CanvasSymbols.flag,
      ProfileKeys.rowLevel: CanvasSymbols.showChart,
      ProfileKeys.rowLichess: CanvasSymbols.link,
      ProfileKeys.rowNotices: CanvasSymbols.notifications,
    };
    for (final MapEntry(:key, :value) in icons.entries) {
      expect(
        find.descendant(of: find.byKey(key), matching: find.byIcon(value)),
        findsOneWidget,
        reason: '$key',
      );
    }
  });

  // O canvas contorna os cartões e os grupos com 1 px de #E1E5DF.
  testWidgets('os grupos e o cartão do Perfil têm o contorno do canvas', (
    tester,
  ) async {
    await pumpScreen(tester);
    final grupo = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(ProfileRowGroup).first,
            matching: find.byType(Material),
          )
          .first,
    );
    expect(
      (grupo.shape! as RoundedRectangleBorder).side,
      const BorderSide(color: AppColors.cardOutline),
    );
    final cartao = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(ProfileKeys.localCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (cartao.decoration as BoxDecoration).border,
      Border.all(color: AppColors.cardOutline),
    );
  });

  // CompOpcaoLista: linha com subtítulo tem 72 px de altura mínima.
  testWidgets('a linha com valor tem a altura do canvas', (tester) async {
    await pumpScreen(tester);
    expect(tester.getSize(find.byKey(ProfileKeys.rowLanguage)).height, 72);
  });

  testWidgets('Idioma e Notificações abrem as telas dos Ajustes', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(ProfileKeys.rowLanguage));
    await tester.pumpAndSettle();
    expect(find.text('rota-idioma'), findsOneWidget);
    GoRouter.of(tester.element(find.text('rota-idioma'))).pop();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byKey(ProfileKeys.rowNotices), 200);
    await tester.tap(find.byKey(ProfileKeys.rowNotices));
    await tester.pumpAndSettle();
    expect(find.text('rota-avisos'), findsOneWidget);
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
    await tester.scrollUntilVisible(find.byKey(ProfileKeys.rowNotices), 200);
    for (final text in [
      'Privacidade e anúncios',
      'Enviar feedback',
      'Avaliar o Lucena',
      'Remover anúncios',
    ]) {
      expect(find.text(text), findsNothing, reason: text);
    }
  });

  group('cartão do curso (H-VEN-04/09)', () {
    FakePurchaseRepository store(PilaresAccess access) =>
        FakePurchaseRepository(
          PurchaseState(
            access: access,
            pricesReady: true,
            prices: const {PilaresPlan.monthly: r'R$ 19,90'},
          ),
        );

    Finder inCard(String text) => find.descendant(
      of: find.byKey(PurchaseKeys.courseCard),
      matching: find.text(text),
    );

    testWidgets('04-1: demo vê o selo e "Ver o curso completo" abre a '
        'oferta', (tester) async {
      await pumpScreen(tester, purchases: store(const PilaresAccess()));
      expect(inCard('Pilares do Xadrez'), findsOneWidget);
      expect(inCard('Demonstração'), findsOneWidget);
      expect(
        inCard(
          'Na demonstração você faz o Capítulo 1. O curso completo tem 20 capítulos.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(PurchaseKeys.courseSeeFull));
      await tester.pumpAndSettle();
      expect(find.textContaining('rota-oferta /pilares/offer'), findsOneWidget);
    });

    testWidgets('09-1: vitalício com a data e "Acesso vitalício"; 04-5: sem '
        '"Ver o curso completo"', (tester) async {
      await pumpScreen(
        tester,
        purchases: store(
          PilaresAccess(
            kind: PilaresAccessKind.lifetime,
            since: DateTime(2026, 11, 2),
          ),
        ),
      );
      expect(inCard('Vitalício'), findsOneWidget);
      expect(
        inCard('Comprado em 2 de novembro de 2026, pela Google Play'),
        findsOneWidget,
      );
      expect(inCard('Acesso vitalício'), findsOneWidget);
      expect(find.byKey(PurchaseKeys.courseSeeFull), findsNothing);
      expect(find.byKey(PurchaseKeys.courseManage), findsNothing);
      expect(find.byKey(PurchaseKeys.courseRestore), findsOneWidget);
    });

    testWidgets('09-2: mensal com a renovação e "Gerenciar na Google Play"', (
      tester,
    ) async {
      final links = FakeLinkRepository();
      await pumpScreen(
        tester,
        links: links,
        purchases: store(
          PilaresAccess(
            kind: PilaresAccessKind.monthlyActive,
            since: DateTime(2026, 11, 2),
            renewsAt: DateTime(2026, 12, 2),
          ),
        ),
      );
      expect(inCard('Mensal'), findsOneWidget);
      expect(
        inCard('Assinado em 2 de novembro de 2026, pela Google Play'),
        findsOneWidget,
      );
      expect(
        inCard(r'Mensal · R$ 19,90/mês · renova em 2 de dezembro de 2026'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(PurchaseKeys.courseManage));
      await tester.pumpAndSettle();
      expect(links.opened.single.host, 'play.google.com');
    });

    testWidgets('09-3: pagamento pendente com o aviso e o botão cheio', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        purchases: store(
          PilaresAccess(
            kind: PilaresAccessKind.monthlyGrace,
            since: DateTime(2026, 11, 2),
            renewsAt: DateTime(2026, 12, 2),
            graceUntil: DateTime(2026, 12, 9),
          ),
        ),
      );
      expect(
        find.text(
          'Regularize o pagamento até 9 de dezembro para manter o acesso ao '
          'curso.',
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(PurchaseKeys.courseGrace),
          matching: find.byIcon(Icons.credit_card_off),
        ),
        findsOneWidget,
      );
      expect(
        inCard(r'Mensal · R$ 19,90/mês · pagamento pendente'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(PurchaseKeys.courseFixPayment),
          matching: find.byType(FilledButton),
          matchRoot: true,
        ),
        findsOneWidget,
      );
      expect(find.byKey(PurchaseKeys.courseManage), findsNothing);
    });

    testWidgets('09-4: "Detalhes do curso" abre o Sobre o Pilares', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        purchases: store(const PilaresAccess(kind: PilaresAccessKind.lifetime)),
      );
      await tester.tap(find.byKey(PurchaseKeys.courseDetails));
      await tester.pumpAndSettle();
      expect(find.text('rota-sobre'), findsOneWidget);
    });

    testWidgets('09: "Restaurar compra" abre a restauração', (tester) async {
      await pumpScreen(
        tester,
        purchases: store(const PilaresAccess(kind: PilaresAccessKind.lifetime)),
      );
      await tester.ensureVisible(find.byKey(PurchaseKeys.courseRestore));
      await tester.tap(find.byKey(PurchaseKeys.courseRestore));
      await tester.pumpAndSettle();
      expect(find.text('rota-restaurar'), findsOneWidget);
    });

    testWidgets('09-5: a loja mudou o acesso, o cartão acompanha', (
      tester,
    ) async {
      final purchases = store(const PilaresAccess());
      await pumpScreen(tester, purchases: purchases);
      expect(inCard('Demonstração'), findsOneWidget);
      purchases.state = purchases.state.copyWith(
        access: PilaresAccess(
          kind: PilaresAccessKind.lifetime,
          since: DateTime(2026, 11, 2),
        ),
      );
      await tester.pumpAndSettle();
      expect(inCard('Vitalício'), findsOneWidget);
    });
  });
}
