import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/lichess/lichess_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/level_source.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/platform_rating.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';
import 'package:lucena/ui/level/widgets/level_chess_screen.dart';
import 'package:lucena/ui/level/widgets/level_lichess_screen.dart';
import 'package:lucena/ui/level/widgets/level_rating_screen.dart';
import 'package:lucena/ui/level/widgets/level_screen.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_chesscom_repository.dart';
import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_lichess_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';

final _readAt = DateTime(2026, 10, 22);

void main() {
  late FakeOnboardingRepository onboarding;
  late FakeProfileRepository profile;
  late FakeLichessRepository lichess;
  late FakeChessComRepository chessCom;

  setUp(() {
    onboarding = FakeOnboardingRepository(
      const Onboarding(inProgress: true, step: 4),
    );
    profile = FakeProfileRepository();
    lichess = FakeLichessRepository(
      rating: PlatformRating(
        user: 'gabriel_finais',
        readAt: _readAt,
        bullet: const ModeRating(rating: 1588, games: 312),
        blitz: const ModeRating(rating: 1712, games: 940),
        rapid: const ModeRating(rating: 1805, games: 121),
      ),
    );
    chessCom = FakeChessComRepository(
      users: {
        'gabriel_finais': PlatformRating(
          user: 'gabriel_finais',
          readAt: _readAt,
          blitz: const ModeRating(rating: 1405, games: 512),
        ),
        'sem_partidas': PlatformRating(user: 'sem_partidas', readAt: _readAt),
      },
    );
  });

  GoRoute part(String path, Widget screen) => GoRoute(
    path: path,
    builder: (_, state) =>
        BlocProvider.value(value: state.extra! as LevelCubit, child: screen),
  );

  /// "Seu nível" na primeira abertura ou, com [fromProfile], aberto de uma
  /// tela "perfil" por cima.
  Future<void> pumpLevel(
    WidgetTester tester, {
    bool fromProfile = false,
    FakeAccountRepository? accounts,
    FakeAnalyticsRepository? analytics,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final speech = SpeechCubit(
      FakeVoiceRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(speech.close);
    await speech.load();
    final settingsCubit = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settingsCubit.close);
    await settingsCubit.load();
    final profileCubit = ProfileCubit(profile);
    addTearDown(profileCubit.close);
    final router = GoRouter(
      initialLocation: fromProfile ? '/perfil' : Routes.level,
      routes: [
        GoRoute(
          path: '/perfil',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push(Routes.levelFrom('profile')),
              child: const Text('rota-perfil'),
            ),
          ),
        ),
        GoRoute(
          path: Routes.level,
          builder: (_, state) => BlocProvider(
            create: (_) => LevelCubit(
              onboarding: onboarding,
              profile: profile,
              characters: FakeCharacterRepository(),
              lichess: lichess,
              chessCom: chessCom,
              home: FakeHomeLayoutRepository(),
              fromProfile: state.uri.queryParameters['from'] == 'profile',
              accounts: accounts,
            )..load(),
            child: const LevelScreen(),
          ),
        ),
        part(Routes.levelLichess, const LevelLichessScreen()),
        part(Routes.levelChess, const LevelChessScreen()),
        part(Routes.levelRating, const LevelRatingScreen()),
        GoRoute(
          path: Routes.nextSteps,
          builder: (_, state) => Scaffold(
            body: Text(
              'rota-proximos ${state.uri.queryParameters['level'] ?? '-'}',
            ),
          ),
        ),
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('rota-home')),
        ),
        GoRoute(
          path: Routes.goal,
          builder: (_, _) => const Scaffold(body: Text('rota-objetivo')),
        ),
        GoRoute(
          path: Routes.school,
          builder: (_, _) => const Scaffold(body: Text('rota-aulas')),
        ),
      ],
    );
    final account = accounts ?? FakeAccountRepository();
    final sync = SyncScheduler(account, FakeSyncRepository());
    addTearDown(sync.dispose);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AccountRepository>.value(value: account),
          RepositoryProvider<SyncScheduler>.value(value: sync),
        ],
        child: BlocProvider.value(
          value: profileCubit,
          child: TestApp(
            settingsCubit: settingsCubit,
            speechCubit: speech,
            router: router,
            analytics: analytics,
            locale: locale,
            child: const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (fromProfile) {
      await tester.tap(find.text('rota-perfil'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> choose(WidgetTester tester, LevelChoice choice) async {
    // Lichess, Chess.com e o número ficam atrás de "Já sei o meu rating".
    if ([
      LevelChoice.lichess,
      LevelChoice.chess,
      LevelChoice.manual,
    ].contains(choice)) {
      await choose(tester, LevelChoice.known);
    }
    final card = find.byKey(LevelKeys.option(choice));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LevelKeys.continueButton));
    await tester.pumpAndSettle();
  }

  testWidgets('abre com os 3 cartões, "Fazer o teste" marcado, cartões de 48 '
      'ou mais', (tester) async {
    await pumpLevel(tester);
    expect(find.text('Your level'), findsOneWidget);
    expect(
      tester
          .element(find.byKey(LevelKeys.screen))
          .read<LevelCubit>()
          .state
          .choice,
      LevelChoice.test,
    );
    const top = [LevelChoice.test, LevelChoice.known, LevelChoice.zero];
    for (final choice in LevelChoice.values) {
      final card = find.byKey(LevelKeys.option(choice));
      if (!top.contains(choice)) {
        expect(card, findsNothing);
        continue;
      }
      await tester.ensureVisible(card);
      expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
    }
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(LevelKeys.continueButton))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('a seta de voltar leva à pergunta do objetivo', (tester) async {
    await pumpLevel(tester);
    await tester.tap(find.byKey(LevelKeys.back));
    await tester.pumpAndSettle();
    expect(find.text('rota-objetivo'), findsOneWidget);
  });

  testWidgets('"Já sei o meu rating" abre Lichess, Chess.com e o número; a '
      'seta volta às três opções', (tester) async {
    await pumpLevel(tester);
    await choose(tester, LevelChoice.known);
    for (final choice in [
      LevelChoice.lichess,
      LevelChoice.chess,
      LevelChoice.manual,
    ]) {
      expect(find.byKey(LevelKeys.option(choice)), findsOneWidget);
    }
    expect(find.byKey(LevelKeys.option(LevelChoice.test)), findsNothing);
    expect(find.byKey(LevelKeys.option(LevelChoice.zero)), findsNothing);
    await tester.tap(find.byKey(LevelKeys.back));
    await tester.pumpAndSettle();
    expect(find.byKey(LevelKeys.option(LevelChoice.known)), findsOneWidget);
    expect(find.text('rota-objetivo'), findsNothing);
  });

  testWidgets('"Não sei jogar" grava o iniciante e sai da tela', (
    tester,
  ) async {
    await pumpLevel(tester);
    await choose(tester, LevelChoice.zero);
    expect(onboarding.saved.selectedRating, RatingLevel.beginner.rating);
    expect(onboarding.saved.done, isTrue);
    expect(
      find.text(VisibleLessons.school ? 'rota-aulas' : 'rota-proximos -'),
      findsOneWidget,
    );
  });

  testWidgets(
    'rating informado: FIDE 1450 vira 1650 e vai aos próximos passos',
    (tester) async {
      await pumpLevel(tester);
      await choose(tester, LevelChoice.manual);
      expect(find.byKey(LevelKeys.ratingScreen), findsOneWidget);
      final use = find.byKey(LevelKeys.ratingUse);
      expect(tester.widget<FilledButton>(use).onPressed, isNull);
      await tester.enterText(find.byKey(LevelKeys.ratingField), '1450');
      await tester.pumpAndSettle();
      expect(find.textContaining('1450 FIDE is close to 1650'), findsOneWidget);
      await tester.tap(
        find.byKey(LevelKeys.ratingSource(RatingOrigin.lichess)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('is close to 1450'), findsOneWidget);
      await tester.enterText(find.byKey(LevelKeys.ratingField), '99');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(use).onPressed, isNull);
      await tester.enterText(find.byKey(LevelKeys.ratingField), '1450');
      await tester.pumpAndSettle();
      await tester.tap(use);
      await tester.pumpAndSettle();
      expect(profile.profile.rating, 1450);
      expect(profile.profile.levelSource, LevelSource.manual);
      expect(find.text('rota-proximos 1450'), findsOneWidget);
    },
  );

  testWidgets('rating fora de 400 a 3000: erro no campo e botão desabilitado '
      '(H-ABE-16)', (tester) async {
    await pumpLevel(tester);
    await choose(tester, LevelChoice.manual);
    const help = 'Just the number, from 400 to 3000.';
    const error = 'Enter a number from 400 to 3000.';
    final use = find.byKey(LevelKeys.ratingUse);
    // Vazio: a ajuda fica e o botão está desabilitado.
    expect(find.text(help), findsOneWidget);
    expect(find.text(error), findsNothing);
    expect(tester.widget<FilledButton>(use).onPressed, isNull);
    for (final text in ['3001', '399']) {
      await tester.enterText(find.byKey(LevelKeys.ratingField), text);
      await tester.pumpAndSettle();
      expect(find.text(error), findsOneWidget, reason: text);
      expect(tester.widget<FilledButton>(use).onPressed, isNull);
    }
    await tester.enterText(find.byKey(LevelKeys.ratingField), '3000');
    await tester.pumpAndSettle();
    expect(find.text(error), findsNothing);
    expect(tester.widget<FilledButton>(use).onPressed, isNotNull);
  });

  testWidgets('Lichess: conecta, mostra os ratings e usa o blitz', (
    tester,
  ) async {
    await pumpLevel(tester);
    await choose(tester, LevelChoice.lichess);
    expect(find.byKey(LevelKeys.lichessScreen), findsOneWidget);
    expect(find.text('Connected as gabriel_finais'), findsOneWidget);
    expect(find.text('1712'), findsOneWidget);
    expect(find.text('940 games'), findsOneWidget);
    await tester.tap(find.byKey(LevelKeys.lichessUse));
    await tester.pumpAndSettle();
    expect(profile.profile.rating, 1712);
    expect(profile.profile.lichessUser, 'gabriel_finais');
    expect(find.text('rota-proximos 1712'), findsOneWidget);
  });

  testWidgets('Lichess sem conta: o convite da conta e "Agora não" segue', (
    tester,
  ) async {
    final analytics = FakeAnalyticsRepository();
    await pumpLevel(
      tester,
      accounts: FakeAccountRepository(),
      analytics: analytics,
    );
    await choose(tester, LevelChoice.lichess);
    await tester.tap(find.byKey(LevelKeys.lichessUse));
    await tester.pumpAndSettle();
    expect(profile.profile.lichessUser, 'gabriel_finais');
    expect(find.byKey(AccountKeys.inviteSheet), findsOneWidget);
    expect(
      find.text(
        'Keep your progress and your Lichess link in a Lucena account.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(AccountKeys.notNow));
    await tester.pumpAndSettle();
    expect(find.byKey(AccountKeys.inviteSheet), findsNothing);
    expect(find.text('rota-proximos 1712'), findsOneWidget);
    expect(
      analytics.eventsNamed('conta_convite').single.params['momento'],
      'pos_lichess',
    );
  });

  testWidgets('Lichess com conta: sem convite', (tester) async {
    await pumpLevel(
      tester,
      accounts: FakeAccountRepository(account: FakeAccountRepository.google),
    );
    await choose(tester, LevelChoice.lichess);
    await tester.tap(find.byKey(LevelKeys.lichessUse));
    await tester.pumpAndSettle();
    expect(find.byKey(AccountKeys.inviteSheet), findsNothing);
    expect(find.text('rota-proximos 1712'), findsOneWidget);
  });

  testWidgets('Lichess provisório oferece o teste e "usar mesmo assim"', (
    tester,
  ) async {
    lichess.rating = PlatformRating(
      user: 'gabi_novata',
      readAt: _readAt,
      blitz: const ModeRating(rating: 1500, games: 4, provisional: true),
    );
    await pumpLevel(tester);
    await choose(tester, LevelChoice.lichess);
    expect(find.text('1500?'), findsOneWidget);
    expect(find.byKey(LevelKeys.lichessTest), findsOneWidget);
    await tester.tap(find.byKey(LevelKeys.lichessUseDefault));
    await tester.pumpAndSettle();
    expect(profile.profile.rating, 1500);
  });

  testWidgets('Lichess sem rede abre a tela "Sem internet"; Voltar fecha', (
    tester,
  ) async {
    lichess.failure = LichessFailure.network;
    await pumpLevel(tester);
    await choose(tester, LevelChoice.lichess);
    expect(find.byKey(LevelKeys.lichessScreen), findsNothing);
    expect(find.byKey(LevelKeys.lichessOfflineScreen), findsOneWidget);
    expect(
      find.text('You need an internet connection to reach Lichess.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(LevelKeys.lichessOfflineBack));
    await tester.pumpAndSettle();
    expect(find.byKey(LevelKeys.lichessOfflineScreen), findsNothing);
    expect(find.byKey(LevelKeys.screen), findsOneWidget);
  });

  testWidgets('Lichess sem rede: Tentar de novo conecta e mostra o rating', (
    tester,
  ) async {
    lichess.failure = LichessFailure.network;
    await pumpLevel(tester);
    await choose(tester, LevelChoice.lichess);
    lichess.failure = null;
    await tester.tap(find.byKey(LevelKeys.lichessRetry));
    await tester.pumpAndSettle();
    expect(find.byKey(LevelKeys.lichessOfflineScreen), findsNothing);
    expect(find.byKey(LevelKeys.lichessScreen), findsOneWidget);
    expect(find.text('1712'), findsOneWidget);
  });

  testWidgets('Lichess recusado: aviso com "Tentar de novo", sem tela nova', (
    tester,
  ) async {
    lichess.failure = LichessFailure.cancelled;
    await pumpLevel(tester);
    await choose(tester, LevelChoice.lichess);
    expect(find.byKey(LevelKeys.lichessScreen), findsNothing);
    expect(find.byKey(LevelKeys.lichessOfflineScreen), findsNothing);
    expect(find.byKey(LevelKeys.lichessCancelledSnack), findsOneWidget);
    expect(
      find.text('Could not finish the Lichess authorization'),
      findsOneWidget,
    );
    lichess.failure = null;
    await tester.tap(find.byKey(LevelKeys.lichessSnackRetry));
    await tester.pumpAndSettle();
    expect(find.byKey(LevelKeys.lichessScreen), findsOneWidget);
  });

  testWidgets('Chess.com: não achado mostra o erro; achado usa o convertido', (
    tester,
  ) async {
    await pumpLevel(tester);
    await choose(tester, LevelChoice.chess);
    expect(find.byKey(LevelKeys.chessScreen), findsOneWidget);
    final use = find.byKey(LevelKeys.chessUse);
    await tester.enterText(find.byKey(LevelKeys.chessField), 'ninguem');
    // Sem busca automática: só o botão procura.
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.textContaining("couldn't find this user"), findsNothing);
    await tester.tap(find.byKey(LevelKeys.chessSearch));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "I couldn't find this user on Chess.com. Check how it is spelled.",
      ),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(use).onPressed, isNull);
    await tester.enterText(find.byKey(LevelKeys.chessField), 'gabriel_finais');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Found: gabriel_finais'), findsOneWidget);
    expect(find.textContaining('Lucena rating starts at 1650'), findsOneWidget);
    await tester.tap(use);
    await tester.pumpAndSettle();
    expect(profile.profile.rating, 1650);
    expect(profile.profile.chessComUser, 'gabriel_finais');
  });

  testWidgets('Chess.com sem rede: tela "Sem internet" no lugar', (
    tester,
  ) async {
    chessCom.offline = true;
    await pumpLevel(tester);
    await choose(tester, LevelChoice.chess);
    await tester.enterText(find.byKey(LevelKeys.chessField), 'gabriel_finais');
    await tester.tap(find.byKey(LevelKeys.chessSearch));
    await tester.pumpAndSettle();
    expect(find.byKey(LevelKeys.chessOfflineScreen), findsOneWidget);
    expect(
      find.text('You need an internet connection to reach Chess.com.'),
      findsOneWidget,
    );
    chessCom.offline = false;
    await tester.tap(find.byKey(LevelKeys.chessRetry));
    await tester.pumpAndSettle();
    expect(find.byKey(LevelKeys.chessOfflineScreen), findsNothing);
    expect(find.text('Found: gabriel_finais'), findsOneWidget);
  });

  testWidgets('Chess.com sem rating: teste e faixa no lugar de "Usar"', (
    tester,
  ) async {
    await pumpLevel(tester);
    await choose(tester, LevelChoice.chess);
    await tester.enterText(find.byKey(LevelKeys.chessField), 'sem_partidas');
    await tester.tap(find.byKey(LevelKeys.chessSearch));
    await tester.pumpAndSettle();
    expect(find.byKey(LevelKeys.chessNoRating), findsOneWidget);
    expect(find.byKey(LevelKeys.chessUse), findsNothing);
    expect(find.byKey(LevelKeys.chessTest), findsOneWidget);
    expect(find.byKey(LevelKeys.chessPickBand), findsOneWidget);
  });

  testWidgets('com o teclado aberto, "Usar esse rating" fica acima dele', (
    tester,
  ) async {
    await pumpLevel(tester);
    await choose(tester, LevelChoice.manual);
    const keyboard = 300.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(find.byKey(LevelKeys.ratingField), '1450');
    await tester.pumpAndSettle();
    final screen =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final use = tester.getRect(find.byKey(LevelKeys.ratingUse));
    expect(use.bottom, lessThanOrEqualTo(screen - keyboard));
    expect(
      tester.widget<FilledButton>(find.byKey(LevelKeys.ratingUse)).onPressed,
      isNotNull,
    );
  });

  testWidgets('pelo Perfil, o rating informado volta para o Perfil', (
    tester,
  ) async {
    onboarding = FakeOnboardingRepository(const Onboarding(done: true));
    await pumpLevel(tester, fromProfile: true);
    await choose(tester, LevelChoice.manual);
    await tester.enterText(find.byKey(LevelKeys.ratingField), '1800');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LevelKeys.ratingUse));
    await tester.pumpAndSettle();
    expect(find.text('rota-perfil'), findsOneWidget);
    expect(find.byKey(LevelKeys.screen), findsNothing);
    expect(profile.profile.rating, 1936);
  });

  testWidgets('pelo Perfil, "Não sei jogar" também aparece', (tester) async {
    onboarding = FakeOnboardingRepository(const Onboarding(done: true));
    await pumpLevel(tester, fromProfile: true);
    final zero = find.byKey(LevelKeys.option(LevelChoice.zero));
    await tester.ensureVisible(zero);
    expect(zero, findsOneWidget);
    await tester.tap(find.byKey(LevelKeys.back));
    await tester.pumpAndSettle();
    expect(find.text('rota-perfil'), findsOneWidget);
  });

  group('H-CON-16 (PT)', () {
    const pt = Locale('pt');

    Future<void> openProfile(WidgetTester tester) async {
      onboarding = FakeOnboardingRepository(const Onboarding(done: true));
      await pumpLevel(tester, fromProfile: true, locale: pt);
    }

    testWidgets(
      '1. Seu nível pelo Perfil: textos do quadro e o teste marcado',
      (tester) async {
        await openProfile(tester);
        expect(find.text('Seu nível'), findsOneWidget);
        expect(
          find.text(
            'Para escolher os adversários certos: em que ponto você está no '
            'xadrez?',
          ),
          findsOneWidget,
        );
        expect(
          tester
              .element(find.byKey(LevelKeys.screen))
              .read<LevelCubit>()
              .state
              .choice,
          LevelChoice.test,
        );
        // Com a Escola escondida, o texto não promete a Escola.
        expect(
          find.text(
            VisibleLessons.school
                ? 'Comece pela Escola do Viktor.'
                : 'Comece pelos adversários mais fáceis.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(LevelKeys.option(LevelChoice.known)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(LevelKeys.continueButton));
        await tester.pumpAndSettle();
        for (final text in [
          'Login no site do Lichess. O Lucena lê seus ratings.',
          'Digite seu usuário para ler o rating público.',
          'Informar meu rating',
        ]) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
      },
    );

    testWidgets('2. FIDE 1450: "fica perto de 1650"; campo com ícone e dica', (
      tester,
    ) async {
      await openProfile(tester);
      await choose(tester, LevelChoice.manual);
      expect(find.text('Informar o rating'), findsOneWidget);
      final field = find.byKey(LevelKeys.ratingField);
      expect(
        find.descendant(of: field, matching: find.byIcon(Icons.trending_up)),
        findsOneWidget,
      );
      expect(find.text('Ex.: 1500'), findsOneWidget);
      await tester.enterText(field, '1450');
      await tester.tap(find.byKey(LevelKeys.ratingSource(RatingOrigin.fide)));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('1450 da FIDE fica perto de 1650 no Lucena'),
        findsOneWidget,
      );
    });

    testWidgets('3. limites: 399 e 3001 recusados, 400 e 3000 aceitos', (
      tester,
    ) async {
      await openProfile(tester);
      await choose(tester, LevelChoice.manual);
      bool enabled() =>
          tester
              .widget<FilledButton>(find.byKey(LevelKeys.ratingUse))
              .onPressed !=
          null;
      for (final (typed, ok) in [
        ('399', false),
        ('400', true),
        ('3000', true),
        ('3001', false),
      ]) {
        await tester.enterText(find.byKey(LevelKeys.ratingField), typed);
        await tester.pumpAndSettle();
        expect(enabled(), ok, reason: typed);
        expect(
          find.text('Digite um número de 400 a 3000.'),
          ok ? findsNothing : findsOneWidget,
          reason: typed,
        );
      }
    });
  });
}
