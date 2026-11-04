import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/core/keys/voice_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/widgets/viktor_conversation.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:lucena/ui/tour/widgets/tour_screen.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';
import 'package:lucena/ui/voice/widgets/voice_pickers.dart';

import '../../../testing/fakes/fake_character_repository.dart';
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
  Future<void> pumpTour(
    WidgetTester tester, {
    TourStep step = TourStep.board,
    Size size = const Size(412, 915),
    bool voices = true,
    bool link = false,
    bool learn = false,
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
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settingsCubit,
        speechCubit: speech,
        router: router,
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
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
            await tester.tap(find.byKey(TourKeys.nextButton));
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

            // Progresso: 4 dp, largura toda, colado na base da barra (y 56).
            final progress = rect(tester, find.byKey(TourKeys.progress));
            expect(progress.height, 4);
            expect(progress.left, 0);
            expect(progress.width, size.width);
            expect(progress.top, closeTo(56, 1));
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

            // Botão de baixo.
            final button = rect(
              tester,
              find.byKey(
                step.isLast ? TourKeys.startButton : TourKeys.nextButton,
              ),
            );
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
      await tester.tap(find.byKey(TourKeys.startButton));
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
}
