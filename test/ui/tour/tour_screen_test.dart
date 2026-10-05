import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_accent.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:lucena/ui/tour/widgets/tour_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeSettingsRepository settings;

  /// Abre o tour no passo [step] (o app fechado no meio volta nele).
  Future<void> pumpTour(
    WidgetTester tester, {
    TourStep step = TourStep.goal,
    Locale locale = const Locale('en'),
  }) async {
    settings = FakeSettingsRepository();
    final settingsCubit = SettingsCubit(
      settings,
      languages: AppLanguage.selectable,
    );
    addTearDown(settingsCubit.close);
    await settingsCubit.load();
    // Um tour novo a cada chamada, sem o estado do anterior.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        settingsCubit: settingsCubit,
        child: BlocProvider(
          create: (_) => TourCubit(
            onboarding: FakeOnboardingRepository(Onboarding(step: step.index)),
            profile: FakeProfileRepository(),
            characters: FakeCharacterRepository(),
            lessons: FakeLessonRepository(),
          )..load(locale.languageCode),
          child: const TourScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ThemeData theme(WidgetTester tester) =>
      Theme.of(tester.element(find.byKey(TourKeys.screen)));

  testWidgets('os passos em ordem e o nível no fim, em português', (
    tester,
  ) async {
    await pumpTour(tester, locale: const Locale('pt'));

    expect(find.byKey(TourKeys.step(TourStep.goal)), findsOneWidget);
    expect(find.byKey(TourKeys.skipButton), findsOneWidget);
    for (var step = 1; step < TourStep.values.length; step++) {
      await tester.tap(find.byKey(TourKeys.nextButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.values[step])), findsOneWidget);
    }
    expect(find.text('Qual é o seu nível atual?'), findsOneWidget);
    await tester.tap(find.byKey(TourKeys.level(RatingLevel.advanced)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(TourKeys.startRung), 100);
    expect(find.text('A Jornada começa no Maia 1800'), findsOneWidget);
    expect(find.byKey(TourKeys.startButton), findsOneWidget);
    expect(find.byKey(TourKeys.skipButton), findsNothing);

    // Iniciante: o botão abre as aulas.
    await tester.ensureVisible(
      find.byKey(TourKeys.level(RatingLevel.beginner)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TourKeys.level(RatingLevel.beginner)));
    await tester.pumpAndSettle();
    expect(find.text('Começar as aulas'), findsOneWidget);
    expect(find.byKey(TourKeys.viktor), findsOneWidget);
    expect(find.text('Mestre Viktor'), findsOneWidget);
  });

  testWidgets('a aparência vem logo depois das boas-vindas: tema e depois '
      'tabuleiro', (tester) async {
    await pumpTour(tester, locale: const Locale('pt'));

    await tester.tap(find.byKey(TourKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.text('Deixe o app com a sua cara'), findsOneWidget);
    expect(find.textContaining('nas Configurações'), findsOneWidget);

    await tester.tap(find.byKey(TourKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.text('Escolha o seu tabuleiro'), findsOneWidget);
    expect(find.byKey(TourKeys.boardPreview), findsOneWidget);
  });

  testWidgets('no passo do tema, a cor de fábrica vem marcada e escolher '
      'outra muda o app na hora e grava', (tester) async {
    await pumpTour(tester, step: TourStep.theme);

    expect(tester.widget<Text>(find.byKey(TourKeys.accentValue)).data, 'Blue');

    await tester.tap(find.byKey(TourKeys.accent(AppAccent.pink)));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(TourKeys.accentValue)).data, 'Pink');
    expect(
      theme(tester).colorScheme.primary,
      AppTheme.of(Brightness.light, accent: AppAccent.pink).colorScheme.primary,
    );
    expect(settings.saved, [const AppSettings(accent: AppAccent.pink)]);
  });

  testWidgets('no passo do tema, escolher escuro grava o tema', (tester) async {
    await pumpTour(tester, step: TourStep.theme);

    await tester.tap(find.byKey(TourKeys.themeMode(AppThemeMode.dark)));
    await tester.pumpAndSettle();

    expect(settings.saved, [const AppSettings(themeMode: AppThemeMode.dark)]);
  });

  testWidgets('no passo do tabuleiro, cores e peças mudam a amostra e ficam '
      'gravadas', (tester) async {
    await pumpTour(tester, step: TourStep.board);

    await tester.tap(find.byKey(TourKeys.boardColors(BoardColors.green)));
    await tester.pumpAndSettle();
    // As peças ficam abaixo da amostra e das cores; a fileira rola de lado.
    await tester.scrollUntilVisible(
      find.byKey(TourKeys.boardPieces(PieceStyle.cburnett)),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.byKey(TourKeys.boardPieces(PieceStyle.merida)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TourKeys.boardPieces(PieceStyle.merida)));
    await tester.pumpAndSettle();

    final preview = tester
        .widget<StaticChessboard>(find.byKey(TourKeys.boardPreview))
        .settings;
    expect(preview.colorScheme, BoardColors.green.scheme);
    expect(preview.pieceAssets, PieceStyle.merida.assets);
    expect(
      settings.saved.last,
      const AppSettings(
        board: BoardSettings(
          colors: BoardColors.green,
          pieces: PieceStyle.merida,
        ),
      ),
    );
  });

  testWidgets('os passos de aparência cabem em tela pequena e em árabe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final step in [TourStep.theme, TourStep.board]) {
      await pumpTour(tester, step: step, locale: const Locale('ar'));
      expect(find.byKey(TourKeys.step(step)), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
