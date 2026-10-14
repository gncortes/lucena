import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/core/keys/voice_keys.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/widgets/position_board.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:lucena/ui/tour/widgets/tour_screen.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';

const _longSpeech =
    'Bem-vindo, meu aluno. Eu sou o Viktor e vou lhe mostrar, passo a passo, '
    'como se ganha um final de partida com calma e com método, do começo até '
    'o último lance, sem pressa nenhuma.';

final _texts = LessonTexts.fromJson({
  'tour.board': _longSpeech,
  'tour.voice': 'Escolha a minha voz.',
  'tour.voice.none': 'Só o seu nome, então.',
  'tour.school': 'Cada lição tem três etapas.',
  'tour.help': 'Ficou difícil? Peça ajuda.',
  'tour.play': 'Depois, jogue contra os adversários.',
  'tour.level': 'Escolha o seu nível.',
});

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
    onboarding = FakeOnboardingRepository(Onboarding(step: step.index));
    profile = FakeProfileRepository();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => BlocProvider(
            create: (_) => TourCubit(
              onboarding: onboarding,
              profile: profile,
              characters: FakeCharacterRepository(),
              lessons: FakeLessonRepository(texts: _texts),
              voice: voices ? voiceRepository : null,
            )..load('pt'),
            child: const TourScreen(),
          ),
        ),
        GoRoute(
          path: Routes.school,
          builder: (_, _) => const Scaffold(body: Text('rota-aulas')),
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

  const sizes = [Size(412, 915), Size(360, 640)];

  group('layout, em 412x915 e 360x640', () {
    for (final size in sizes) {
      for (final step in TourStep.values) {
        testWidgets(
          '${step.name} em ${size.width.toInt()}x${size.height.toInt()} '
          'cabe, com o botão de 52 a 16 dos lados e 24 do fundo',
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
            final bar = tester.widget<LinearProgressIndicator>(
              find.descendant(
                of: find.byKey(TourKeys.progress),
                matching: find.byType(LinearProgressIndicator),
              ),
            );
            expect(bar.value, closeTo((step.index + 1) / 6, 0.001));

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
            expect(size.height - button.bottom, closeTo(24, 1));

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

    testWidgets('no último passo não há Pular e há Voltar', (tester) async {
      await pumpTour(tester, step: TourStep.level);
      expect(find.byKey(TourKeys.skipButton), findsNothing);
      expect(find.byKey(TourKeys.backButton), findsOneWidget);
    });

    testWidgets('Continuar e Voltar andam pelos passos', (tester) async {
      await pumpTour(tester);
      await tester.tap(find.byKey(TourKeys.nextButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.voice)), findsOneWidget);
      await tester.tap(find.byKey(TourKeys.backButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.board)), findsOneWidget);
    });

    testWidgets('Pular leva ao último passo', (tester) async {
      await pumpTour(tester);
      await tester.tap(find.byKey(TourKeys.skipButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.level)), findsOneWidget);
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
      expect(
        find.descendant(
          of: find.byKey(LessonScriptKeys.speechSheet),
          matching: find.textContaining('último lance', findRichText: true),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(LessonScriptKeys.speechSheetClose));
      await tester.pumpAndSettle();
      expect(find.byKey(LessonScriptKeys.speechSheet), findsNothing);
    });
  });

  group('passo 1, tabuleiro', () {
    testWidgets('a amostra tem 216 e fica centrada', (tester) async {
      await pumpTour(tester);
      final preview = rect(tester, find.byKey(TourKeys.boardPreview));
      expect(preview.width, 216);
      expect(preview.center.dx, closeTo(206, 1));
    });

    testWidgets('cores e peças mudam a amostra e ficam gravadas', (
      tester,
    ) async {
      await pumpTour(tester);
      await tester.tap(find.byKey(TourKeys.boardColors(BoardColors.green)));
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

    testWidgets('a cor escolhida vale nos tabuleiros dos passos 3 e 4', (
      tester,
    ) async {
      await pumpTour(tester);
      await tester.tap(find.byKey(TourKeys.boardColors(BoardColors.green)));
      await tester.pumpAndSettle();
      // Voz, depois aulas (passo 3).
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(TourKeys.nextButton));
        await tester.pumpAndSettle();
      }
      Object scheme() => tester
          .widget<StaticChessboard>(find.byType(StaticChessboard))
          .settings
          .colorScheme;
      expect(scheme(), BoardColors.green.scheme);
      await tester.tap(find.byKey(TourKeys.nextButton));
      await tester.pumpAndSettle();
      expect(scheme(), BoardColors.green.scheme);
    });
  });

  group('passo 2, voz e nome', () {
    testWidgets('o campo do nome grava o apelido no perfil', (tester) async {
      await pumpTour(tester, step: TourStep.voice);
      await tester.enterText(find.byKey(TourKeys.nameField), 'Ana');
      await tester.pumpAndSettle();
      expect((await profile.load()).nickname, 'Ana');
    });

    testWidgets('escolher uma voz grava e liga; "sem voz" desliga; sem tom', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.voice);
      expect(find.byKey(TourKeys.voiceHint), findsOneWidget);
      for (final tone in VoiceTone.values) {
        expect(find.byKey(VoiceKeys.tone(tone)), findsNothing);
      }
      await tester.ensureVisible(find.byKey(VoiceKeys.voice('pt-br-c')));
      await tester.tap(find.byKey(VoiceKeys.voice('pt-br-c')));
      await tester.pumpAndSettle();
      expect(voice.settings.enabled, isTrue);
      expect(voice.settings.teacherVoice, 'pt-br-c');
      await tester.ensureVisible(find.byKey(VoiceKeys.none));
      await tester.tap(find.byKey(VoiceKeys.none));
      await tester.pumpAndSettle();
      expect(voice.settings.enabled, isFalse);
    });

    testWidgets('sem vozes no idioma: só o nome, e a fala é a do nome', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.voice, voices: false);
      expect(find.byKey(TourKeys.nameField), findsOneWidget);
      expect(find.byKey(VoiceKeys.none), findsNothing);
      expect(find.textContaining('Só o seu nome'), findsWidgets);
    });
  });

  group('passos 3 a 5', () {
    testWidgets('aulas: três etapas e tabuleiro de 176 centrado', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.school);
      expect(find.byKey(TourKeys.stages), findsOneWidget);
      final board = rect(tester, find.byType(PositionBoard));
      expect(board.width, 176);
      expect(board.center.dx, closeTo(206, 1));
      expect(find.text('Ideia'), findsOneWidget);
      expect(find.text('Exemplos'), findsOneWidget);
      expect(find.text('Prática'), findsOneWidget);
    });

    testWidgets('ajuda: tabuleiro de 200 centrado e "Ver resposta" de 48', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.help);
      expect(find.byKey(TourKeys.helpButtons), findsOneWidget);
      final board = rect(tester, find.byType(PositionBoard));
      expect(board.width, 200);
      expect(board.center.dx, closeTo(206, 1));
      expect(find.text('Ver resposta'), findsOneWidget);
      expect(
        rect(tester, find.byKey(TourKeys.helpButtons)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('partidas: os adversários e o chip do rating do perfil', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.play);
      expect(find.byKey(TourKeys.opponents), findsOneWidget);
      expect(find.byKey(TourKeys.ratingChip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('passo 6, nível', () {
    testWidgets('abre com "Estou começando" marcado, Começar liberado; 48+', (
      tester,
    ) async {
      await pumpTour(tester, step: TourStep.level);
      final start = tester.widget<FilledButton>(
        find.byKey(TourKeys.startButton),
      );
      expect(start.onPressed, isNotNull);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      for (final choice in TourLevelChoice.values) {
        final card = find.byKey(TourKeys.levelOption(choice));
        await tester.ensureVisible(card);
        expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('Começar grava "começando" e leva às aulas', (tester) async {
      await pumpTour(tester, step: TourStep.level);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.textContaining('A Jornada começa no'), findsNothing);
      final start = tester.widget<FilledButton>(
        find.byKey(TourKeys.startButton),
      );
      expect(start.onPressed, isNotNull);
      expect(onboarding.saved.selectedRating, isNull);
      await tester.tap(find.byKey(TourKeys.startButton));
      await tester.pumpAndSettle();
      expect(onboarding.saved.selectedRating, RatingLevel.beginner.rating);
      expect(find.text('rota-aulas'), findsOneWidget);
      expect(onboarding.saved.done, isTrue);
    });
  });
}
