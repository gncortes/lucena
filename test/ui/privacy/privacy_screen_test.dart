import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/profile/profile_repository.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/analytics_keys.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/keys/legal_keys.dart';
import 'package:lucena/ui/core/keys/privacy_keys.dart';
import 'package:lucena/ui/privacy/view_models/privacy_cubit.dart';
import 'package:lucena/ui/privacy/widgets/privacy_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_device_settings_repository.dart';
import '../../../testing/fakes/fake_link_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeDeviceSettingsRepository device;
  late FakeLinkRepository links;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    device = FakeDeviceSettingsRepository();
    links = FakeLinkRepository();
  });

  group('H-CON-20 · Privacidade e dados', () {
    Future<PrivacyCubit> pumpScreen(
      WidgetTester tester, {
      AccountRepository? accounts,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      final repository =
          accounts ??
          FakeAccountRepository(account: FakeAccountRepository.google);
      final cubit = PrivacyCubit(accounts: repository, device: device);
      addTearDown(cubit.close);
      await tester.runAsync(cubit.load);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt', 'BR'),
          analytics: FakeAnalyticsRepository(),
          linkRepository: links,
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AccountRepository>.value(value: repository),
              RepositoryProvider<ProfileRepository>.value(
                value: FakeProfileRepository(),
              ),
            ],
            child: BlocProvider.value(
              value: cubit,
              child: const PrivacyScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return cubit;
    }

    Future<void> tapRow(WidgetTester tester, Key key) async {
      await tester.scrollUntilVisible(find.byKey(key), 200);
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }

    testWidgets('título, cartão LGPD e as linhas na ordem do quadro', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.text('Privacidade e dados'), findsOneWidget);
      expect(find.byKey(PrivacyKeys.lgpdCard), findsOneWidget);
      expect(find.text('Seus dados pela LGPD'), findsOneWidget);
      expect(
        find.text(
          'Envia dados de uso e relatórios de erro. Sem nome, e-mail nem o '
          'que você escreve.',
        ),
        findsOneWidget,
      );

      final rows = [
        PrivacyKeys.lgpdCard,
        AnalyticsKeys.optInSwitch,
        PrivacyKeys.ads,
        PrivacyKeys.notifications,
        PrivacyKeys.microphone,
        PrivacyKeys.download,
        PrivacyKeys.talk,
        PrivacyKeys.terms,
        PrivacyKeys.policy,
        PrivacyKeys.deleteAccount,
      ];
      // Tela alta: todas as linhas desenhadas ao mesmo tempo.
      tester.view.physicalSize = const Size(1080, 9000);
      await tester.pumpAndSettle();
      final tops = [
        for (final key in rows) tester.getTopLeft(find.byKey(key)).dy,
      ];
      expect(tops, [...tops]..sort());
      expect(tops.toSet().length, rows.length);
      expect(find.text('Excluir minha conta'), findsOneWidget);
      for (final section in [
        'Uso e anúncios',
        'Permissões do aparelho',
        'Seus dados',
        'Documentos',
        'Conta',
      ]) {
        expect(find.text(section), findsOneWidget, reason: section);
      }
    });

    testWidgets('H-CON-24: sem "Escolhas de anúncios" nem "O Lucena é '
        'grátis"; a linha de anúncios não tem toque', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Escolhas de anúncios'), findsNothing);
      expect(find.text('O Lucena é grátis'), findsNothing);
      expect(find.text('Anúncios sem personalização'), findsOneWidget);
      final tile = tester.widget<ListTile>(
        find.descendant(
          of: find.byKey(PrivacyKeys.ads),
          matching: find.byType(ListTile),
        ),
      );
      expect(tile.onTap, isNull);
      expect(tile.trailing, isNull);
    });

    testWidgets('Notificações e Microfone abrem os ajustes do sistema', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tapRow(tester, PrivacyKeys.notifications);
      expect(device.notifications, 1);
      await tapRow(tester, PrivacyKeys.microphone);
      expect(device.appPermissions, 1);
    });

    testWidgets('"Falar sobre meus dados" abre o e-mail do encarregado', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tapRow(tester, PrivacyKeys.talk);
      expect(links.opened, [Uri.parse('mailto:gncortes.apps@gmail.com')]);
    });

    testWidgets('sem app de e-mail: aparece o aviso', (tester) async {
      links.fails = true;
      await pumpScreen(tester);
      await tapRow(tester, PrivacyKeys.talk);
      expect(find.byKey(CoreKeys.linkFailure), findsOneWidget);
    });

    testWidgets('Termos e Política abrem a folha com o texto', (tester) async {
      await pumpScreen(tester);
      await tapRow(tester, PrivacyKeys.terms);
      expect(find.byKey(LegalKeys.terms), findsOneWidget);
      await tester.tap(find.byKey(LegalKeys.close));
      await tester.pumpAndSettle();
      expect(find.byKey(PrivacyKeys.screen), findsOneWidget);

      await tapRow(tester, PrivacyKeys.policy);
      expect(find.byKey(LegalKeys.privacy), findsOneWidget);
      expect(links.opened, isEmpty);
    });

    testWidgets('sem conta: sem "Baixar meus dados" e sem "Excluir"', (
      tester,
    ) async {
      await pumpScreen(tester, accounts: FakeAccountRepository());
      await tester.scrollUntilVisible(find.byKey(PrivacyKeys.policy), 200);
      expect(find.byKey(PrivacyKeys.download), findsNothing);
      expect(find.byKey(PrivacyKeys.deleteAccount), findsNothing);
      expect(find.byKey(PrivacyKeys.talk), findsOneWidget);
    });

    testWidgets('a conta sai com a tela aberta: as linhas da conta somem', (
      tester,
    ) async {
      final accounts = FakeAccountRepository(
        account: FakeAccountRepository.google,
      );
      await pumpScreen(tester, accounts: accounts);
      await tester.scrollUntilVisible(
        find.byKey(PrivacyKeys.deleteAccount),
        200,
      );
      await tester.runAsync(accounts.signOut);
      await tester.pumpAndSettle();
      expect(find.byKey(PrivacyKeys.deleteAccount), findsNothing);
    });

    testWidgets('H-CON-14: "Excluir a conta" abre a mesma folha do Perfil', (
      tester,
    ) async {
      final accounts = FakeAccountRepository(
        account: FakeAccountRepository.google,
      );
      await pumpScreen(tester, accounts: accounts);
      await tapRow(tester, PrivacyKeys.deleteAccount);
      expect(find.byKey(PrivacyKeys.screen), findsOneWidget);
      expect(find.byKey(AccountKeys.deleteSheet), findsOneWidget);

      await tester.tap(find.byKey(AccountKeys.deleteConfirm));
      await tester.pumpAndSettle();
      expect(accounts.current, isNull);
      expect(find.byKey(AccountKeys.deleteSheet), findsNothing);
      // O cubit escuta a conta fora do relógio falso (carregado no runAsync).
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.byKey(PrivacyKeys.deleteAccount), findsNothing);
    });
  });
}
