import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/main.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:lucena/ui/core/keys/catalog_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/game_setup_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';

import '../testing/fakes/fake_now.dart';
import '../testing/fakes/fake_ongoing_game_repository.dart';
import '../testing/fakes/fake_profile_repository.dart';
import '../testing/fakes/fake_settings_repository.dart';
import '../testing/test_dependencies.dart';

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
  }) async {
    await tester.pumpWidget(
      LucenaApp(
        dependencies: testDependencies(
          now: now,
          settingsRepository: settings,
          profileRepository: profile,
          ongoingGameRepository: games,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  testWidgets('abre na tela inicial', (tester) async {
    await pumpApp(tester);

    expect(find.byKey(HomeKeys.screen), findsOneWidget);
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

    expect(textOf(tester, HomeKeys.tagline), 'Treino de finais de xadrez');
  });

  testWidgets('idioma do sistema sem tradução cai no inglês', (tester) async {
    useSystemLocale(tester, const Locale('sw'));
    await pumpApp(tester);

    expect(textOf(tester, HomeKeys.tagline), 'Chess endgame training');
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

    expect(
      textOf(tester, HomeKeys.tagline),
      'Entrenamiento de finales de ajedrez',
    );
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
    expect(textOf(tester, HomeKeys.tagline), 'تدريب نهايات الشطرنج');
  });

  testWidgets('trocar o idioma em Configurações muda os textos na hora e '
      'grava a escolha', (tester) async {
    useSystemLocale(tester, const Locale('en', 'US'));
    final settings = FakeSettingsRepository();
    await pumpApp(tester, settings: settings);

    await tester.tap(find.byKey(HomeKeys.settingsButton));
    await tester.pumpAndSettle();
    expect(textOf(tester, SettingsKeys.title), 'Settings');

    await tester.tap(find.byKey(SettingsKeys.languageTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.languageOption('es')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(textOf(tester, SettingsKeys.title), 'Ajustes');
    expect(textOf(tester, SettingsKeys.languageValue), 'Español');
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
    await tester.tap(find.byKey(SettingsKeys.themeTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.themeOption(AppThemeMode.dark)));
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(SettingsKeys.themeScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(settings.saved, [const AppSettings(themeMode: AppThemeMode.dark)]);
  });

  Future<void> openProfile(WidgetTester tester) async {
    await tester.tap(find.byKey(HomeKeys.settingsButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.profileTile));
    await tester.pumpAndSettle();
  }

  Future<void> pickLevel(WidgetTester tester, RatingLevel level) async {
    await tester.tap(find.byKey(ProfileKeys.levelField));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(ProfileKeys.levelOption(level)));
    await tester.tap(find.byKey(ProfileKeys.levelOption(level)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ProfileKeys.levelConfirmButton));
    await tester.pumpAndSettle();
  }

  testWidgets('salvar o perfil volta para Configurações com os dados novos', (
    tester,
  ) async {
    useSystemLocale(tester, const Locale('en', 'US'));
    final profile = FakeProfileRepository();
    await pumpApp(tester, profile: profile);
    await openProfile(tester);

    await tester.enterText(find.byKey(ProfileKeys.nicknameField), 'Ana');
    await pickLevel(tester, RatingLevel.advanced);
    await tester.tap(find.byKey(ProfileKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.byKey(ProfileKeys.screen), findsNothing);
    expect(textOf(tester, SettingsKeys.profileValue), 'Ana · Advanced');
    expect(profile.saved, [
      UserProfile(nickname: 'Ana', rating: RatingLevel.advanced.rating),
    ]);
  });

  testWidgets('editar o perfil e sair sem salvar não muda nada', (
    tester,
  ) async {
    useSystemLocale(tester, const Locale('en', 'US'));
    final profile = FakeProfileRepository(
      const UserProfile(nickname: 'Ana', rating: 1750),
    );
    await pumpApp(tester, profile: profile);
    await openProfile(tester);

    await tester.enterText(find.byKey(ProfileKeys.nicknameField), 'Outro');
    await pickLevel(tester, RatingLevel.beginner);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(textOf(tester, SettingsKeys.profileValue), 'Ana · Advanced');
    expect(profile.saved, isEmpty);

    await tester.tap(find.byKey(SettingsKeys.profileTile));
    await tester.pumpAndSettle();
    final nickname = tester.widget<TextField>(
      find.byKey(ProfileKeys.nicknameField),
    );
    expect(nickname.controller!.text, 'Ana');
    expect(textOf(tester, ProfileKeys.levelName), 'Advanced');
  });

  testWidgets('o botão da tela inicial abre o tabuleiro livre', (tester) async {
    useSystemLocale(tester, const Locale('pt', 'BR'));
    await pumpApp(tester);

    expect(
      find.descendant(
        of: find.byKey(HomeKeys.freeBoardButton),
        matching: find.text('Tabuleiro livre'),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(HomeKeys.freeBoardButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomeKeys.freeBoardButton));
    await tester.pumpAndSettle();

    expect(find.byKey(FreeBoardKeys.screen), findsOneWidget);
    expect(textOf(tester, FreeBoardKeys.turn), 'Brancas jogam');
  });

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
        'continua a partida', (tester) async {
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

      await tester.ensureVisible(find.byKey(HomeKeys.freeBoardButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(HomeKeys.freeBoardButton));
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
    await tap(CatalogKeys.subcategory('rookPawnVsRook'));
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
    expect(find.byKey(CatalogKeys.subcategoryScreen), findsOneWidget);
  });
}
