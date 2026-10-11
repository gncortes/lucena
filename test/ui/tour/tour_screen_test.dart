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
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
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
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';

import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/voice_keys.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

void main() {
  late FakeSettingsRepository settings;
  late FakeVoiceRepository voice;

  /// Abre o tour no passo [step] (o app fechado no meio volta nele).
  Future<void> pumpTour(
    WidgetTester tester, {
    TourStep step = TourStep.goal,
    Locale locale = const Locale('en'),
    FakeProfileRepository? profile,
    FakeVoiceRepository? withVoice,
  }) async {
    final voiceRepository = voice = withVoice ?? FakeVoiceRepository();
    final speech = SpeechCubit(
      voiceRepository,
      characters: FakeCharacterRepository(),
    );
    addTearDown(speech.close);
    await speech.load();
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
        speechCubit: speech,
        child: BlocProvider(
          create: (_) => TourCubit(
            onboarding: FakeOnboardingRepository(Onboarding(step: step.index)),
            profile: profile ?? FakeProfileRepository(),
            characters: FakeCharacterRepository(),
            lessons: FakeLessonRepository(),
            voice: voiceRepository,
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
    await pumpTour(tester, step: TourStep.voice, locale: const Locale('pt'));

    // A voz é o primeiro passo: sem voltar, com pular.
    expect(find.byKey(TourKeys.step(TourStep.voice)), findsOneWidget);
    expect(find.byKey(TourKeys.backButton), findsNothing);
    expect(find.byKey(TourKeys.skipButton), findsOneWidget);
    // Com uma voz escolhida, vem o passo das vozes dos adversários.
    await tester.tap(find.byKey(VoiceKeys.voice('pt-br-a')));
    await tester.pumpAndSettle();
    // Até o nível, o penúltimo passo.
    for (var step = 1; step <= TourStep.level.index; step++) {
      await tester.tap(find.byKey(TourKeys.nextButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.values[step])), findsOneWidget);
    }
    expect(find.text('Qual é o seu nível atual?'), findsOneWidget);
    // O teste vem primeiro; a lista das faixas, atrás do botão discreto.
    expect(find.byKey(TourKeys.takeTestCard), findsOneWidget);
    expect(find.byKey(TourKeys.level(RatingLevel.advanced)), findsNothing);
    await tester.tap(find.byKey(TourKeys.chooseByHand));
    await tester.pumpAndSettle();
    // Na mão, o aviso: sem o teste, o estudo não fica personalizado.
    expect(find.byKey(TourKeys.byHandHint), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(TourKeys.level(RatingLevel.advanced)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TourKeys.level(RatingLevel.advanced)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(TourKeys.startRung), 100);
    expect(find.text('A Jornada começa no Maia 1800'), findsOneWidget);
    expect(find.byKey(TourKeys.skipButton), findsOneWidget);

    // Iniciante: no último passo, os caminhos dele e o botão das aulas.
    await tester.ensureVisible(
      find.byKey(TourKeys.level(RatingLevel.beginner)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TourKeys.level(RatingLevel.beginner)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TourKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.byKey(TourKeys.step(TourStep.goals)), findsOneWidget);
    expect(find.text('O que você quer fazer no Lucena?'), findsOneWidget);
    expect(find.byKey(TourKeys.startButton), findsOneWidget);
    expect(find.byKey(TourKeys.skipButton), findsNothing);
    expect(find.text('Começar as aulas'), findsOneWidget);
    expect(find.byKey(TourKeys.viktor), findsOneWidget);
    expect(find.text('Mestre Viktor'), findsOneWidget);
    // Os cartões na ordem do iniciante: Aprender primeiro, marcado.
    final learn = tester.getRect(find.byKey(TourKeys.goal(HomePath.learn)));
    final journey = tester.getRect(find.byKey(TourKeys.goal(HomePath.journey)));
    expect(learn.top, lessThan(journey.top));
    // Desmarcar as aulas: o botão deixa de abrir as aulas.
    await tester.ensureVisible(find.byKey(TourKeys.goal(HomePath.learn)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TourKeys.goal(HomePath.learn)));
    await tester.pumpAndSettle();
    expect(find.text('Começar as aulas'), findsNothing);
  });

  testWidgets('nas boas-vindas, o campo do nome grava o apelido no perfil', (
    tester,
  ) async {
    final profile = FakeProfileRepository();
    await pumpTour(tester, locale: const Locale('pt'), profile: profile);

    expect(find.text('Como devo chamar você?'), findsOneWidget);
    // Vazio, o apelido padrão fica à vista.
    expect(find.text('Jogador'), findsOneWidget);
    await tester.enterText(find.byKey(TourKeys.nameField), 'Gabriel');
    await tester.pumpAndSettle();

    expect((await profile.load()).nickname, 'Gabriel');

    // Ir e voltar não apaga o que foi escrito.
    await tester.tap(find.byKey(TourKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.byKey(TourKeys.nameField), findsNothing);
    await tester.tap(find.byKey(TourKeys.backButton));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byKey(TourKeys.nameField)).controller!.text,
      'Gabriel',
    );
  });

  testWidgets('o nome passa do tamanho máximo: o campo corta', (tester) async {
    final profile = FakeProfileRepository();
    await pumpTour(tester, profile: profile);

    await tester.enterText(find.byKey(TourKeys.nameField), 'a' * 40);
    await tester.pumpAndSettle();

    expect(
      (await profile.load()).nickname,
      'a' * UserProfile.maxNicknameLength,
    );
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

  testWidgets('no passo do som, o som vem ligado e escolher "sem som" grava '
      'a escolha', (tester) async {
    await pumpTour(tester, step: TourStep.sound);
    expect(find.byKey(TourKeys.step(TourStep.sound)), findsOneWidget);
    expect(find.text('Sound on or off?'), findsOneWidget);
    ListTile option({required bool enabled}) =>
        tester.widget<ListTile>(find.byKey(TourKeys.sound(enabled: enabled)));
    expect(option(enabled: true).selected, isTrue);

    await tester.tap(find.byKey(TourKeys.sound(enabled: false)));
    await tester.pumpAndSettle();

    expect(option(enabled: false).selected, isTrue);
    expect(settings.saved.last.sound, isFalse);
  });

  group('a voz', () {
    testWidgets('o Viktor pede a voz dele: ouvir não grava; escolher liga a '
        'voz e vem o passo dos adversários', (tester) async {
      await pumpTour(tester, step: TourStep.voice, locale: const Locale('pt'));
      expect(find.byKey(TourKeys.step(TourStep.voice)), findsOneWidget);
      // Só as vozes do Brasil: o português do app é o pt-BR.
      expect(find.text('Voz 1'), findsOneWidget);
      expect(find.text('Voz 3'), findsOneWidget);

      await tester.tap(find.byKey(VoiceKeys.voice('pt-br-c')));
      await tester.pumpAndSettle();
      expect(voice.spoken.single.$2.voice.id, 'pt-br-c');
      expect(voice.settings.enabled, isTrue);
      expect(voice.settings.teacherVoice, 'pt-br-c');

      await tester.tap(find.byKey(TourKeys.nextButton));
      await tester.pumpAndSettle();
      expect(
        find.byKey(TourKeys.step(TourStep.characterVoices)),
        findsOneWidget,
      );
      expect(find.text('Manter assim'), findsOneWidget);
    });

    testWidgets('o passo da voz ensina a ter vozes melhores e abre os ajustes '
        'de voz do aparelho', (tester) async {
      await pumpTour(tester, step: TourStep.voice, locale: const Locale('pt'));
      await tester.scrollUntilVisible(find.byKey(VoiceKeys.openSystem), 100);
      expect(find.byKey(VoiceKeys.betterVoices), findsOneWidget);
      await tester.tap(find.byKey(VoiceKeys.openSystem));
      await tester.pumpAndSettle();
      expect(voice.systemOpened, 1);
    });

    testWidgets('"sem voz" desliga a voz e pula as vozes dos adversários', (
      tester,
    ) async {
      await pumpTour(
        tester,
        step: TourStep.voice,
        withVoice: FakeVoiceRepository(
          settings: const VoiceSettings(enabled: true),
        ),
      );
      await tester.tap(find.byKey(VoiceKeys.none));
      await tester.pumpAndSettle();
      expect(voice.settings.enabled, isFalse);

      await tester.tap(find.byKey(TourKeys.nextButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.goal)), findsOneWidget);
      // Voltando, o passo pulado continua pulado.
      await tester.tap(find.byKey(TourKeys.backButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.voice)), findsOneWidget);
    });

    testWidgets('sem voz no idioma, os dois passos somem', (tester) async {
      await pumpTour(tester, step: TourStep.sound, locale: const Locale('ja'));
      await tester.tap(find.byKey(TourKeys.nextButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.rating)), findsOneWidget);
    });

    testWidgets('as vozes dos adversários: tocar num abre a escolha, que '
        'grava e deixa ouvir na fala dele', (tester) async {
      await pumpTour(
        tester,
        step: TourStep.characterVoices,
        locale: const Locale('pt'),
        withVoice: FakeVoiceRepository(
          settings: const VoiceSettings(enabled: true),
        ),
      );
      final first = FakeCharacterRepository.sampleCharacters.firstWhere(
        (c) => c.id != 'master',
      );
      await tester.tap(find.byKey(VoiceKeys.character(first.id)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(VoiceKeys.voice('pt-br-b')));
      await tester.pumpAndSettle();
      expect(voice.settings.characterVoices[first.id], 'pt-br-b');
      expect(voice.spoken.last.$1, contains(first.name));

      await tester.tap(find.byKey(VoiceKeys.appChoice));
      await tester.pumpAndSettle();
      expect(voice.settings.characterVoices, isEmpty);
    });
  });
}
