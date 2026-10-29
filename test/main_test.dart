import 'dart:math' as math;

import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/lesson_content.dart';

import '../testing/fakes/fake_endgame_repositories.dart';

import 'package:lucena/ui/core/keys/history_keys.dart';
import 'package:lucena/ui/core/keys/rating_keys.dart';
import 'package:lucena/ui/core/widgets/character_avatar.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';
import 'package:lucena/domain/models/app_accent.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/main.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:lucena/ui/core/keys/catalog_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/game_setup_keys.dart';
import 'package:lucena/ui/core/keys/all_modes_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/data/repositories/deep_link/deep_link_repository.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/ui/core/keys/challenge_keys.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';

import 'package:lucena/domain/models/push_alert.dart';
import 'package:lucena/ui/core/keys/featured_keys.dart';

import '../testing/fakes/fake_analytics_repository.dart';
import '../testing/fakes/fake_deep_link_service.dart';
import '../testing/fakes/fake_push_repository.dart';

import 'package:lucena/ui/core/keys/goal_keys.dart';
import 'package:lucena/ui/core/keys/board_controls_keys.dart';

import '../testing/fakes/fake_onboarding_repository.dart';

import 'package:lucena/data/repositories/onboarding/onboarding_repository.dart';

import '../testing/fakes/fake_now.dart';
import '../testing/fakes/fake_ongoing_game_repository.dart';
import '../testing/fakes/fake_profile_repository.dart';
import '../testing/fakes/fake_settings_repository.dart';
import '../testing/fakes/fake_star_challenge_repository.dart';
import '../testing/test_dependencies.dart';

class _UnavailableEndgames extends FakeEndgameLessonRepository {
  @override
  Future<EndgameTrail> trail() async => throw const LessonContentUnavailable();
}

void main() {
  void useSystemLocale(WidgetTester tester, Locale locale) {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    FakeSettingsRepository? settings,
    FakeProfileRepository? profile,
    FakeNow? now,
    FakeOngoingGameRepository? games,
    FakeStarChallengeRepository? stars,
    FakeDeepLinkService? links,
    OnboardingRepository? onboarding,
    FakePushRepository? push,
    FakeAnalyticsRepository? analytics,
    FakeEndgameLessonRepository? endgameLessons,
    FakeEndgameProgressRepository? endgameProgress,
  }) async {
    await tester.pumpWidget(
      LucenaApp(
        dependencies: testDependencies(
          now: now,
          settingsRepository: settings,
          profileRepository: profile,
          ongoingGameRepository: games,
          starChallengeRepository: stars,
          onboardingRepository: onboarding,
          pushRepository: push,
          analyticsRepository: analytics,
          endgameLessonRepository: endgameLessons,
          endgameProgressRepository: endgameProgress,
          deepLinkRepository: links == null
              ? null
              : ServiceDeepLinkRepository(links),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  testWidgets('sem pacote de aula, abre o início e preserva a retomada salva', (
    tester,
  ) async {
    const saved = EndgameProgress(
      ongoing: LessonCheckpoint(
        lessonId: 'rook.lucena',
        step: 1,
        part: 'example',
      ),
    );
    final progress = FakeEndgameProgressRepository(saved);
    await pumpApp(
      tester,
      endgameLessons: FakeEndgameLessonRepository(trail: EndgameTrail.empty),
      endgameProgress: progress,
    );
    expect(find.byKey(HomeKeys.screen), findsOneWidget);
    expect(identical(progress.saved, saved), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falha no download adia retomada e mantém o início navegável', (
    tester,
  ) async {
    const saved = EndgameProgress(
      ongoing: LessonCheckpoint(
        lessonId: 'rook.lucena',
        step: 1,
        part: 'example',
      ),
    );
    final progress = FakeEndgameProgressRepository(saved);
    await pumpApp(
      tester,
      endgameLessons: _UnavailableEndgames(),
      endgameProgress: progress,
    );
    expect(find.byKey(HomeKeys.screen), findsOneWidget);
    expect(identical(progress.saved, saved), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abre na tela inicial', (tester) async {
    await pumpApp(tester);

    expect(find.byKey(HomeKeys.screen), findsOneWidget);
  });

  testWidgets('fechado à força no meio do desafio das estrelas, reabre no '
      'Pronto do mesmo desafio e nível; ao sair, não reabre mais', (
    tester,
  ) async {
    // No tamanho do celular, como no aparelho.
    tester.view.physicalSize = const Size(412, 917) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final stars = FakeStarChallengeRepository()
      ..opened = const OpenStarChallenge(
        ChallengePiece.knight,
        ChallengeLevel.medium,
      );
    await pumpApp(tester, stars: stars);

    expect(find.byKey(StarChallengeKeys.screen), findsOneWidget);
    expect(find.byKey(StarChallengeKeys.goButton), findsOneWidget);
    expect(stars.opened?.key, 'knight.medium');

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(StarChallengeKeys.listScreen), findsOneWidget);
    expect(stars.opened, isNull);
  });

  testWidgets('entrega às telas o relógio da composição', (tester) async {
    final now = FakeNow(DateTime.utc(2026, 5, 17));
    await pumpApp(tester, now: now);

    final context = tester.element(find.byKey(HomeKeys.screen));

    expect(context.read<Now>(), same(now));
  });

  testWidgets('sem idioma escolhido, segue o idioma do sistema', (
    tester,
  ) async {
    useSystemLocale(tester, const Locale('pt', 'BR'));
    await pumpApp(tester);

    expect(journeyLabel(tester), 'Jornada');
  });

  testWidgets('idioma do sistema sem tradução cai no inglês', (tester) async {
    useSystemLocale(tester, const Locale('sw'));
    await pumpApp(tester);

    expect(journeyLabel(tester), 'Journey');
  });

  testWidgets('português de Portugal usa a variante de Portugal', (
    tester,
  ) async {
    useSystemLocale(tester, const Locale('pt', 'PT'));
    await pumpApp(tester);

    await tester.tap(find.byKey(HomeKeys.settingsButton));
    await tester.pumpAndSettle();

    expect(textOf(tester, SettingsKeys.title), 'Definições');
  });

  testWidgets('o idioma escolhido vence o idioma do sistema', (tester) async {
    useSystemLocale(tester, const Locale('pt', 'BR'));
    await pumpApp(
      tester,
      settings: FakeSettingsRepository(const AppSettings(languageCode: 'es')),
    );

    expect(journeyLabel(tester), 'Recorrido');
  });

  testWidgets('em árabe a tela espelha: o botão de configurações vai para a '
      'esquerda', (tester) async {
    await pumpApp(
      tester,
      settings: FakeSettingsRepository(const AppSettings(languageCode: 'ar')),
    );

    final context = tester.element(find.byKey(HomeKeys.screen));
    final button = tester.getCenter(find.byKey(HomeKeys.settingsButton));
    final width = tester.getSize(find.byKey(HomeKeys.screen)).width;

    expect(Directionality.of(context), TextDirection.rtl);
    expect(button.dx, lessThan(width / 2));
    expect(journeyLabel(tester), 'الرحلة');
  });

  testWidgets('trocar o idioma em Configurações muda os textos na hora e '
      'grava a escolha', (tester) async {
    useSystemLocale(tester, const Locale('en', 'US'));
    final settings = FakeSettingsRepository();
    await pumpApp(tester, settings: settings);

    await tester.tap(find.byKey(HomeKeys.settingsButton));
    await tester.pumpAndSettle();
    expect(textOf(tester, SettingsKeys.title), 'Settings');

    await tester.tap(find.byKey(SettingsKeys.appearanceTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.languageTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.languageOption('es')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(textOf(tester, SettingsKeys.languageValue), 'Español');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(textOf(tester, SettingsKeys.title), 'Ajustes');
    expect(settings.saved, [const AppSettings(languageCode: 'es')]);
  });

  void useSystemBrightness(WidgetTester tester, Brightness brightness) {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }

  Brightness appBrightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byKey(HomeKeys.screen))).brightness;

  testWidgets('sem tema escolhido, o app acompanha o tema do aparelho', (
    tester,
  ) async {
    useSystemBrightness(tester, Brightness.dark);
    await pumpApp(tester);
    expect(appBrightness(tester), Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();

    expect(appBrightness(tester), Brightness.light);
  });

  testWidgets('o tema escolhido vence o tema do aparelho', (tester) async {
    useSystemBrightness(tester, Brightness.light);
    await pumpApp(
      tester,
      settings: FakeSettingsRepository(
        const AppSettings(themeMode: AppThemeMode.dark),
      ),
    );

    expect(appBrightness(tester), Brightness.dark);
  });

  testWidgets('trocar o tema em Configurações muda o app na hora e grava', (
    tester,
  ) async {
    useSystemBrightness(tester, Brightness.light);
    final settings = FakeSettingsRepository();
    await pumpApp(tester, settings: settings);

    await tester.tap(find.byKey(HomeKeys.settingsButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.appearanceTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.themeTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.themeOption(AppThemeMode.dark)));
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(SettingsKeys.themeScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(settings.saved, [const AppSettings(themeMode: AppThemeMode.dark)]);
  });

  testWidgets('trocar a cor do app em Configurações muda o app na hora, no '
      'claro e no escuro, e grava', (tester) async {
    useSystemBrightness(tester, Brightness.light);
    final settings = FakeSettingsRepository();
    await pumpApp(tester, settings: settings);

    await tester.tap(find.byKey(HomeKeys.settingsButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.appearanceTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.themeTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.accentOption(AppAccent.purple)));
    await tester.pumpAndSettle();

    // O tema que a tela usa: a cor principal e o fundo.
    (Color, Color) colors(ThemeData theme) =>
        (theme.colorScheme.primary, theme.scaffoldBackgroundColor);
    ThemeData theme() =>
        Theme.of(tester.element(find.byKey(SettingsKeys.themeScreen)));
    expect(
      colors(theme()),
      colors(AppTheme.of(Brightness.light, accent: AppAccent.purple)),
    );
    expect(settings.saved, [const AppSettings(accent: AppAccent.purple)]);

    await tester.tap(find.byKey(SettingsKeys.themeOption(AppThemeMode.dark)));
    await tester.pumpAndSettle();
    expect(
      colors(theme()),
      colors(AppTheme.of(Brightness.dark, accent: AppAccent.purple)),
    );
  });

  testWidgets('"Continuar" na tela inicial abre o desafio com o tabuleiro e o '
      'retrato voando, e voltar cai na tela inicial', (tester) async {
    // Tela de celular: o cartão do adversário cabe embaixo do tabuleiro.
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    final small = tester.getSize(find.byKey(HomeKeys.heroBoard)).width;

    await tester.ensureVisible(find.byKey(HomeKeys.goalAction));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomeKeys.goalAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // No meio do caminho: um tabuleiro só, entre o pequeno e o grande, e o
    // retrato fora dos dois cartões.
    final screen = tester.getSize(find.byType(MaterialApp)).width;
    // O maior tabuleiro: as outras miniaturas continuam na home.
    final flying = [
      for (final board in find.byType(StaticChessboard).evaluate())
        tester.getSize(find.byWidget(board.widget)).width,
    ].reduce(math.max);
    expect(flying, greaterThan(small));
    expect(flying, lessThan(screen));
    expect(
      find.descendant(
        of: find.byKey(JourneyKeys.opponentCard),
        matching: find.byType(CharacterAvatar),
      ),
      findsNothing,
    );
    expect(find.byType(CharacterAvatar), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(JourneyKeys.challengeScreen), findsOneWidget);
    expect(tester.getSize(find.byType(StaticChessboard)).width, screen);
    expect(
      find.descendant(
        of: find.byKey(JourneyKeys.opponentCard),
        matching: find.byType(CharacterAvatar),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(JourneyKeys.challengeScreen), findsNothing);
    expect(find.byKey(HomeKeys.goalAction), findsOneWidget);
  });

  testWidgets('tocar no cartão do jogador abre os detalhes do rating, e '
      'voltar cai na tela inicial', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(HomeKeys.playerCard));
    await tester.pumpAndSettle();
    expect(find.byKey(RatingKeys.screen), findsOneWidget);
    // Sem partida nenhuma, o Histórico mostra só o convite (sem cartão).
    expect(find.byKey(HistoryKeys.screen), findsOneWidget);
    expect(find.byKey(HistoryKeys.empty), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(RatingKeys.screen), findsNothing);
    expect(find.byKey(HomeKeys.playerCard), findsOneWidget);
  });

  Future<void> openProfile(WidgetTester tester) async {
    await tester.tap(find.byKey(HomeKeys.settingsButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.profileTile));
    await tester.pumpAndSettle();
  }

  Future<void> editNickname(WidgetTester tester, String text) async {
    await tester.tap(find.byKey(ProfileKeys.editData));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(AccountKeys.nickname), text);
  }

  testWidgets('salvar "Seus dados" volta ao Perfil e Configurações mostra o '
      'apelido novo', (tester) async {
    useSystemLocale(tester, const Locale('en', 'US'));
    final profile = FakeProfileRepository();
    await pumpApp(tester, profile: profile);
    await openProfile(tester);

    await editNickname(tester, 'Ana');
    await tester.tap(find.byKey(AccountKeys.dataSave));
    await tester.pumpAndSettle();
    expect(find.byKey(ProfileKeys.screen), findsOneWidget);
    expect(textOf(tester, ProfileKeys.headerName), 'Ana');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(textOf(tester, SettingsKeys.profileName), 'Ana');
    expect(profile.saved.last.nickname, 'Ana');
  });

  testWidgets('sair de "Seus dados" sem salvar não muda nada', (tester) async {
    useSystemLocale(tester, const Locale('en', 'US'));
    final profile = FakeProfileRepository(
      const UserProfile(nickname: 'Ana', rating: 1750),
    );
    await pumpApp(tester, profile: profile);
    await openProfile(tester);

    await editNickname(tester, 'Outro');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(textOf(tester, ProfileKeys.headerName), 'Ana');
    expect(profile.profile.nickname, 'Ana');
  });

  testWidgets(
    'Todos os modos, pelo "Ver mais" dos atalhos, abre o tabuleiro livre',
    (tester) async {
      useSystemLocale(tester, const Locale('pt', 'BR'));
      await pumpApp(tester);

      await openFreeBoardFromHome(tester);

      expect(find.byKey(FreeBoardKeys.screen), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.turn), findsOneWidget);
      expect(find.text('Brancas jogam'), findsNothing);
    },
  );

  group('partida em andamento', () {
    const startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

    testWidgets('sem partida gravada, o app abre na tela inicial', (
      tester,
    ) async {
      await pumpApp(tester, games: FakeOngoingGameRepository());

      expect(find.byKey(HomeKeys.screen), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.screen), findsNothing);
    });

    testWidgets('partida que estava na tela ao fechar: o app reabre nela', (
      tester,
    ) async {
      final games = FakeOngoingGameRepository(
        const GameSnapshot(startFen: startFen, moves: ['e2e4', 'e7e5']),
      );

      await pumpApp(tester, games: games);

      expect(find.byKey(FreeBoardKeys.board), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.move(1)), findsOneWidget);

      // A tela inicial está embaixo: voltar cai nela.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(HomeKeys.screen), findsOneWidget);
      expect(games.snapshot?.onScreen, isFalse);
    });

    testWidgets('tabuleiro aberto e intocado ao fechar: o app abre na tela '
        'inicial', (tester) async {
      await pumpApp(
        tester,
        games: FakeOngoingGameRepository(
          const GameSnapshot(startFen: startFen),
        ),
      );

      expect(find.byKey(HomeKeys.screen), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.screen), findsNothing);
    });

    testWidgets('partida de que o jogador saiu: abre na tela inicial e o botão '
        'pergunta antes de continuar a partida', (tester) async {
      final games = FakeOngoingGameRepository(
        const GameSnapshot(
          startFen: startFen,
          moves: ['e2e4'],
          onScreen: false,
        ),
      );

      await pumpApp(tester, games: games);
      expect(find.byKey(HomeKeys.screen), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.screen), findsNothing);

      await openFreeBoardFromHome(tester);
      // A partida guardada: o aviso pergunta antes (decisão 1 do Gabriel).
      expect(find.byKey(FreeBoardKeys.savedGameSheet), findsOneWidget);
      await tester.tap(find.byKey(FreeBoardKeys.savedGameContinue));
      await tester.pumpAndSettle();

      expect(find.byKey(FreeBoardKeys.move(0)), findsOneWidget);
      expect(games.snapshot?.onScreen, isTrue);
    });
  });

  testWidgets('catálogo → posição → configuração → partida, e voltar cai na '
      'lista', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await pumpApp(tester);

    Future<void> tap(Key key) async {
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }

    await tap(HomeKeys.catalogButton);
    await tap(CatalogKeys.category('rookPawn'));
    // As posições já estão abertas na tela da categoria.
    await tap(CatalogKeys.position('rookPawn.rookPawnVsRook.0001'));
    expect(find.byKey(GameSetupKeys.screen), findsOneWidget);

    await tap(GameSetupKeys.startButton);

    final board = tester.widget<Chessboard>(find.byKey(FreeBoardKeys.board));
    expect(board.controller.fen, '8/8/8/4k3/8/r7/4P3/4K2R b - - 0 1');
    // A posição é das pretas: o tabuleiro abre virado para elas.
    expect(board.orientation, Side.black);
    expect(find.byKey(FreeBoardKeys.clock(Side.black)), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(CatalogKeys.categoryScreen), findsOneWidget);
  });

  group('desafio por link', () {
    ChallengeLink challenge({bool locked = false}) => ChallengeLink(
      fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
      userSide: Side.white,
      opponent: OpponentKind.maia,
      level: 1400,
      clock: TimeControl.tryParse('300+0'),
      locked: locked,
    );

    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(412, 917) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    testWidgets('o app aberto pelo link fechado cai na tela do desafio, e '
        'Jogar abre a partida com o mesmo relógio', (tester) async {
      phone(tester);
      await pumpApp(
        tester,
        links: FakeDeepLinkService(initial: challenge(locked: true).uri),
      );
      expect(find.byKey(ChallengeKeys.screen), findsOneWidget);
      expect(find.byKey(ChallengeKeys.lockedNote), findsOneWidget);
      expect(find.text('5+0'), findsOneWidget);

      await tester.tap(find.byKey(ChallengeKeys.play));
      await tester.pumpAndSettle();
      expect(find.byKey(FreeBoardKeys.screen), findsOneWidget);
    });

    testWidgets('o link aberto (sem trava) preenche a Nova partida', (
      tester,
    ) async {
      phone(tester);
      await pumpApp(
        tester,
        links: FakeDeepLinkService(initial: challenge().uri),
      );
      expect(find.byKey(GameSetupKeys.screen), findsOneWidget);
      expect(find.byKey(ChallengeKeys.linkSetupSubtitle), findsOneWidget);
    });

    testWidgets('um link que chega com o app aberto abre o desafio por cima', (
      tester,
    ) async {
      phone(tester);
      final links = FakeDeepLinkService();
      await pumpApp(tester, links: links);
      expect(find.byKey(HomeKeys.screen), findsOneWidget);
      links.open(challenge(locked: true).uri);
      await tester.pumpAndSettle();
      expect(find.byKey(ChallengeKeys.screen), findsOneWidget);
    });

    testWidgets('QA cola o link nas Configurações e o desafio abre', (
      tester,
    ) async {
      phone(tester);
      await pumpApp(tester);
      await tester.tap(find.byKey(HomeKeys.settingsButton));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(SettingsKeys.openLinkTile));
      await tester.tap(find.byKey(SettingsKeys.openLinkTile));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(SettingsKeys.openLinkField), 'lixo');
      await tester.tap(find.byKey(SettingsKeys.openLinkConfirm));
      await tester.pumpAndSettle();
      expect(find.text('This is not a challenge link'), findsOneWidget);

      await tester.enterText(
        find.byKey(SettingsKeys.openLinkField),
        challenge(locked: true).uri.toString(),
      );
      await tester.tap(find.byKey(SettingsKeys.openLinkConfirm));
      await tester.pumpAndSettle();
      expect(find.byKey(ChallengeKeys.screen), findsOneWidget);
    });

    testWidgets('primeira abertura pelo link: o "Antes do desafio" vem antes '
        'e o tour espera', (tester) async {
      phone(tester);
      final onboarding = FakeOnboardingRepository(const Onboarding());
      await pumpApp(
        tester,
        onboarding: onboarding,
        links: FakeDeepLinkService(initial: challenge(locked: true).uri),
      );
      expect(find.byKey(ChallengeKeys.setupScreen), findsOneWidget);
      expect(find.byKey(TourKeys.screen), findsNothing);

      await tester.tap(find.byKey(ChallengeKeys.setupPlay));
      await tester.pumpAndSettle();
      expect(find.byKey(ChallengeKeys.screen), findsOneWidget);
      expect(onboarding.saved.linkSetupDone, isTrue);
      expect(find.byKey(TourKeys.screen), findsNothing);
    });

    testWidgets('link frio tem prioridade sobre partida e push pendentes', (
      tester,
    ) async {
      phone(tester);
      await pumpApp(
        tester,
        games: FakeOngoingGameRepository(
          const GameSnapshot(
            startFen:
                'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
            moves: ['e2e4', 'e7e5'],
          ),
        ),
        push: FakePushRepository(
          initial: PushOpening(link: Uri.parse('https://playlucena.com/daily')),
        ),
        links: FakeDeepLinkService(initial: challenge(locked: true).uri),
      );
      expect(find.byKey(ChallengeKeys.screen), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.screen), findsNothing);
    });

    testWidgets('link inválido frio permite voltar à partida salva', (
      tester,
    ) async {
      phone(tester);
      await pumpApp(
        tester,
        games: FakeOngoingGameRepository(
          const GameSnapshot(
            startFen:
                'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
            moves: ['e2e4', 'e7e5'],
          ),
        ),
        links: FakeDeepLinkService(
          initial: Uri.parse('https://playlucena.com/p/bad?fen=bad'),
        ),
      );
      expect(find.byKey(ChallengeKeys.invalidScreen), findsOneWidget);
      await tester.tap(find.byKey(ChallengeKeys.invalidBack));
      await tester.pumpAndSettle();
      expect(find.byKey(FreeBoardKeys.screen), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.move(1)), findsOneWidget);
    });

    testWidgets('um link quebrado mostra erro sobre a tela inicial', (
      tester,
    ) async {
      phone(tester);
      await pumpApp(
        tester,
        links: FakeDeepLinkService(
          initial: Uri.parse('https://playlucena.com/p/abcde?fen=lixo'),
        ),
      );
      expect(find.byKey(ChallengeKeys.invalidScreen), findsOneWidget);
      await tester.tap(find.byKey(ChallengeKeys.invalidBack));
      await tester.pumpAndSettle();
      expect(find.byKey(HomeKeys.screen), findsOneWidget);
    });
  });

  testWidgets(
    'primeira abertura pergunta intenção e oferece controles sem tour',
    (tester) async {
      final onboarding = FakeOnboardingRepository(
        const Onboarding(stage: OnboardingStage.goal),
      );
      await pumpApp(tester, onboarding: onboarding);
      expect(find.byKey(GoalKeys.screen), findsOneWidget);
      expect(find.byKey(TourKeys.screen), findsNothing);
      await tester.tap(find.byKey(GoalKeys.option(GoalPreference.learn)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(GoalKeys.continueButton));
      await tester.pumpAndSettle();
      expect(find.byKey(BoardControlsKeys.screen), findsOneWidget);
      await tester.tap(find.byKey(BoardControlsKeys.continueButton));
      await tester.pumpAndSettle();
      expect(onboarding.saved.boardControlsDone, isTrue);
      expect(find.byKey(HomeKeys.screen), findsOneWidget);
    },
  );
  group('push (E1.19 3.8)', () {
    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(412, 917) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    testWidgets('app fechado: o toque abre o torneio e conta o envio', (
      tester,
    ) async {
      phone(tester);
      final analytics = FakeAnalyticsRepository();
      await pumpApp(
        tester,
        analytics: analytics,
        push: FakePushRepository(
          initial: PushOpening(
            link: Uri.parse('/featured/tournament/live'),
            pushId: 'p1',
            country: 'BR',
          ),
        ),
      );

      expect(find.byKey(FeaturedKeys.tournamentScreen), findsOneWidget);
      final event = analytics.eventsNamed('push_aberto').single;
      expect(event.params, {'push_id': 'p1', 'pais': 'BR'});
    });

    testWidgets('link que esta versão não tem: abre no início', (tester) async {
      phone(tester);
      await pumpApp(
        tester,
        push: FakePushRepository(
          initial: PushOpening(link: Uri.parse('/featured/ranking/2026')),
        ),
      );

      expect(find.byKey(HomeKeys.screen), findsOneWidget);
    });

    testWidgets('em segundo plano: o toque em Ver torneio abre o torneio', (
      tester,
    ) async {
      phone(tester);
      final push = FakePushRepository();
      await pumpApp(tester, push: push);

      push.open(Uri.parse('/featured/tournament/live'), pushId: 'p2');
      await tester.pumpAndSettle();

      expect(find.byKey(FeaturedKeys.tournamentScreen), findsOneWidget);
    });
  });
}

/// O lugar do cartão azul da tela inicial (a Jornada), no idioma da tela.
String? journeyLabel(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(HomeKeys.heroLabel)).data;

/// O tabuleiro livre saiu da tela inicial (T83): abre por "Todos os modos",
/// no "Ver mais" dos atalhos.
Future<void> openFreeBoardFromHome(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(HomeKeys.shortcutsSeeMore));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(HomeKeys.shortcutsSeeMore));
  await tester.pumpAndSettle();
  final item = find.byKey(AllModesKeys.item('freeBoard'));
  await tester.scrollUntilVisible(item, 200);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}
