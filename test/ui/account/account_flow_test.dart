import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/account/avatar_repository.dart';
import 'package:lucena/data/repositories/account/mail_app_repository.dart';
import 'package:lucena/data/repositories/photo/photo_repository.dart';
import 'package:lucena/data/repositories/sync/sync_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/domain/models/account.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/avatar_photo.dart';
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
import '../../../testing/fakes/fake_avatar_repository.dart';
import '../../../testing/fakes/fake_mail_app_repository.dart';
import '../../../testing/fakes/fake_photo_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/test_app.dart';

/// Criar conta, Entrar, "Esqueci a senha", "Seu perfil" e "Bem-vindo de
/// volta" (E1.13, refeitas na §2.12).
void main() {
  late FakeAccountRepository accounts;
  late FakeSyncRepository sync;
  late FakeProfileRepository profiles;
  late FakeAvatarRepository avatars;
  late FakePhotoRepository photos;
  late FakeMailAppRepository mail;

  setUp(() {
    accounts = FakeAccountRepository();
    sync = FakeSyncRepository();
    avatars = FakeAvatarRepository();
    photos = FakePhotoRepository();
    mail = FakeMailAppRepository();
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
            signIn: state.uri.queryParameters['entrar'] == '1',
            reauth: state.uri.queryParameters['reauth'] == '1',
          ),
        ),
        GoRoute(
          path: Routes.accountData,
          builder: (_, state) => AccountDataScreen(
            from: from(state),
            welcome: state.uri.queryParameters['novo'] == '1',
          ),
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
          RepositoryProvider<AvatarRepository>.value(value: avatars),
          RepositoryProvider<PhotoRepository>.value(value: photos),
          RepositoryProvider<MailAppRepository>.value(value: mail),
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

  group('Criar conta', () {
    testWidgets('criar a conta segue para "Seu perfil", com o aviso', (
      tester,
    ) async {
      await pump(tester, Routes.accountEmailFrom('tour'));
      expect(find.byKey(AccountKeys.legal), findsOneWidget);
      await fill(tester, ' ana@example.com ', '12345678');

      expect(accounts.current?.email, 'ana@example.com');
      expect(find.byKey(AccountKeys.dataScreen), findsOneWidget);
      expect(find.byKey(AccountKeys.savedBanner), findsOneWidget);
    });

    testWidgets('senha curta avisa e não cria', (tester) async {
      await pump(tester, Routes.accountEmailFrom('tour'));
      await fill(tester, 'ana@example.com', '1234');

      expect(
        find.text('A senha precisa de pelo menos 8 caracteres.'),
        findsOneWidget,
      );
      expect(accounts.current, isNull);
      expect(find.byKey(AccountKeys.createScreen), findsOneWidget);
    });

    testWidgets('o olho mostra e esconde a senha', (tester) async {
      await pump(tester, Routes.accountEmailFrom('tour'));
      bool hidden() => tester
          .widget<TextField>(find.byKey(AccountKeys.passwordField))
          .obscureText;

      expect(hidden(), isTrue);
      await tester.tap(find.byKey(AccountKeys.passwordEye));
      await tester.pump();
      expect(hidden(), isFalse);
      expect(find.byTooltip('Esconder a senha'), findsOneWidget);
    });

    testWidgets('"Já tem conta? Entrar" troca para Entrar', (tester) async {
      await pump(tester, Routes.accountEmailFrom('tour'));
      await tester.tap(find.byKey(AccountKeys.toSignIn));
      await tester.pumpAndSettle();

      expect(find.byKey(AccountKeys.signInScreen), findsOneWidget);
      expect(find.byKey(AccountKeys.createScreen), findsNothing);
      expect(find.byKey(AccountKeys.legal), findsNothing);
    });
  });

  group('Entrar', () {
    String signIn(String from) => Routes.accountEmailFrom(from, signIn: true);

    testWidgets('numa conta com progresso mostra "Bem-vindo de volta"', (
      tester,
    ) async {
      sync.remote = const ProgressSummary(
        profile: UserProfile(nickname: 'Ana', rating: 1500),
        challenges: {'a', 'b'},
      );
      await pump(tester, signIn('profile'));
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
      await pump(tester, signIn('tour'));
      await fill(tester, 'ana@example.com', 'errada123');

      expect(find.text('E-mail ou senha errados.'), findsOneWidget);
      expect(find.byKey(AccountKeys.signInScreen), findsOneWidget);
    });

    testWidgets('sem rede ao ler a conta segue direto', (tester) async {
      sync.offline = true;
      await pump(tester, signIn('tour'));
      await fill(tester, 'ana@example.com', 'segredo123');

      expect(find.text('rota-objetivo'), findsOneWidget);
    });

    testWidgets('"Não tem conta? Criar conta" troca para Criar conta', (
      tester,
    ) async {
      await pump(tester, signIn('tour'));
      await tester.tap(find.byKey(AccountKeys.toCreate));
      await tester.pumpAndSettle();

      expect(find.byKey(AccountKeys.createScreen), findsOneWidget);
    });

    testWidgets('para apagar a conta, só entrar (sem trocar)', (tester) async {
      await pump(tester, Routes.accountEmailFrom('profile', reauth: true));
      expect(find.byKey(AccountKeys.signInScreen), findsOneWidget);
      expect(find.byKey(AccountKeys.toCreate), findsNothing);
    });
  });

  group('Esqueci a senha', () {
    Future<void> openReset(WidgetTester tester) async {
      await pump(tester, Routes.accountEmailFrom('tour', signIn: true));
      await tester.enterText(
        find.byKey(AccountKeys.emailField),
        ' ana@example.com ',
      );
      await tester.tap(find.byKey(AccountKeys.forgotPassword));
      await tester.pumpAndSettle();
    }

    testWidgets('o e-mail vem do campo; mandar mostra "Confira o seu e-mail"', (
      tester,
    ) async {
      await openReset(tester);
      expect(find.byKey(AccountKeys.resetSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(AccountKeys.resetEmail),
          matching: find.text('ana@example.com'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(AccountKeys.resetSend));
      await tester.pumpAndSettle();

      expect(accounts.resets, ['ana@example.com']);
      expect(find.byKey(AccountKeys.resetSheet), findsNothing);
      expect(find.byKey(AccountKeys.resetSentSheet), findsOneWidget);
      expect(
        find.textContaining(
          'Se existir uma conta com ana@example.com',
          findRichText: true,
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(AccountKeys.resetOpenMail));
      await tester.pumpAndSettle();
      expect(mail.opened, 1);
      expect(find.byKey(AccountKeys.resetSentSheet), findsNothing);
    });

    testWidgets('e-mail sem conta tem a mesma resposta', (tester) async {
      accounts.failure = AccountFailure.wrongCredentials;
      await openReset(tester);
      await tester.tap(find.byKey(AccountKeys.resetSend));
      await tester.pumpAndSettle();

      expect(find.byKey(AccountKeys.resetSentSheet), findsOneWidget);
    });

    testWidgets('sem app de e-mail, só "Entendi"', (tester) async {
      mail.installed = false;
      await openReset(tester);
      await tester.tap(find.byKey(AccountKeys.resetSend));
      await tester.pumpAndSettle();

      expect(find.byKey(AccountKeys.resetOpenMail), findsNothing);
      await tester.tap(find.byKey(AccountKeys.resetOk));
      await tester.pumpAndSettle();
      expect(find.byKey(AccountKeys.resetSentSheet), findsNothing);
    });

    testWidgets('e-mail mal escrito avisa no campo e fica na folha', (
      tester,
    ) async {
      accounts.failure = AccountFailure.invalidEmail;
      await openReset(tester);
      await tester.tap(find.byKey(AccountKeys.resetSend));
      await tester.pumpAndSettle();

      expect(find.byKey(AccountKeys.resetSheet), findsOneWidget);
      expect(find.text('Confira o e-mail.'), findsOneWidget);
    });
  });

  group('Seu perfil', () {
    testWidgets('sem apelido, vem o nome da conta; sem aviso pelo lápis', (
      tester,
    ) async {
      accounts.account = FakeAccountRepository.google;
      await pump(tester, Routes.accountDataFrom('profile'));

      expect(
        find.descendant(
          of: find.byKey(AccountKeys.nickname),
          matching: find.text('Teste'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(AccountKeys.savedBanner), findsNothing);
    });

    testWidgets('salvar grava apelido e cor, sobe e segue', (tester) async {
      accounts.account = FakeAccountRepository.google;
      await pump(tester, Routes.accountDataFrom('profile'));
      await tester.enterText(find.byKey(AccountKeys.nickname), 'Bia');
      await tester.tap(find.byKey(AccountKeys.photo));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AccountKeys.avatar(2)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AccountKeys.dataSave));
      await tester.pumpAndSettle();

      expect(profiles.profile.nickname, 'Bia');
      expect(profiles.profile.avatarColor, 2);
      expect(profiles.profile.photo, AvatarPhoto.none);
      expect(accounts.names, ['Bia']);
      expect(sync.synced, contains('google-uid'));
      expect(find.text('rota-perfil'), findsOneWidget);
    });

    testWidgets('sem conta, só as iniciais; salvar só grava no aparelho', (
      tester,
    ) async {
      await pump(tester, Routes.accountDataFrom('profile'));
      await tester.tap(find.byKey(AccountKeys.photo));
      await tester.pumpAndSettle();
      expect(find.byKey(AccountKeys.photoCamera), findsNothing);
      expect(find.byKey(AccountKeys.photoGallery), findsNothing);
      expect(find.byKey(AccountKeys.photoGoogle), findsNothing);
      await tester.tap(find.byKey(AccountKeys.avatar(1)));
      await tester.pumpAndSettle();

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
      await tester.tap(find.byKey(AccountKeys.photo));
      await tester.pumpAndSettle();
      expect(find.byKey(AccountKeys.photoGoogle), findsNothing);
      expect(find.byKey(AccountKeys.photoGallery), findsOneWidget);
    });

    testWidgets('a foto da galeria sobe ao salvar', (tester) async {
      accounts.account = FakeAccountRepository.google;
      photos.photo = Uint8List.fromList([1, 2, 3]);
      await pump(tester, Routes.accountDataFrom('profile'));
      await tester.tap(find.byKey(AccountKeys.photo));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AccountKeys.photoGallery));
      await tester.pumpAndSettle();

      expect(photos.sources, [PhotoSource.gallery]);
      expect(avatars.photos, isEmpty);

      await tester.tap(find.byKey(AccountKeys.dataSave));
      await tester.pumpAndSettle();

      expect(avatars.photos['google-uid'], [1, 2, 3]);
      expect(profiles.profile.photo, AvatarPhoto.upload);
      expect(
        profiles.profile.photoUrl,
        'https://storage.test/users/google-uid/avatar.jpg',
      );
      expect(find.text('rota-perfil'), findsOneWidget);
    });

    testWidgets('sem rede, a foto não sobe: avisa e fica na tela', (
      tester,
    ) async {
      accounts.account = FakeAccountRepository.google;
      photos.photo = Uint8List.fromList([1, 2, 3]);
      avatars.offline = true;
      await pump(tester, Routes.accountDataFrom('profile'));
      await tester.tap(find.byKey(AccountKeys.photo));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AccountKeys.photoCamera));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AccountKeys.dataSave));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Não deu para enviar a foto. Confira a internet e tente de novo.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(AccountKeys.dataScreen), findsOneWidget);
      expect(profiles.saved, isEmpty);
    });

    testWidgets('remover a foto enviada apaga a do Storage', (tester) async {
      accounts.account = FakeAccountRepository.google;
      avatars.photos['google-uid'] = Uint8List.fromList([1]);
      await pump(
        tester,
        Routes.accountDataFrom('profile'),
        profile: const UserProfile(
          photo: AvatarPhoto.upload,
          photoUrl: 'https://storage.test/users/google-uid/avatar.jpg',
        ),
      );
      await tester.tap(find.byKey(AccountKeys.photo));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AccountKeys.photoRemove));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AccountKeys.dataSave));
      await tester.pumpAndSettle();

      expect(avatars.deleted, ['google-uid']);
      expect(profiles.profile.photo, AvatarPhoto.none);
      expect(profiles.profile.photoUrl, isNull);
    });
  });
}
