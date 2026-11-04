import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/ui/core/theme/app_bar_height.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/ui/account/widgets/account_widgets.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/chesscom/chesscom_repository.dart';
import 'package:lucena/data/repositories/home/home_layout_repository.dart';
import 'package:lucena/data/repositories/lichess/lichess_repository.dart';
import 'package:lucena/data/repositories/onboarding/onboarding_repository.dart';
import 'package:lucena/data/repositories/profile/profile_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/widgets/choice_card.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/core/keys/voice_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/widgets/viktor_conversation.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:lucena/ui/tour/widgets/tour_screen.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';
import 'package:lucena/ui/voice/widgets/voice_pickers.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_chesscom_repository.dart';
import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_lichess_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeSettingsRepository settings;
  late FakeVoiceRepository voice;
  late FakeOnboardingRepository onboarding;
  late FakeProfileRepository profile;

  /// Abre o tour no passo [step] (o app fechado no meio volta nele), em PT-BR.
  late FakeAccountRepository accounts;

  Future<void> pumpTour(
    WidgetTester tester, {
    TourStep step = TourStep.board,
    Size size = const Size(412, 915),
    bool voices = true,
    bool link = false,
    bool learn = false,
    bool settle = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final voiceRepository = voice = FakeVoiceRepository(
      voices: voices ? null : const [],
    );
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
    onboarding = FakeOnboardingRepository(
      Onboarding(step: step.index, linkSetupDone: link),
    );
    profile = FakeProfileRepository(
      learn
          ? const UserProfile(goal: GoalPreference.learn)
          : const UserProfile(),
    );
    final router = GoRouter(
      initialLocation: Routes.tour,
      routes: [
        GoRoute(
          path: Routes.tour,
          builder: (_, _) => BlocProvider(
            create: (_) => TourCubit(
              onboarding: onboarding,
              profile: profile,
              characters: FakeCharacterRepository(),
              voice: voices ? voiceRepository : null,
            )..load('pt'),
            child: const TourScreen(),
          ),
        ),
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('rota-inicio')),
        ),
      ],
    );
    accounts = FakeAccountRepository();
    final sync = SyncScheduler(accounts, FakeSyncRepository());
    addTearDown(sync.dispose);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AccountRepository>.value(value: accounts),
          RepositoryProvider<OnboardingRepository>.value(value: onboarding),
          RepositoryProvider<ProfileRepository>.value(value: profile),
          RepositoryProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(),
          ),
          RepositoryProvider<LichessRepository>.value(
            value: FakeLichessRepository(),
          ),
          RepositoryProvider<ChessComRepository>.value(
            value: FakeChessComRepository(),
          ),
          RepositoryProvider<HomeLayoutRepository>.value(
            value: FakeHomeLayoutRepository(),
          ),
          RepositoryProvider<SyncScheduler>.value(value: sync),
          RepositoryProvider<Now>.value(value: FakeNow(DateTime(2026, 11, 4))),
        ],
        child: TestApp(
          locale: const Locale('pt'),
          settingsCubit: settingsCubit,
          speechCubit: speech,
          router: router,
          child: const SizedBox(),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // Só carrega o passo (o cubit lê o repositório), sem rodar a entrada.
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
    }
  }

  Rect rect(WidgetTester tester, Finder finder) => tester.getRect(finder);

  Finder avatarImage() => find
      .descendant(of: find.byKey(TourKeys.viktor), matching: find.byType(Image))
      .first;

  double barValue(WidgetTester tester) => tester
      .widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(TourKeys.progress),
          matching: find.byType(LinearProgressIndicator),
        ),
      )
      .value!;

  String speechText(WidgetTester tester) => tester
      .widget<ViktorConversation>(find.byType(ViktorConversation))
      .speech!;

  const sizes = [Size(412, 915), Size(360, 640)];

  group('a fala de cada passo é a do canvas', () {
    for (final voices in [true, false]) {
      testWidgets('(com voz: $voices)', (tester) async {
        final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
        await pumpTour(tester, voices: voices);
        final expected = [
          l10n.tourSpeechBoard,
          l10n.tourSpeechTheme,
          voices ? l10n.tourSpeechVoice : l10n.tourSpeechVoiceNone,
          l10n.tourSpeechLevel,
          l10n.tourSpeechRegion,
          l10n.tourSpeechAccount,
        ];
        for (var index = 0; index < expected.length; index++) {
          expect(tester.takeException(), isNull);
          expect(speechText(tester), expected[index]);
          if (index < expected.length - 1) {
            // O Nível tem o "Continuar" dele e grava; "Pular" basta aqui.
            await tester.tap(
              find.byKey(
                expected[index] == l10n.tourSpeechLevel
                    ? TourKeys.skipButton
                    : TourKeys.nextButton,
              ),
            );
            await tester.pumpAndSettle();
          }
        }
      });
    }

    testWidgets('texto da voz exatamente como no canvas', (tester) async {
      await pumpTour(tester, step: TourStep.voice);
      expect(
        speechText(tester),
        'Posso ler em voz alta tudo o que eu disser. Toque em uma voz para '
        'ouvir.',
      );
      expect(
        tester.widget<Text>(find.byKey(TourKeys.voiceHint)).data,
        'Os adversários usam uma voz do aparelho. A minha voz muda depois '
        'nas Configurações, e o seu nome, no Perfil.',
      );
    });
  });

  group('layout, em 412x915 e 360x640', () {
    for (final size in sizes) {
      for (final step in TourStep.values) {
        testWidgets(
          '${step.name} em ${size.width.toInt()}x${size.height.toInt()} '
          'cabe, com a barra na fração do canvas',
          (tester) async {
            await pumpTour(tester, step: step, size: size);
            expect(tester.takeException(), isNull);
            expect(find.byKey(TourKeys.step(step)), findsOneWidget);

            // Progresso: 4 dp, largura toda, colado na base da barra (y 64).
            final progress = rect(tester, find.byKey(TourKeys.progress));
            expect(progress.height, 4);
            expect(progress.left, 0);
            expect(progress.width, size.width);
            expect(progress.top, closeTo(AppBarHeight.standard, 1));
            const fractions = {
              TourStep.board: 0.20,
              TourStep.theme: 0.30,
              TourStep.voice: 0.40,
              TourStep.level: 0.60,
              TourStep.region: 0.80,
              TourStep.account: 1.0,
            };
            expect(barValue(tester), closeTo(fractions[step]!, 0.001));

            // Retrato do Viktor: 64, a 16 da esquerda.
            final avatar = rect(tester, avatarImage());
            expect(avatar.width, 64);
            expect(avatar.left, closeTo(16, 1));

            // Balão a 16 dos lados.
            final balloon = rect(tester, find.byKey(TourKeys.speech));
            expect(balloon.left, closeTo(16, 1));
            expect(size.width - balloon.right, closeTo(16, 1));

            // Botão de baixo (a Conta tem os dela dentro do passo).
            final button = rect(
              tester,
              find.byKey(switch (step) {
                TourStep.level => LevelKeys.continueButton,
                TourStep.account => TourKeys.accountLater,
                _ => TourKeys.nextButton,
              }),
            );
            if (step == TourStep.account) {
              expect(find.byKey(TourKeys.accountGoogle), findsOneWidget);
              expect(find.byKey(TourKeys.accountEmail), findsOneWidget);
              expect(find.byKey(TourKeys.nextButton), findsNothing);
              return;
            }
            expect(button.height, 52);
            expect(button.left, closeTo(16, 1));
            expect(size.width - button.right, closeTo(16, 1));
            expect(size.height - button.bottom, closeTo(8, 1));

            // O fim da tela rola até acima do botão.
            final scroll = tester.state<ScrollableState>(
              find
                  .descendant(
                    of: find.byKey(TourKeys.scroll),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            scroll.position.jumpTo(scroll.position.maxScrollExtent);
            await tester.pump();
            expect(tester.takeException(), isNull);
            final scrollBox = rect(tester, find.byKey(TourKeys.scroll));
            expect(scrollBox.bottom, lessThanOrEqualTo(button.top + 1));
          },
        );
      }
    }
  });

  group('barra do alto', () {
    testWidgets('sem pontinhos nem "n/N"', (tester) async {
      await pumpTour(tester);
      expect(find.textContaining(RegExp(r'\d+/\d+')), findsNothing);
      expect(find.textContaining('Passo'), findsNothing);
    });

    testWidgets('Voltar some no primeiro passo e deixa o espaço de 56; Pular '
        'fica no mesmo lugar nos dois primeiros', (tester) async {
      await pumpTour(tester);
      expect(find.byKey(TourKeys.backButton), findsNothing);
      expect(rect(tester, find.byKey(TourKeys.backSlot)).width, 56);
      final skip1 = rect(tester, find.byKey(TourKeys.skipButton));
      // O texto de "Pular" fica a 16 da direita (o botão tem 12 por dentro).
      expect(412 - skip1.right, closeTo(4, 1));
      await tester.tap(find.byKey(TourKeys.nextButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.backButton), findsOneWidget);
      final skip2 = rect(tester, find.byKey(TourKeys.skipButton));
      expect(skip2.right, skip1.right);
      expect(
        tester.getSize(find.byKey(TourKeys.backButton)).shortestSide,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(TourKeys.skipButton)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('em build de teste, o primeiro passo abre um link de desafio '
        'colado (QA sem App Links)', (tester) async {
      await pumpTour(tester);
      expect(find.byKey(TourKeys.openLink), findsOneWidget);
      await tester.tap(find.byKey(TourKeys.openLink));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('o atalho do link só aparece no primeiro passo', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.voice);
      expect(find.byKey(TourKeys.openLink), findsNothing);
    });

    testWidgets('na Conta não há Pular, e há Voltar', (tester) async {
      await pumpTour(tester, step: TourStep.account);
      expect(find.byKey(TourKeys.skipButton), findsNothing);
      expect(find.byKey(TourKeys.backButton), findsOneWidget);
      expect(barValue(tester), 1);
    });

    testWidgets('Continuar e Voltar andam pelos passos', (tester) async {
      await pumpTour(tester);
      await tester.tap(find.byKey(TourKeys.nextButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.theme)), findsOneWidget);
      await tester.tap(find.byKey(TourKeys.backButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.board)), findsOneWidget);
    });

    testWidgets('Pular pula só o passo: Voz vai ao Nível e Região à Conta', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.voice);
      await tester.tap(find.byKey(TourKeys.skipButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.level)), findsOneWidget);
      expect(barValue(tester), closeTo(0.6, 0.001));
      expect(voice.settings.enabled, isFalse);
      await tester.tap(find.byKey(TourKeys.skipButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.region)), findsOneWidget);
      await tester.tap(find.byKey(TourKeys.skipButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.account)), findsOneWidget);
      expect(onboarding.saved.done, isFalse);
    });

    testWidgets('sair da Conta leva ao Início e dá o tour por visto', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.account);
      await tester.tap(find.byKey(TourKeys.accountLater));
      await tester.pumpAndSettle();
      expect(find.text('rota-inicio'), findsOneWidget);
      expect(onboarding.saved.done, isTrue);
    });

    testWidgets('com Aprender a jogar não há Nível e a Região fica em 75%', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.voice, learn: true);
      expect(barValue(tester), closeTo(0.5, 0.001));
      await tester.tap(find.byKey(TourKeys.nextButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.region)), findsOneWidget);
      expect(barValue(tester), closeTo(0.75, 0.001));
    });
  });

  group('a conversa', () {
    testWidgets('o balão fica logo abaixo do retrato, com a ponta para cima', (
      tester,
    ) async {
      await pumpTour(tester);
      final avatar = rect(tester, avatarImage());
      final balloon = rect(tester, find.byKey(TourKeys.speech));
      expect(balloon.top, greaterThanOrEqualTo(avatar.bottom));
      expect(balloon.top - avatar.bottom, lessThanOrEqualTo(16));
    });

    testWidgets('clicar no balão abre a fala inteira; o X fecha', (
      tester,
    ) async {
      await pumpTour(tester, size: const Size(360, 640));
      await tester.tap(find.byKey(TourKeys.speech));
      await tester.pumpAndSettle();
      expect(find.byKey(LessonScriptKeys.speechSheet), findsOneWidget);
      await tester.tap(find.byKey(LessonScriptKeys.speechSheetClose));
      await tester.pumpAndSettle();
      expect(find.byKey(LessonScriptKeys.speechSheet), findsNothing);
    });
  });

  group('passo 1, tabuleiro', () {
    testWidgets('a amostra ocupa a largura toda', (tester) async {
      await pumpTour(tester);
      final preview = rect(tester, find.byKey(TourKeys.boardPreview));
      expect(preview.width, 412);
      expect(preview.left, 0);
    });

    testWidgets('abre em Cores; "Peças" troca o carrossel', (tester) async {
      await pumpTour(tester);
      expect(
        find.byKey(TourKeys.boardColors(BoardColors.green)),
        findsOneWidget,
      );
      expect(find.byKey(TourKeys.boardPieces(PieceStyle.merida)), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byKey(TourKeys.boardTabs),
          matching: find.text('Peças'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(TourKeys.boardPieces(PieceStyle.merida)),
        findsOneWidget,
      );
      expect(find.byKey(TourKeys.boardColors(BoardColors.green)), findsNothing);
    });

    testWidgets('cores e peças mudam a amostra e ficam gravadas', (
      tester,
    ) async {
      await pumpTour(tester);
      await tester.ensureVisible(
        find.byKey(TourKeys.boardColors(BoardColors.green)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(TourKeys.boardColors(BoardColors.green)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(TourKeys.boardTabs));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(TourKeys.boardTabs),
          matching: find.text('Peças'),
        ),
      );
      await tester.pumpAndSettle();
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
      expect(settings.saved.last.board.colors, BoardColors.green);
      expect(settings.saved.last.board.pieces, PieceStyle.merida);
    });

    testWidgets('o interruptor do som liga e desliga o som das peças', (
      tester,
    ) async {
      await pumpTour(tester);
      final tile = find.byKey(TourKeys.boardSound);
      await tester.ensureVisible(tile);
      expect(tester.widget<SwitchListTile>(tile).value, isTrue);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(tile).value, isFalse);
      expect(settings.saved.last.sound, isFalse);
    });
  });

  group('passo 2, tema', () {
    testWidgets('três cartões, com "Padrão do sistema" marcado', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.theme);
      bool selected(Key key) =>
          tester.widget<VoiceCard>(find.byKey(key)).selected;
      expect(selected(TourKeys.themeSystem), isTrue);
      expect(selected(TourKeys.themeLight), isFalse);
      expect(selected(TourKeys.themeDark), isFalse);
      expect(find.text('Padrão do sistema'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Escuro'), findsOneWidget);
    });

    testWidgets('tocar em "Claro" marca só ele e grava a preferência', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.theme);
      await tester.tap(find.byKey(TourKeys.themeLight));
      await tester.pumpAndSettle();
      expect(
        tester.widget<VoiceCard>(find.byKey(TourKeys.themeLight)).selected,
        isTrue,
      );
      expect(
        tester.widget<VoiceCard>(find.byKey(TourKeys.themeSystem)).selected,
        isFalse,
      );
      expect(settings.saved.last.themeMode, AppThemeMode.light);
    });
  });

  group('vindo de um link', () {
    testWidgets('abre no tema, sem o tabuleiro e sem seta de voltar', (
      tester,
    ) async {
      await pumpTour(tester, link: true);
      expect(find.byKey(TourKeys.step(TourStep.theme)), findsOneWidget);
      expect(find.byKey(TourKeys.backButton), findsNothing);
      await tester.tap(find.byKey(TourKeys.nextButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(TourKeys.backButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.theme)), findsOneWidget);
    });

    testWidgets('na voz, a fala é a de quem acabou de jogar', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
      await pumpTour(tester, link: true, step: TourStep.voice);
      expect(speechText(tester), l10n.tourSpeechVoiceLink);
    });
  });

  group('passo 3, voz e nome', () {
    testWidgets('o campo do nome grava o apelido no perfil', (tester) async {
      await pumpTour(tester, step: TourStep.voice);
      await tester.enterText(find.byKey(TourKeys.nameField), 'Ana');
      await tester.pumpAndSettle();
      expect((await profile.load()).nickname, 'Ana');
    });

    testWidgets('instalação nova: "Sem voz" marcado e o cabeçalho sem a '
        'velocidade e sem o botão de som (PropV2TourBVoz)', (tester) async {
      await pumpTour(tester, step: TourStep.voice);
      expect(voice.settings.enabled, isFalse);
      final none = tester.widget<VoiceCard>(find.byKey(TourKeys.voiceNone));
      expect(none.selected, isTrue);
      final header = find.byKey(TourKeys.viktor);
      expect(
        find.descendant(
          of: header,
          matching: find.byKey(VoiceKeys.speedButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: header,
          matching: find.byKey(VoiceKeys.speakButton),
        ),
        findsNothing,
      );
    });

    testWidgets('os cartões vêm antes do nome: Voz 1, Voz 2... e Sem voz', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.voice);
      expect(find.text('Voz 1'), findsOneWidget);
      expect(find.text('Voz 2'), findsOneWidget);
      expect(
        rect(tester, find.byKey(TourKeys.voiceCard(1))).top,
        lessThan(rect(tester, find.byKey(TourKeys.nameField)).top),
      );
    });

    testWidgets('escolhida a Voz 1, o cabeçalho mostra "1×" e o botão de som '
        '(PropV2TourBVozEscolhida)', (tester) async {
      await pumpTour(tester, step: TourStep.voice);
      await tester.ensureVisible(find.byKey(TourKeys.voiceCard(1)));
      await tester.tap(find.byKey(TourKeys.voiceCard(1)));
      await tester.pumpAndSettle();
      expect(voice.settings.enabled, isTrue);
      expect(
        tester.widget<VoiceCard>(find.byKey(TourKeys.voiceCard(1))).selected,
        isTrue,
      );
      final header = find.byKey(TourKeys.viktor);
      final speed = find.descendant(
        of: header,
        matching: find.byKey(VoiceKeys.speedButton),
      );
      expect(speed, findsOneWidget);
      expect(
        find.descendant(of: speed, matching: find.text('1×')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: header,
          matching: find.byKey(VoiceKeys.speakButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('escolher uma voz grava e liga; "sem voz" desliga; sem tom', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.voice);
      expect(find.byKey(TourKeys.voiceHint), findsOneWidget);
      for (final tone in VoiceTone.values) {
        expect(find.byKey(VoiceKeys.tone(tone)), findsNothing);
      }
      await tester.ensureVisible(find.byKey(TourKeys.voiceCard(3)));
      await tester.tap(find.byKey(TourKeys.voiceCard(3)));
      await tester.pumpAndSettle();
      expect(voice.settings.enabled, isTrue);
      expect(voice.settings.teacherVoice, 'pt-br-c');
      await tester.ensureVisible(find.byKey(TourKeys.voiceNone));
      await tester.tap(find.byKey(TourKeys.voiceNone));
      await tester.pumpAndSettle();
      expect(voice.settings.enabled, isFalse);
    });

    testWidgets('sem vozes no idioma: só o nome, e a fala é a do nome', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.voice, voices: false);
      expect(find.byKey(TourKeys.nameField), findsOneWidget);
      expect(find.byKey(TourKeys.voiceNone), findsNothing);
      expect(find.textContaining('diga como devo chamar'), findsWidgets);
    });
  });

  group('passo 4, nível', () {
    testWidgets('cinco cartões, "Estou começando" marcado', (tester) async {
      await pumpTour(tester, step: TourStep.level);
      for (final choice in [
        LevelChoice.zero,
        LevelChoice.test,
        LevelChoice.lichess,
        LevelChoice.chess,
        LevelChoice.band,
      ]) {
        expect(find.byKey(LevelKeys.option(choice)), findsOneWidget);
      }
      expect(
        tester
            .widget<ChoiceCard>(find.byKey(LevelKeys.option(LevelChoice.zero)))
            .selected,
        isTrue,
      );
    });

    testWidgets('sem entrada para digitar o rating (só o Perfil, H-ABE-16)', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.level);
      expect(find.byKey(LevelKeys.option(LevelChoice.manual)), findsNothing);
      expect(find.byKey(LevelKeys.option(LevelChoice.known)), findsNothing);
      expect(find.byKey(LevelKeys.ratingScreen), findsNothing);
    });

    testWidgets('a faixa abre a folha, Confirmar marca e mostra onde começa', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.level);
      final card = find.byKey(LevelKeys.option(LevelChoice.band));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byKey(LevelKeys.bandSheet), findsOneWidget);
      await tester.tap(find.byKey(LevelKeys.bandOption(RatingLevel.advanced)));
      await tester.tap(find.byKey(LevelKeys.bandConfirm));
      await tester.pumpAndSettle();
      expect(find.byKey(LevelKeys.bandSheet), findsNothing);
      expect(find.textContaining('A Jornada começa no Maia'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceCard>(find.byKey(LevelKeys.option(LevelChoice.band)))
            .selected,
        isTrue,
      );
    });

    testWidgets('Continuar com "Estou começando" segue para a região', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.level);
      await tester.tap(find.byKey(LevelKeys.continueButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.region)), findsOneWidget);
      expect(onboarding.saved.done, isFalse);
    });
  });

  group('passo 5, região', () {
    testWidgets('a cidade espera o estado, e o país vem da busca', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.region);
      await tester.tap(find.byKey(TourKeys.regionCountry));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(TourKeys.regionSearch), 'Brasil');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(TourKeys.regionOption('BR')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(TourKeys.regionState));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(TourKeys.regionSearch), 'São Paulo');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(TourKeys.regionOption('SP')));
      await tester.pumpAndSettle();
      expect(find.text('São Paulo'), findsOneWidget);
      await tester.tap(find.byKey(TourKeys.nextButton));
      await tester.pumpAndSettle();
      expect(profile.profile.country, 'BR');
      expect(profile.profile.state, 'SP');
      expect(find.byKey(TourKeys.step(TourStep.account)), findsOneWidget);
    });

    testWidgets('Pular não grava nada', (tester) async {
      await pumpTour(tester, step: TourStep.region);
      await tester.tap(find.byKey(TourKeys.skipButton));
      await tester.pumpAndSettle();
      expect(profile.saved.where((p) => p.country != null), isEmpty);
      expect(find.byKey(TourKeys.step(TourStep.account)), findsOneWidget);
    });
  });

  group('passo 6, conta', () {
    testWidgets('convite sem "Pular" e sem rodapé do tour', (tester) async {
      await pumpTour(tester, step: TourStep.account);
      expect(find.byKey(TourKeys.accountGoogle), findsOneWidget);
      expect(find.byKey(TourKeys.accountEmail), findsOneWidget);
      expect(find.byKey(TourKeys.accountLogin), findsOneWidget);
      expect(find.byKey(TourKeys.skipButton), findsNothing);
    });

    testWidgets('H-ABE-11: o convite é o da Conta, na ordem do quadro', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.account);
      double top(Key key) => tester.getTopLeft(find.byKey(key)).dy;
      expect(top(TourKeys.accountGoogle), lessThan(top(TourKeys.accountEmail)));
      expect(top(TourKeys.accountEmail), lessThan(top(TourKeys.accountLogin)));
      expect(top(TourKeys.accountLogin), lessThan(top(TourKeys.accountLater)));
      expect(find.byType(AccountSwitchLink), findsOneWidget);
    });

    testWidgets('H-ABE-11: o Google mostra carregando no próprio botão', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.account);
      final hold = accounts.googleHold = Completer<void>();
      await tester.tap(find.byKey(TourKeys.accountGoogle));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(TourKeys.accountGoogle),
          matching: find.byKey(CoreKeys.busySpinner),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(TourKeys.accountEmail))
            .onPressed,
        isNull,
      );
      hold.complete();
      await tester.pumpAndSettle();
    });
  });

  group('animações da abertura (T85-D3)', () {
    double opacidadeDoItem(WidgetTester tester, int i) {
      final achados = find.descendant(
        of: find.byKey(MotionKeys.itemDaCascata(i)),
        matching: find.byType(Opacity),
      );
      return achados.evaluate().isEmpty
          ? 1
          : tester.widget<Opacity>(achados.first).opacity;
    }

    testWidgets('H-ANI-13: a barra do tour enche de 0 até o passo', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.region, settle: false);
      expect(find.byKey(MotionKeys.barraQueEnche), findsOneWidget);
      expect(barValue(tester), 0);
      await tester.pump(const Duration(milliseconds: 350));
      expect(barValue(tester), allOf(greaterThan(0), lessThan(0.8)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(barValue(tester), closeTo(0.8, 0.001));
      await tester.pumpAndSettle();
    });

    testWidgets('H-ANI-16: a conta entra em cascata e o toque já vale', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.account, settle: false);
      expect(opacidadeDoItem(tester, 2), 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacidadeDoItem(tester, 0), greaterThan(0));
      expect(opacidadeDoItem(tester, 2), lessThan(1));
      // O toque fica liberado desde o início.
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(TourKeys.accountGoogle))
            .onPressed,
        isNotNull,
      );
      await tester.pump(const Duration(milliseconds: 1300));
      for (var i = 0; i < 3; i++) {
        expect(opacidadeDoItem(tester, i), 1);
      }
      await tester.pumpAndSettle();
    });

    testWidgets('H-ANI-16: a região entra em cascata (campos e benefícios)', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.region, settle: false);
      expect(opacidadeDoItem(tester, 5), 0);
      await tester.pump(const Duration(milliseconds: 1300));
      expect(opacidadeDoItem(tester, 5), 1);
      await tester.pumpAndSettle();
    });

    testWidgets('cada passo é o quadro do canvas na primeira visita', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.theme);
      final tela = tester.widget<EntradaDaTela>(find.byType(EntradaDaTela));
      expect(tela.id, 'PropV2TourBTema');
    });

    testWidgets('movimento reduzido: barra e cascata já prontas', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpTour(tester, step: TourStep.account, settle: false);
      expect(barValue(tester), 1);
      expect(opacidadeDoItem(tester, 3), 1);
      await tester.pumpAndSettle();
    });
  });
}
