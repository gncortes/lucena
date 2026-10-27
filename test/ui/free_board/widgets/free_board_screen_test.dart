import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:lucena/ui/free_board/widgets/move_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/ui/conclusion/view_models/conclusion_cubit.dart';
import 'package:lucena/ui/core/theme/app_motion.dart';
import 'package:lucena/ui/core/widgets/game_clock.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/character.dart';

import '../../../../testing/goldens/golden_harness.dart';

import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/clock_settings.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/ui/core/keys/challenge_keys.dart';
import 'package:lucena/ui/core/keys/daily_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/widgets/speech_balloon.dart';
import 'package:lucena/ui/featured/view_models/featured_endgame_cubit.dart';
import 'package:lucena/ui/daily/view_models/daily_game_cubit.dart';

import '../../../../testing/fakes/fake_daily_final_repository.dart';
import '../../../../testing/fakes/fake_activity_repository.dart';
import '../../../../testing/fakes/fake_kpk_repository.dart';

import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';
import 'package:lucena/ui/core/widgets/character_avatar.dart';
import 'package:lucena/ui/core/widgets/character_speech.dart';
import 'package:lucena/ui/free_board/view_models/talk_cubit.dart';
import 'package:lucena/ui/free_board/widgets/clock_row.dart';
import 'package:lucena/ui/free_board/widgets/free_board_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../../testing/fakes/fake_voice_repository.dart';

import '../../../../testing/board_gestures.dart';
import '../../../../testing/fakes/fake_achievements_repository.dart';
import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/fakes/fake_positions_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_featured_repositories.dart';
import '../../../../testing/fakes/fake_evaluation_repository.dart';
import '../../../../testing/fakes/fake_haptics_repository.dart';
import '../../../../testing/fakes/fake_talk_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_opponent_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FreeBoardCubit cubit;
  late FakeNow now;
  late FakeOngoingGameRepository games;
  late FakeOpponentRepository opponent;
  late FakeProgressRepository progress;
  late TalkCubit talk;
  late FakeEvaluationRepository evaluation;
  late FakeTalkRepository talkRepository;

  Future<void> pumpScreen(
    WidgetTester tester, {
    String? fen,
    Locale locale = const Locale('en'),
    BoardSettings board = const BoardSettings(),
    Side? playerSide,
    ClockConfig? clock,
    ClockSettings clockSettings = const ClockSettings(),
    GameSnapshot? saved,
    GameMode mode = const GameMode(),
    AppSettings? appSettings,
    bool withReporter = false,
    Size screen = const Size(1080, 2400),
    bool systemBars = false,
    FakeCharacterRepository? characters,
    EdgeInsets? systemInsets,
    ThemeMode themeMode = ThemeMode.light,
    SpeechCubit? speech,
    bool scriptedTalk = false,
  }) async {
    // Tela de celular em retrato, como no app.
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    if (systemBars || systemInsets != null) {
      final insets = systemInsets ?? const EdgeInsets.only(top: 24, bottom: 32);
      final padding = FakeViewPadding(
        top: insets.top * 2.625,
        bottom: insets.bottom * 2.625,
      );
      tester.view.viewPadding = padding;
      tester.view.padding = padding;
    }
    final repository = FakeSettingsRepository(
      appSettings ?? AppSettings(board: board, clock: clockSettings),
    );
    final settings = SettingsCubit(
      repository,
      languages: AppLanguage.selectable,
    );
    now = FakeNow(DateTime.utc(2026, 1, 1, 12));
    addTearDown(settings.close);
    await settings.load();
    games = FakeOngoingGameRepository(saved);
    opponent = FakeOpponentRepository(now: now);
    progress = FakeProgressRepository();
    cubit = FreeBoardCubit(
      now: now,
      haptics: FakeHapticsRepository(),
      settings: repository,
      games: games,
      opponent: opponent,
      progress: progress,
      // Com partida gravada, a tela abre para continuar essa partida.
      start: saved != null
          ? null
          : fen == null
          ? GameRules.initial
          : GameRules.fromFen(fen)!,
      playerSide: playerSide,
      clock: clock,
      mode: mode,
      reporter: withReporter
          ? GameReporter(
              rating: FakeRatingRepository(),
              achievements: FakeAchievementsRepository(),
              journey: FakeJourneyRepository(),
              progress: progress,
              speedruns: FakeSpeedrunRepository(progress),
              positions: FakePositionsRepository(),
              now: now,
            )
          : null,
    );
    addTearDown(cubit.close);
    evaluation = FakeEvaluationRepository();
    talkRepository = FakeTalkRepository();
    final createTalk = scriptedTalk ? _FixtureTalkCubit.new : TalkCubit.new;
    talk = createTalk(
      characters: characters ?? FakeCharacterRepository(),
      evaluation: evaluation,
      talk: talkRepository,
      settings: repository,
      now: now,
      language: 'en',
      random: Random(1),
    );
    addTearDown(talk.close);
    // A partida contra a máquina termina trocando de tela para a conclusão.
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cubit),
              BlocProvider.value(value: talk),
              if (mode.dailyDate != null)
                BlocProvider(
                  create: (_) => DailyGameCubit(
                    date: mode.dailyDate!,
                    daily: FakeDailyFinalRepository(),
                    activity: FakeActivityRepository(),
                    kpk: FakeKpkRepository(),
                  ),
                ),
              if (mode.featuredId != null)
                BlocProvider(
                  create: (_) => FeaturedEndgameCubit(
                    id: mode.featuredId!,
                    featured: FakeFeaturedRepository(sampleFeaturedCatalog()),
                    progress: FakeFeaturedProgressRepository(),
                    characters: FakeCharacterRepository(),
                  ),
                ),
            ],
            child: const FreeBoardScreen(),
          ),
        ),
        GoRoute(
          path: '/result',
          builder: (context, state) {
            final args = state.extra! as ConclusionArgs;
            return Scaffold(
              body: Text('conclusion ${args.conclusion.result.name}'),
            );
          },
        ),
        GoRoute(
          path: '/result/:id',
          builder: (context, state) =>
              Scaffold(body: Text('conclusion ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        themeMode: themeMode,
        settingsCubit: settings,
        speechCubit: speech,
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect boardRect(WidgetTester tester) =>
      tester.getRect(find.byKey(FreeBoardKeys.board));

  /// Toca na casa de origem e depois na de destino.
  Future<void> move(WidgetTester tester, String from, String to) async {
    final orientation = cubit.state.orientation;
    final board = boardRect(tester);
    await tester.tapAt(squareCenter(board, from, orientation: orientation));
    await tester.pump();
    await tester.tapAt(squareCenter(board, to, orientation: orientation));
    await tester.pumpAndSettle();
  }

  /// Como [move], mas sem esperar as animações: lê o selo logo após o fim.
  Future<void> moveNow(WidgetTester tester, String from, String to) async {
    final orientation = cubit.state.orientation;
    final board = boardRect(tester);
    await tester.tapAt(squareCenter(board, from, orientation: orientation));
    await tester.pump();
    await tester.tapAt(squareCenter(board, to, orientation: orientation));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> drag(WidgetTester tester, String from, String to) async {
    final board = boardRect(tester);
    await tester.dragFrom(
      squareCenter(board, from),
      squareCenter(board, to) - squareCenter(board, from),
    );
    await tester.pumpAndSettle();
  }

  Chessboard boardWidget(WidgetTester tester) =>
      tester.widget<Chessboard>(find.byKey(FreeBoardKeys.board));

  String moveText(WidgetTester tester, int index) {
    final text = tester.widget<RichText>(
      find.descendant(
        of: find.byKey(FreeBoardKeys.move(index)),
        matching: find.byType(RichText),
      ),
    );
    return text.text.toPlainText();
  }

  // A vez sem relógio é o anel primário de 2 px no retrato de quem joga (T73,
  // D1): um só na tela, e nenhum chip de texto.
  void expectRing(WidgetTester tester) {
    expect(find.byKey(FreeBoardKeys.turn), findsOneWidget);
    final box = tester.widget<DecoratedBox>(find.byKey(FreeBoardKeys.turn));
    final border = (box.decoration as BoxDecoration).border! as Border;
    expect(border.top.width, 2);
    expect(
      border.top.color,
      Theme.of(tester.element(find.byKey(FreeBoardKeys.turn)))
          .colorScheme
          .primary,
    );
    expect(find.text('Your turn'), findsNothing);
    expect(find.text('White to move'), findsNothing);
    expect(find.text('Black to move'), findsNothing);
  }

  String boardFen(WidgetTester tester) =>
      tester.widget<Chessboard>(find.byKey(FreeBoardKeys.board)).controller.fen;

  // O texto na key, simples ou com partes (o relógio escreve os décimos
  // menores).
  String textOf(WidgetTester tester, Key key) {
    final texts = find.descendant(
      of: find.byKey(key),
      matching: find.byType(Text),
      matchRoot: true,
    );
    final text = tester.widget<Text>(
      key == FreeBoardKeys.endFlash ? texts.first : texts,
    );
    return text.data ?? text.textSpan!.toPlainText();
  }

  testWidgets('abre na posição inicial, com as brancas para jogar', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(boardFen(tester), GameRules.initial.fen);
    expectRing(tester);
    expect(find.byKey(FreeBoardKeys.noMoves), findsOneWidget);
  });

  testWidgets(
    'o tabuleiro usa as cores, as peças e as coordenadas escolhidas',
    (tester) async {
      await pumpScreen(
        tester,
        board: const BoardSettings(
          colors: BoardColors.green,
          pieces: PieceStyle.merida,
          coordinates: false,
        ),
      );

      final settings = tester
          .widget<Chessboard>(find.byKey(FreeBoardKeys.board))
          .settings;
      expect(settings.colorScheme, ChessboardColorScheme.green);
      expect(settings.pieceAssets, PieceSet.meridaAssets);
      expect(settings.enableCoordinates, isFalse);
    },
  );

  testWidgets('tocar na peça e no destino joga o lance e passa a vez', (
    tester,
  ) async {
    await pumpScreen(tester);

    await move(tester, 'e2', 'e4');

    expect(cubit.state.moves, ['e4']);
    expectRing(tester);
    expect(find.byKey(FreeBoardKeys.move(0)), findsOneWidget);
    expect(find.byKey(FreeBoardKeys.noMoves), findsNothing);
    expect(boardFen(tester), cubit.state.position.fen);
  });

  testWidgets('arrastar a peça também joga o lance', (tester) async {
    await pumpScreen(tester);
    final board = boardRect(tester);

    await tester.dragFrom(
      squareCenter(board, 'g1'),
      squareCenter(board, 'f3') - squareCenter(board, 'g1'),
    );
    await tester.pumpAndSettle();

    expect(cubit.state.moves, ['Nf3']);
  });

  testWidgets('lance ilegal não muda o tabuleiro nem a lista', (tester) async {
    await pumpScreen(tester);

    await move(tester, 'e2', 'e5');
    await move(tester, 'e7', 'e5');

    expect(boardFen(tester), GameRules.initial.fen);
    expect(cubit.state.moves, isEmpty);
    expectRing(tester);
  });

  testWidgets('a lista mostra a peça em figurino no lugar da letra', (
    tester,
  ) async {
    await pumpScreen(tester);

    await move(tester, 'g1', 'f3');

    final chip = find.byKey(FreeBoardKeys.move(0));
    final text = tester.widget<RichText>(
      find.descendant(of: chip, matching: find.byType(RichText)),
    );
    expect(text.text.toPlainText(), '♘f3');
    expect(tester.getSemantics(chip).label, 'Nf3');
  });

  testWidgets('os lances ficam numa faixa no alto, lado a lado, com o número '
      'de cada jogada', (tester) async {
    await pumpScreen(tester);

    await move(tester, 'e2', 'e4');
    await move(tester, 'e7', 'e5');
    await move(tester, 'g1', 'f3');

    final white1 = tester.getRect(find.byKey(FreeBoardKeys.move(0)));
    final black1 = tester.getRect(find.byKey(FreeBoardKeys.move(1)));
    final white2 = tester.getRect(find.byKey(FreeBoardKeys.move(2)));
    // Como no chess.com: todos na mesma linha, um depois do outro.
    expect(black1.center.dy, white1.center.dy);
    expect(white2.center.dy, white1.center.dy);
    expect(black1.left, greaterThan(white1.right - 1));
    expect(white2.left, greaterThan(black1.right - 1));
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    // A faixa fica acima do tabuleiro, logo abaixo da barra do alto.
    expect(white1.bottom, lessThanOrEqualTo(boardRect(tester).top));
  });

  testWidgets('tocar num lance mostra a posição daquele momento, só para ver; '
      'tocar no último volta para a partida', (tester) async {
    await pumpScreen(tester);
    await move(tester, 'e2', 'e4');
    await move(tester, 'e7', 'e5');
    await move(tester, 'g1', 'f3');
    final live = cubit.state.position.fen;

    // O primeiro lance: só o peão do rei saiu.
    await tester.tap(find.byKey(FreeBoardKeys.move(0)));
    await tester.pumpAndSettle();
    expect(cubit.state.browsing, isTrue);
    expect(cubit.state.shownPosition.board.pieceAt(Square.e4), isNotNull);
    expect(cubit.state.shownPosition.board.pieceAt(Square.e5), isNull);
    // A partida não mudou, e mexer nas peças não joga nada.
    await move(tester, 'd7', 'd5');
    expect(cubit.state.position.fen, live);
    expect(cubit.state.moves, ['e4', 'e5', 'Nf3']);

    await tester.tap(find.byKey(FreeBoardKeys.move(1)));
    await tester.pumpAndSettle();
    expect(cubit.state.viewedPly, 2);
    expect(cubit.state.shownPosition.board.pieceAt(Square.e5), isNotNull);

    // O último lance devolve o tabuleiro à partida.
    await tester.tap(find.byKey(FreeBoardKeys.move(2)));
    await tester.pumpAndSettle();
    expect(cubit.state.browsing, isFalse);
    await move(tester, 'b8', 'c6');
    expect(cubit.state.moves, ['e4', 'e5', 'Nf3', 'Nc6']);
  });

  testWidgets('sem lances, a faixa avisa que não há lances', (tester) async {
    await pumpScreen(tester);

    expect(find.byKey(FreeBoardKeys.noMoves), findsOneWidget);
    expect(find.byKey(FreeBoardKeys.move(0)), findsNothing);
  });

  testWidgets('promoção: o seletor aparece e o cavalo escolhido entra', (
    tester,
  ) async {
    await pumpScreen(tester, fen: '8/P6k/8/8/8/8/8/K7 w - - 0 1');

    await move(tester, 'a7', 'a8');
    // O lance só entra depois de escolher a peça no seletor.
    expect(cubit.state.moves, isEmpty);

    await tester.tapAt(
      promotionChoiceCenter(boardRect(tester), 'a8', Role.knight),
    );
    await tester.pumpAndSettle();

    expect(cubit.state.moves, ['a8=N']);
    expect(cubit.state.position.board.roleAt(Square.a8), Role.knight);
  });

  testWidgets('com as pretas começando, a lista abre com reticências', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      fen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
    );

    await move(tester, 'e7', 'e5');

    // O número vem com reticências: o primeiro lance é das pretas.
    expect(find.text('1...'), findsOneWidget);
    final number = tester.getRect(find.text('1...'));
    final black = tester.getRect(find.byKey(FreeBoardKeys.move(0)));
    expect(black.center.dy, number.center.dy);
    expect(black.left, greaterThan(number.left));
    expect(cubit.state.moves, ['e5']);
  });

  testWidgets('mate: mostra o resultado traduzido e trava o tabuleiro', (
    tester,
  ) async {
    // Falta só Dxf7 para o mate do pastor.
    await pumpScreen(
      tester,
      fen:
          'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
      locale: const Locale('pt'),
    );

    await move(tester, 'h5', 'f7');

    expect(textOf(tester, FreeBoardKeys.endReason), 'Xeque-mate');
    expect(textOf(tester, FreeBoardKeys.endResult), 'Vitória das brancas');
    expect(find.byKey(FreeBoardKeys.turn), findsNothing);

    final fen = boardFen(tester);
    await move(tester, 'e8', 'f7');
    expect(boardFen(tester), fen);
  });

  testWidgets('nova partida volta à posição inicial e limpa a lista', (
    tester,
  ) async {
    await pumpScreen(tester);
    await move(tester, 'e2', 'e4');
    await move(tester, 'e7', 'e5');

    await tester.ensureVisible(find.byKey(FreeBoardKeys.newGameButton));
    await tester.tap(find.byKey(FreeBoardKeys.newGameButton));
    await tester.pumpAndSettle();

    expect(boardFen(tester), GameRules.initial.fen);
    expect(find.byKey(FreeBoardKeys.noMoves), findsOneWidget);
    expectRing(tester);
  });

  testWidgets('no fim, o botão do painel começa outra partida', (tester) async {
    await pumpScreen(
      tester,
      fen:
          'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
    );
    await move(tester, 'h5', 'f7');

    await tester.ensureVisible(find.byKey(FreeBoardKeys.endNewGameButton));
    await tester.tap(find.byKey(FreeBoardKeys.endNewGameButton));
    await tester.pumpAndSettle();

    expect(find.byKey(FreeBoardKeys.endPanel), findsNothing);
    expect(cubit.state.moves, isEmpty);
  });

  testWidgets('no tabuleiro livre a partida não fica no histórico: sem o '
      'botão de revisar', (tester) async {
    await pumpScreen(
      tester,
      fen:
          'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
    );
    await move(tester, 'h5', 'f7');

    expect(find.byKey(FreeBoardKeys.endPanel), findsOneWidget);
  });

  testWidgets('em árabe o tabuleiro e a lista não espelham', (tester) async {
    await pumpScreen(tester, locale: const Locale('ar'));

    await move(tester, 'e2', 'e4');

    // a1 continua embaixo à esquerda: o lance e2-e4 só vale se não espelhou.
    expect(cubit.state.moves, ['e4']);
    final list = tester.element(find.byKey(FreeBoardKeys.move(0)));
    expect(Directionality.of(list), TextDirection.ltr);
  });

  testWidgets('só tocar: arrastar não move a peça, tocar move', (tester) async {
    await pumpScreen(
      tester,
      board: const BoardSettings(moveMethod: MoveMethod.tap),
    );

    await drag(tester, 'e2', 'e4');
    expect(cubit.state.moves, isEmpty);

    await move(tester, 'g1', 'f3');
    expect(cubit.state.moves, ['Nf3']);
  });

  testWidgets('só arrastar: tocar não move a peça, arrastar move', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      board: const BoardSettings(moveMethod: MoveMethod.drag),
    );

    await move(tester, 'e2', 'e4');
    expect(cubit.state.moves, isEmpty);

    await drag(tester, 'g1', 'f3');
    expect(cubit.state.moves, ['Nf3']);
  });

  testWidgets('ajudas visuais e animação seguem as preferências', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      board: const BoardSettings(
        showLegalMoves: false,
        highlightLastMove: false,
        animation: false,
      ),
    );

    final settings = boardWidget(tester).settings;
    expect(settings.showValidMoves, isFalse);
    expect(settings.showLastMove, isFalse);
    expect(settings.animationDuration, Duration.zero);
  });

  testWidgets('virar o tabuleiro inverte a orientação e mantém a lista', (
    tester,
  ) async {
    await pumpScreen(tester);
    await move(tester, 'e2', 'e4');
    await move(tester, 'e7', 'e5');

    await tester.ensureVisible(find.byKey(FreeBoardKeys.flipButton));
    await tester.tap(find.byKey(FreeBoardKeys.flipButton));
    await tester.pumpAndSettle();

    expect(boardWidget(tester).orientation, Side.black);
    expect(cubit.state.moves, ['e4', 'e5']);

    // Com o tabuleiro virado, as casas trocam de lugar na tela.
    await move(tester, 'g1', 'f3');
    expect(cubit.state.moves, ['e4', 'e5', 'Nf3']);
  });

  testWidgets('notação por letras em português mostra C, B, T, D e R', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      fen: '4k3/8/8/8/8/8/8/R1BQKBN1 w - - 0 1',
      locale: const Locale('pt'),
      board: const BoardSettings(notation: MoveNotation.letters),
    );

    await move(tester, 'g1', 'f3');
    await move(tester, 'e8', 'e7');
    await move(tester, 'f1', 'c4');
    await move(tester, 'e7', 'f6');
    await move(tester, 'd1', 'd4');
    await move(tester, 'f6', 'e7');
    await move(tester, 'a1', 'a7');

    expect(
      [for (var i = 0; i < 7; i++) moveText(tester, i)],
      ['Cf3', 'Re7', 'Bc4', 'Rf6', 'Dd4+', 'Re7', 'Ta7+'],
    );
    expect(tester.getSemantics(find.byKey(FreeBoardKeys.move(0))).label, 'Cf3');
  });

  testWidgets('pré-lance: marcado na vez do adversário e jogado em seguida', (
    tester,
  ) async {
    await pumpScreen(tester, playerSide: Side.white);
    await move(tester, 'e2', 'e4');

    // Vez das pretas: o lance das brancas fica só marcado.
    await move(tester, 'd2', 'd4');
    expect(cubit.state.moves, ['e4']);
    expect(boardWidget(tester).controller.premove, NormalMove.fromUci('d2d4'));

    cubit.play(NormalMove.fromUci('e7e5'));
    await tester.pumpAndSettle();

    expect(cubit.state.moves, ['e4', 'e5', 'd4']);
    expect(boardWidget(tester).controller.premove, isNull);
  });

  testWidgets('pré-lance que deixou de ser legal é descartado', (tester) async {
    await pumpScreen(tester, playerSide: Side.white);
    await move(tester, 'e2', 'e4');
    await move(tester, 'e4', 'e5');

    cubit.play(NormalMove.fromUci('e7e5'));
    await tester.pumpAndSettle();

    expect(cubit.state.moves, ['e4', 'e5']);
    expect(boardWidget(tester).controller.premove, isNull);
  });

  testWidgets('com os pré-lances desligados, nada fica marcado', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      playerSide: Side.white,
      board: const BoardSettings(premoves: false),
    );
    await move(tester, 'e2', 'e4');

    await move(tester, 'd2', 'd4');
    expect(boardWidget(tester).controller.premove, isNull);

    cubit.play(NormalMove.fromUci('e7e5'));
    await tester.pumpAndSettle();
    expect(cubit.state.moves, ['e4', 'e5']);
  });

  testWidgets('o jogador de um lado só não move as peças do adversário', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      playerSide: Side.white,
      board: const BoardSettings(premoves: false),
    );
    await move(tester, 'e2', 'e4');

    await move(tester, 'e7', 'e5');

    expect(cubit.state.moves, ['e4']);
  });

  group('relógio', () {
    const fiveMinutes = TimeControl(initial: Duration(minutes: 5));
    const threeTwo = TimeControl(
      initial: Duration(minutes: 3),
      increment: Duration(seconds: 2),
    );
    const oneZero = TimeControl(initial: Duration(minutes: 1));

    String clockText(WidgetTester tester, Side side) =>
        textOf(tester, FreeBoardKeys.clockTime(side));

    Rect clockRect(WidgetTester tester, Side side) =>
        tester.getRect(find.byKey(FreeBoardKeys.clock(side)));

    /// O relógio do aparelho anda e a tela refaz os tempos no próximo tique.
    Future<void> elapse(WidgetTester tester, Duration duration) async {
      now.advance(duration);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
    }

    Future<void> tap(WidgetTester tester, Key key) async {
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }

    testWidgets('partida sem relógio não mostra relógio nenhum', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byKey(FreeBoardKeys.clock(Side.white)), findsNothing);
      expect(find.byKey(FreeBoardKeys.clock(Side.black)), findsNothing);
    });

    testWidgets('cada lado mostra o seu tempo', (tester) async {
      await pumpScreen(
        tester,
        clock: const ClockConfig(white: oneZero, black: threeTwo),
      );

      expect(clockText(tester, Side.white), '1:00');
      expect(clockText(tester, Side.black), '3:00');
    });

    testWidgets('o tempo de quem joga desconta sozinho na tela', (
      tester,
    ) async {
      await pumpScreen(tester, clock: ClockConfig.same(fiveMinutes));

      await elapse(tester, const Duration(seconds: 7));

      expect(clockText(tester, Side.white), '4:53');
      expect(clockText(tester, Side.black), '5:00');
    });

    testWidgets('incremento de 2 s: depois do lance o relógio soma 2 s', (
      tester,
    ) async {
      await pumpScreen(tester, clock: ClockConfig.same(threeTwo));

      await move(tester, 'e2', 'e4');

      expect(clockText(tester, Side.white), '3:02');
      expect(clockText(tester, Side.black), '3:00');
    });

    testWidgets('abaixo de 10 s aparecem os décimos', (tester) async {
      await pumpScreen(
        tester,
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(seconds: 15)),
        ),
      );
      expect(clockText(tester, Side.white), '0:15');

      await elapse(tester, const Duration(seconds: 5, milliseconds: 500));

      expect(clockText(tester, Side.white), '0:09.5');
      expect(clockText(tester, Side.black), '0:15');
    });

    testWidgets('tempo esgotado: tela de fim e tabuleiro travado', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(seconds: 5)),
        ),
      );

      await elapse(tester, const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(textOf(tester, FreeBoardKeys.endReason), 'Time out');
      expect(textOf(tester, FreeBoardKeys.endResult), 'Black wins');
      expect(clockText(tester, Side.white), '0:00.0');

      await move(tester, 'e2', 'e4');
      expect(cubit.state.moves, isEmpty);
    });

    testWidgets('bandeira contra rei sozinho: empate', (tester) async {
      await pumpScreen(
        tester,
        fen: 'k7/8/8/8/8/8/P7/K7 w - - 0 1',
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(seconds: 5)),
        ),
      );

      await elapse(tester, const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(
        textOf(tester, FreeBoardKeys.endReason),
        'Time out vs. insufficient material',
      );
      expect(textOf(tester, FreeBoardKeys.endResult), 'Draw');
    });

    testWidgets(
      'um de cada lado: pretas em cima, brancas embaixo; vira junto',
      (tester) async {
        await pumpScreen(tester, clock: ClockConfig.same(fiveMinutes));
        final board = boardRect(tester);

        expect(
          clockRect(tester, Side.black).bottom,
          lessThanOrEqualTo(board.top),
        );
        expect(
          clockRect(tester, Side.white).top,
          greaterThanOrEqualTo(board.bottom),
        );

        await tester.ensureVisible(find.byKey(FreeBoardKeys.flipButton));
        await tester.tap(find.byKey(FreeBoardKeys.flipButton));
        await tester.pumpAndSettle();

        expect(
          clockRect(tester, Side.white).bottom,
          lessThanOrEqualTo(board.top),
        );
        expect(
          clockRect(tester, Side.black).top,
          greaterThanOrEqualTo(board.bottom),
        );
      },
    );

    testWidgets('os dois em cima: os relógios ficam acima do tabuleiro', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        clock: ClockConfig.same(fiveMinutes),
        clockSettings: const ClockSettings(position: ClockPosition.top),
      );
      final board = boardRect(tester);

      for (final side in Side.values) {
        expect(clockRect(tester, side).bottom, lessThanOrEqualTo(board.top));
      }
      expect(
        clockRect(tester, Side.white).top,
        clockRect(tester, Side.black).top,
      );
    });

    testWidgets('os dois embaixo: os relógios ficam abaixo do tabuleiro', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        clock: ClockConfig.same(fiveMinutes),
        clockSettings: const ClockSettings(position: ClockPosition.bottom),
      );
      final board = boardRect(tester);

      for (final side in Side.values) {
        expect(clockRect(tester, side).top, greaterThanOrEqualTo(board.bottom));
      }
    });

    testWidgets('painel do relógio: escolher 3 min + 2 s começa a partida', (
      tester,
    ) async {
      await pumpScreen(tester);
      await move(tester, 'e2', 'e4');

      await tap(tester, FreeBoardKeys.clockButton);
      expect(find.byKey(FreeBoardKeys.clockSheet), findsOneWidget);
      await tap(tester, FreeBoardKeys.clockEnabledSwitch);
      await tap(tester, FreeBoardKeys.clockMinutes(Side.white, 3));
      await tap(tester, FreeBoardKeys.clockIncrement(Side.white, 2));
      await tap(tester, FreeBoardKeys.clockStartButton);

      expect(find.byKey(FreeBoardKeys.clockSheet), findsNothing);
      expect(cubit.state.clock?.config, ClockConfig.same(threeTwo));
      expect(cubit.state.moves, isEmpty);
      expect(clockText(tester, Side.white), '3:00');
      expect(clockText(tester, Side.black), '3:00');
    });

    testWidgets('painel do relógio: tempos diferentes para cada lado', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tap(tester, FreeBoardKeys.clockButton);
      await tap(tester, FreeBoardKeys.clockEnabledSwitch);
      await tap(tester, FreeBoardKeys.clockSameSwitch);
      await tap(tester, FreeBoardKeys.clockMinutes(Side.white, 1));
      await tap(tester, FreeBoardKeys.clockMinutes(Side.black, 3));
      await tap(tester, FreeBoardKeys.clockIncrement(Side.black, 2));
      await tap(tester, FreeBoardKeys.clockStartButton);

      expect(
        cubit.state.clock?.config,
        const ClockConfig(white: oneZero, black: threeTwo),
      );
      expect(clockText(tester, Side.white), '1:00');
      expect(clockText(tester, Side.black), '3:00');
    });

    testWidgets('painel do relógio fechado sem confirmar não muda a partida', (
      tester,
    ) async {
      await pumpScreen(tester);
      await move(tester, 'e2', 'e4');

      await tap(tester, FreeBoardKeys.clockButton);
      await tap(tester, FreeBoardKeys.clockEnabledSwitch);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.byKey(FreeBoardKeys.clockSheet), findsNothing);
      expect(cubit.state.clock, isNull);
      expect(cubit.state.moves, ['e4']);
    });

    testWidgets('painel do relógio: desligar o relógio tira os relógios', (
      tester,
    ) async {
      await pumpScreen(tester, clock: ClockConfig.same(fiveMinutes));

      await tap(tester, FreeBoardKeys.clockButton);
      await tap(tester, FreeBoardKeys.clockEnabledSwitch);
      await tap(tester, FreeBoardKeys.clockStartButton);

      expect(cubit.state.clock, isNull);
      expect(find.byKey(FreeBoardKeys.clock(Side.white)), findsNothing);
    });
  });

  group('restauração', () {
    testWidgets('enquanto a partida gravada é lida, o tabuleiro não aparece', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        saved: GameSnapshot(
          startFen: GameRules.initial.fen,
          moves: const ['e2e4', 'e7e5'],
        ),
      );

      expect(find.byKey(FreeBoardKeys.screen), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.board), findsNothing);
    });

    testWidgets('a partida gravada volta com a posição, a lista e o relógio', (
      tester,
    ) async {
      const time = TimeControl(initial: Duration(minutes: 5));
      await pumpScreen(
        tester,
        saved: GameSnapshot(
          startFen: GameRules.initial.fen,
          moves: const ['e2e4', 'e7e5'],
          orientation: Side.black,
          clock: ClockState(
            config: ClockConfig.same(time),
            white: const Duration(minutes: 4),
            black: const Duration(minutes: 5),
            running: Side.white,
            // A vez começou 30 s antes de o app reabrir.
            turnStartedAt: DateTime.utc(2026, 1, 1, 11, 59, 30),
          ),
        ),
      );

      await cubit.open();
      await tester.pumpAndSettle();

      expect(cubit.state.moves, ['e4', 'e5']);
      expect(boardFen(tester), cubit.state.position.fen);
      expect(boardWidget(tester).orientation, Side.black);
      expect(textOf(tester, FreeBoardKeys.clockTime(Side.white)), '3:30');
      expect(textOf(tester, FreeBoardKeys.clockTime(Side.black)), '5:00');
      expect(find.byKey(FreeBoardKeys.move(1)), findsOneWidget);
    });
  });

  group('T65 Speedrun V2', () {
    const speedrun = GameMode(
      opponent: OpponentKind.maia,
      level: 1600,
      userSide: Side.white,
      positionId: 'basic.queen.0001',
      speedrunId: 'queen',
      speedrunAttemptId: 1,
      speedrunStage: 0,
    );

    /// A etapa aberta, já com o rating do jogador lido.
    Future<void> pumpStage(
      WidgetTester tester, {
      required Size size,
      double scale = 1,
      ThemeMode theme = ThemeMode.light,
      Locale locale = const Locale('en'),
    }) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpScreen(
        tester,
        screen: size * 2.625,
        systemBars: true,
        mode: speedrun,
        locale: locale,
        themeMode: theme,
        withReporter: true,
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(minutes: 3)),
        ),
      );
      await cubit.open();
      await talk.settled();
      await tester.pumpAndSettle();
    }

    Rect stripOf(WidgetTester tester, Side side) => tester.getRect(
      find.ancestor(
        of: find.byKey(FreeBoardKeys.clock(side)),
        matching: find.byType(ClockRow),
      ),
    );

    for (final size in const [Size(360, 740), Size(412, 917)]) {
      for (final scale in const [1.0, 2.0]) {
        for (final theme in const [ThemeMode.light, ThemeMode.dark]) {
          for (final locale in const [Locale('en'), Locale('ar')]) {
            testWidgets('etapa $size, fonte $scale, ${theme.name}, '
                '${locale.languageCode}: centro, faixas de 68, detalhe e '
                'alvos', (tester) async {
              await pumpStage(
                tester,
                size: size,
                scale: scale,
                theme: theme,
                locale: locale,
              );
              final l10n = lookupAppLocalizations(locale);
              expect(tester.takeException(), isNull);
              expect(
                textOf(tester, FreeBoardKeys.title),
                l10n.speedrunModeClassic,
              );
              final board = boardRect(tester);
              // Centro da imagem inteira; exceção só se uma linha não couber.
              expectScreenBoardCenter(tester, board);
              expect(board.center.dx, closeTo(size.width / 2, 1));
              expect(board.width, closeTo(size.width, .5));
              // As faixas: 68 de altura e 8 até o tabuleiro dos dois lados.
              final top = stripOf(tester, Side.black);
              final bottom = stripOf(tester, Side.white);
              expect(top.height, closeTo(68, 1));
              expect(bottom.height, closeTo(68, 1));
              expect(board.top - top.bottom, closeTo(8, 1));
              expect(bottom.top - board.bottom, closeTo(8, 1));
              // O balão não cobre o tabuleiro.
              final bubble = find.byKey(FreeBoardKeys.speechBubble);
              if (bubble.evaluate().isNotEmpty) {
                expect(
                  tester.getRect(bubble).bottom,
                  lessThanOrEqualTo(board.top),
                );
              }
              // Nome e detalhe permanecem visíveis durante a fala.
              // A linha de detalhe: o nível do personagem e o rating.
              expect(
                textOf(tester, FreeBoardKeys.playerDetail(Side.black)),
                l10n.journeyOpponentLevel('1600'),
              );
              expect(
                textOf(tester, FreeBoardKeys.playerDetail(Side.white)),
                '1150',
              );
              final detail = tester.getRect(
                find.byKey(FreeBoardKeys.playerDetail(Side.black)),
              );
              expect(detail.top, greaterThanOrEqualTo(top.top));
              expect(detail.bottom, lessThanOrEqualTo(top.bottom));
              // Retrato no começo da linha e relógio no fim: espelha em
              // árabe.
              final avatar = tester.getRect(find.byType(CharacterAvatar));
              final clock = tester.getRect(
                find.byKey(FreeBoardKeys.clock(Side.black)),
              );
              if (locale.languageCode == 'ar') {
                expect(avatar.center.dx, greaterThan(clock.center.dx));
                expect(avatar.right, closeTo(size.width - 16, 1));
              } else {
                expect(avatar.center.dx, lessThan(clock.center.dx));
                expect(avatar.left, closeTo(16, 1));
              }
              // O tempo fica em m:ss, da esquerda para a direita.
              final time = tester.widget<Directionality>(
                find
                    .ancestor(
                      of: find.byKey(FreeBoardKeys.clockTime(Side.black)),
                      matching: find.byType(Directionality),
                    )
                    .first,
              );
              expect(time.textDirection, TextDirection.ltr);
              // Alvos de toque da barra de ações.
              for (final key in [
                FreeBoardKeys.resignButton,
                FreeBoardKeys.drawButton,
                FreeBoardKeys.soundButton,
              ]) {
                final target = tester.getRect(find.byKey(key));
                expect(target.height, greaterThanOrEqualTo(48));
                expect(target.width, greaterThanOrEqualTo(48));
              }
              final actions = tester.getRect(
                find.byKey(FreeBoardKeys.actionsBar),
              );
              expect(bottom.bottom, lessThanOrEqualTo(actions.top));
              await tester.ensureVisible(find.byKey(FreeBoardKeys.actionsBar));
              await tester.pumpAndSettle();
              expect(
                tester.getRect(find.byKey(FreeBoardKeys.actionsBar)).bottom,
                closeTo(size.height - 32, 1),
              );
            });
          }
        }
      }
    }

    // As duas folhas de jogo e a de sair do speedrun: o mesmo molde.
    final sheets = <String, (Key, Key, Key, Key?)>{
      'desistir': (
        FreeBoardKeys.resignButton,
        FreeBoardKeys.resignSheet,
        FreeBoardKeys.resignConfirmButton,
        FreeBoardKeys.confirmationCancel,
      ),
      'empate': (
        FreeBoardKeys.drawButton,
        FreeBoardKeys.drawSheet,
        FreeBoardKeys.drawConfirmButton,
        FreeBoardKeys.confirmationCancel,
      ),
      'sair': (
        FreeBoardKeys.screen,
        FreeBoardKeys.speedrunQuitSheet,
        FreeBoardKeys.speedrunQuitConfirm,
        FreeBoardKeys.speedrunQuitCancel,
      ),
    };

    Future<void> openSheet(WidgetTester tester, String name, Key opener) async {
      if (name == 'sair') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.ensureVisible(find.byKey(opener));
        await tester.tap(find.byKey(opener));
      }
      await tester.pumpAndSettle();
    }

    for (final MapEntry(key: name, value: keys) in sheets.entries) {
      final (opener, sheetKey, confirmKey, cancelKey) = keys;
      for (final size in const [Size(360, 740), Size(412, 917)]) {
        for (final scale in const [1.0, 2.0]) {
          for (final locale in const [Locale('en'), Locale('ar')]) {
            testWidgets('folha $name $size, fonte $scale, '
                '${locale.languageCode}: alça, X no canto final e dois '
                'botões de 52', (tester) async {
              await pumpStage(tester, size: size, scale: scale, locale: locale);
              await openSheet(tester, name, opener);
              expect(tester.takeException(), isNull);
              final sheet = tester.getRect(find.byKey(sheetKey));
              final close = tester.getRect(
                find.byKey(FreeBoardKeys.confirmationClose),
              );
              // O ✕ padrão das folhas (T73, D7): 48, 20 acima da folha, a 12 da borda.
              expect(close.size, const Size(48, 48));
              expect(sheet.top - close.bottom, closeTo(20, 1));
              if (locale.languageCode == 'ar') {
                expect(close.left, closeTo(12, 1));
              } else {
                expect(close.right, closeTo(size.width - 12, 1));
              }
              expect(
                tester
                    .widget<IconButton>(
                      find.descendant(
                        of: find.byKey(FreeBoardKeys.confirmationClose),
                        matching: find.byType(IconButton),
                      ),
                    )
                    .tooltip,
                isNotEmpty,
              );
              // Os dois botões: pílula, largura toda menos 24 de cada lado,
              // 52 de altura (cresce com a fonte), ao alcance do dedo.
              for (final key in [confirmKey, cancelKey!]) {
                await tester.ensureVisible(find.byKey(key));
                await tester.pumpAndSettle();
                final button = tester.getRect(find.byKey(key));
                expect(find.byKey(key).hitTestable(), findsOneWidget);
                expect(button.width, closeTo(size.width - 48, 1));
                if (scale == 1) {
                  expect(button.height, closeTo(52, 1));
                } else {
                  expect(button.height, greaterThanOrEqualTo(52));
                }
              }
              expect(
                find.descendant(
                  of: find.byKey(cancelKey),
                  matching: find.byType(Text),
                ),
                findsOneWidget,
              );
              expect(
                tester.widget(find.byKey(cancelKey)),
                isA<OutlinedButton>(),
              );
              final gap =
                  tester.getRect(find.byKey(cancelKey)).top -
                  tester.getRect(find.byKey(confirmKey)).bottom;
              expect(gap, closeTo(8, 1));
              // "Continuar jogando" fecha sem fazer nada.
              final fen = cubit.state.position.fen;
              await tester.tap(find.byKey(cancelKey));
              await tester.pumpAndSettle();
              expect(find.byKey(sheetKey), findsNothing);
              expect(cubit.state.end, isNull);
              expect(cubit.state.drawOffer, DrawOffer.none);
              expect(cubit.state.position.fen, fen);
              expect(find.byKey(FreeBoardKeys.screen), findsOneWidget);
              // O X também.
              await openSheet(tester, name, opener);
              final x = tester.getRect(
                find.byKey(FreeBoardKeys.confirmationClose),
              );
              await tester.tapAt(x.center);
              await tester.pumpAndSettle();
              expect(find.byKey(sheetKey), findsNothing);
              expect(cubit.state.end, isNull);
              expect(tester.takeException(), isNull);
            });
          }
        }
      }
    }

    testWidgets('textos das folhas: o nome do personagem no empate e os '
        'botões do canvas', (tester) async {
      await pumpStage(tester, size: const Size(412, 917));
      await tester.ensureVisible(find.byKey(FreeBoardKeys.drawButton));
      await tester.tap(find.byKey(FreeBoardKeys.drawButton));
      await tester.pumpAndSettle();
      expect(find.text('Offer a draw?'), findsOneWidget);
      expect(
        find.text(
          'Valdini can accept or decline. If they decline, the game goes on.',
        ),
        findsOneWidget,
      );
      expect(find.text('Keep playing'), findsOneWidget);
      // O desistir é destrutivo, com a bandeira.
      await tester.tap(find.byKey(FreeBoardKeys.confirmationCancel));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(FreeBoardKeys.resignButton));
      await tester.tap(find.byKey(FreeBoardKeys.resignButton));
      await tester.pumpAndSettle();
      final resign = tester.widget<ButtonStyleButton>(
        find.byKey(FreeBoardKeys.resignConfirmButton),
      );
      final context = tester.element(find.byKey(FreeBoardKeys.resignSheet));
      expect(
        resign.style?.backgroundColor?.resolve({}),
        Theme.of(context).colorScheme.error,
      );
      expect(
        find.descendant(
          of: find.byKey(FreeBoardKeys.resignConfirmButton),
          matching: find.byIcon(Icons.flag_outlined),
        ),
        findsOneWidget,
      );
      expect(find.text('Desistir da partida?'), findsNothing);
      // Confirmar desiste de verdade.
      await tester.tap(find.byKey(FreeBoardKeys.resignConfirmButton));
      await tester.pump();
      expect(cubit.state.end?.reason, GameEndReason.resign);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('em português: "Oferecer empate" e a folha de sair sem '
        'etapas vencidas', (tester) async {
      await pumpStage(
        tester,
        size: const Size(360, 740),
        locale: const Locale('pt'),
      );
      await tester.pump(const Duration(seconds: 20));
      await tester.pumpAndSettle();
      expect(
        textOf(tester, FreeBoardKeys.playerDetail(Side.black)),
        'Nível 1600',
      );
      await tester.ensureVisible(find.byKey(FreeBoardKeys.drawButton));
      await tester.tap(find.byKey(FreeBoardKeys.drawButton));
      await tester.pumpAndSettle();
      expect(find.text('Oferecer empate?'), findsOneWidget);
      expect(find.text('Oferecer empate'), findsOneWidget);
      expect(
        find.text(
          'O Valdini pode aceitar ou recusar. Se recusar, a partida continua.',
        ),
        findsOneWidget,
      );
      expect(find.text('Continuar jogando'), findsOneWidget);
      await tester.tap(find.byKey(FreeBoardKeys.confirmationCancel));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Sair do Clássico?'), findsOneWidget);
      expect(
        find.text('A tentativa termina aqui e fica no histórico.'),
        findsOneWidget,
      );
      expect(
        tester.widget(find.byKey(FreeBoardKeys.speedrunQuitConfirm)),
        isA<FilledButton>(),
      );
      expect(
        find.descendant(
          of: find.byKey(FreeBoardKeys.speedrunQuitConfirm),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
    });

    test('plural da folha de sair com 0, 1 e 3 etapas', () {
      final pt = lookupAppLocalizations(const Locale('pt'));
      final en = lookupAppLocalizations(const Locale('en'));
      expect(
        pt.speedrunQuitHint(0),
        'A tentativa termina aqui e fica no histórico.',
      );
      expect(
        pt.speedrunQuitHint(1),
        'Você perde a etapa vencida desta tentativa.',
      );
      expect(
        pt.speedrunQuitHint(3),
        'Você perde as 3 etapas vencidas desta tentativa.',
      );
      expect(
        en.speedrunQuitHint(0),
        'The attempt ends here and stays in your history.',
      );
      expect(
        en.speedrunQuitHint(1),
        'You lose the stage you won in this attempt.',
      );
      expect(
        en.speedrunQuitHint(3),
        'You lose the 3 stages you won in this attempt.',
      );
    });

    testWidgets('a etapa sobrevive a fechar à força e o rating volta na '
        'faixa', (tester) async {
      await pumpStage(tester, size: const Size(412, 917));
      final saved = games.snapshot;
      expect(saved, isNotNull);
      // Reabre a partida gravada: posição, relógio e linha de detalhe.
      await pumpScreen(
        tester,
        screen: const Size(412, 917) * 2.625,
        systemBars: true,
        saved: saved,
        withReporter: true,
      );
      await cubit.open();
      await talk.settled();
      await tester.pumpAndSettle();
      expect(cubit.state.mode.speedrunAttemptId, 1);
      expect(textOf(tester, FreeBoardKeys.title), 'Classic');
      expect(textOf(tester, FreeBoardKeys.playerDetail(Side.white)), '1150');
      expect(tester.takeException(), isNull);
    });
  });

  group('D11 V2', () {
    const sizes = [
      Size(360, 740),
      Size(360, 800),
      Size(384, 832),
      Size(393, 873),
      Size(412, 915),
      Size(414, 896),
    ];
    const machine = GameMode(
      opponent: OpponentKind.maia,
      level: 1600,
      userSide: Side.white,
      positionId: 'basic.queen.0001',
    );
    // Texto do frame do P2 e fixture longa: nenhuma fala do app é alterada.
    const shortSpeech = 'Ah, não, mano! Que vacilo! Por que eu fiz isso?';
    const longSpeech = '$shortSpeech $shortSpeech $shortSpeech';
    testWidgets('R2 P2: reserva só com fala visível nas seis telas', (
      tester,
    ) async {
      for (final size in sizes) {
        Rect? original;
        int? originalLines;
        for (final text in [shortSpeech, longSpeech, null]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await pumpScreen(
            tester,
            screen: size * 2.625,
            systemInsets: const EdgeInsets.only(top: 52, bottom: 24),
            mode: machine.copyWith(level: 1000),
            characters: _BubbleCharacters(text),
            clock: ClockConfig.same(
              const TimeControl(initial: Duration(minutes: 3)),
            ),
          );
          await talk.settled();
          await tester.pumpAndSettle();
          final board = boardRect(tester);
          expectScreenBoardCenter(tester, board);
          if (size == const Size(360, 740)) {
            expect(board.center.dy, greaterThan(size.height / 2 + .5));
          }
          if (text != null) {
            if (original != null) expect(board, original);
            original = board;
          }
          expect(find.text('Coco'), findsOneWidget);
          if (text == null) {
            expect(find.byKey(FreeBoardKeys.speechBubble), findsNothing);
            final offset = switch (size) {
              Size(width: 360, height: 740) => 38.0,
              Size(width: 360, height: 800) => 8.0,
              Size(width: 384, height: 832) => 4.0,
              _ => 0.0,
            };
            expect(board.center.dy, closeTo(size.height / 2 + offset, .5));
          } else {
            expectSpeechAboveOpponent(tester);
            final summary = tester.widget<TypewriterText>(
              find.descendant(
                of: find.byKey(FreeBoardKeys.speechBubble),
                matching: find.byType(TypewriterText),
              ),
            );
            if (originalLines != null) expect(summary.maxLines, originalLines);
            originalLines = summary.maxLines;
            await tester.pump(const Duration(seconds: 30));
            await tester.pumpAndSettle();
            final expired = boardRect(tester);
            expectScreenBoardCenter(tester, expired);
            expect(expired.width, board.width);
            expect(expired.center.dy, lessThan(board.center.dy));
            expect(
              find.byKey(FreeBoardKeys.speechBubble).hitTestable(),
              findsNothing,
            );
          }
          expect(tester.takeException(), isNull);
        }
      }
      for (final mode in [
        machine,
        machine.copyWith(opponent: OpponentKind.stockfish),
        const GameMode(),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await pumpScreen(
          tester,
          screen: const Size(360, 740) * 2.625,
          systemInsets: const EdgeInsets.only(top: 52, bottom: 24),
          mode: mode,
          appSettings: AppSettings(
            characterTalk: mode.opponent != OpponentKind.maia,
          ),
        );
        await talk.settled();
        await tester.pumpAndSettle();
        expectScreenBoardCenter(tester, boardRect(tester));
        if (mode.opponent != OpponentKind.stockfish) {
          expect(find.byKey(FreeBoardKeys.speechBubble), findsNothing);
        }
        expect(tester.takeException(), isNull);
      }
    });
    for (final size in [const Size(393, 873), const Size(393, 1100)]) {
      testWidgets(
        'R2 P2 $size: fade completo libera centro e nova fala reserva',
        (tester) async {
          await pumpScreen(
            tester,
            locale: const Locale('pt'),
            screen: size * 2.625,
            systemInsets: const EdgeInsets.only(top: 52, bottom: 24),
            mode: machine.copyWith(level: 1000),
            characters: _BubbleCharacters(longSpeech),
            scriptedTalk: true,
            clock: ClockConfig.same(
              const TimeControl(initial: Duration(minutes: 3)),
            ),
          );
          await talk.settled();
          await tester.pumpAndSettle();
          final fixture = talk as _FixtureTalkCubit;
          final line = talk.state.line!;
          final active = boardRect(tester);
          final fen = cubit.state.position.fen;
          final moves = List.of(cubit.state.ucis);
          final history = List.of(cubit.state.moves);
          void expectUnchangedGame() {
            expect(boardRect(tester).width, closeTo(size.width, .01));
            expect(cubit.state.position.fen, fen);
            expect(cubit.state.ucis, moves);
            expect(cubit.state.moves, history);
            expect(tester.takeException(), isNull);
          }

          expectScreenBoardCenter(tester, active);
          expectSpeechAboveOpponent(tester);
          if (size.height == 873) {
            expect(active.center.dy, closeTo(487.5, .01));
            expect(
              tester
                  .widget<TypewriterText>(
                    find.descendant(
                      of: find.byKey(FreeBoardKeys.speechBubble),
                      matching: find.byType(TypewriterText),
                    ),
                  )
                  .maxLines,
              1,
            );
          } else {
            expect(active.center.dy, closeTo(size.height / 2, .01));
          }
          final balloon = find.byKey(FreeBoardKeys.speechBubble);
          final opacity = find
              .ancestor(of: balloon, matching: find.byType(AnimatedOpacity))
              .first;
          final fade = find
              .descendant(of: opacity, matching: find.byType(FadeTransition))
              .first;
          final duration = tester.widget<AnimatedOpacity>(opacity).duration;
          expect(duration, greaterThan(Duration.zero));
          await tester.pump(const Duration(seconds: 30));
          expect(tester.widget<AnimatedOpacity>(opacity).opacity, 0);
          expect(balloon.hitTestable(), findsNothing);
          expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
          expect(boardRect(tester), active);
          await tester.pump(duration ~/ 2);
          expect(
            tester.widget<FadeTransition>(fade).opacity.value,
            allOf(greaterThan(0), lessThan(1)),
          );
          expect(boardRect(tester), active);
          expectScreenBoardCenter(tester, boardRect(tester));
          expectUnchangedGame();
          await tester.pumpAndSettle();
          expect(tester.widget<FadeTransition>(fade).opacity.value, 0);
          expectScreenBoardCenter(
            tester,
            boardRect(tester),
            requireScreenCenter: true,
          );
          expect(boardRect(tester).center.dy, closeTo(size.height / 2, .01));
          expect(talk.state.line, same(line));
          expectUnchangedGame();

          fixture.showLine(
            CharacterLine(
              id: '${line.id}.next',
              category: line.category,
              intensity: line.intensity,
              emotion: line.emotion,
              text: shortSpeech,
            ),
          );
          await tester.pumpAndSettle();
          expectSpeechAboveOpponent(tester);
          expectScreenBoardCenter(tester, boardRect(tester));
          expect(boardRect(tester), active);
          expectUnchangedGame();

          fixture.showLine(null);
          await tester.pumpAndSettle();
          expect(balloon, findsNothing);
          expectScreenBoardCenter(
            tester,
            boardRect(tester),
            requireScreenCenter: true,
          );
          expectUnchangedGame();
          fixture.showLine(line);
          await tester.pumpAndSettle();
          expectSpeechAboveOpponent(tester);
          expect(boardRect(tester), active);
          expectUnchangedGame();
        },
      );
    }

    testWidgets('R2 P2: expirar o balão acima preserva narração em curso', (
      tester,
    ) async {
      final voice = FakeVoiceRepository(
        settings: const VoiceSettings(enabled: true),
      );
      final speech = SpeechCubit(voice);
      addTearDown(speech.close);
      await speech.load();
      await pumpScreen(
        tester,
        locale: const Locale('pt'),
        screen: const Size(360, 740) * 2.625,
        systemInsets: const EdgeInsets.only(top: 52, bottom: 24),
        mode: machine.copyWith(level: 1000),
        characters: _BubbleCharacters(longSpeech),
        speech: speech,
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(minutes: 3)),
        ),
      );
      await talk.settled();
      await tester.pumpAndSettle();
      expect(voice.spoken, isNotEmpty);
      expect(speech.state.speaking, longSpeech);
      expect(
        tester
            .widget<SpeechBalloon>(find.byKey(FreeBoardKeys.speechBubble))
            .tail,
        BalloonTail.down,
      );
      expectSpeechAboveOpponent(tester);
      final board = boardRect(tester);
      final name = tester.getRect(find.text('Coco'));
      final detail = tester.getRect(
        find.byKey(FreeBoardKeys.playerDetail(Side.black)),
      );
      final stops = voice.stops;
      final spoken = voice.spoken.length;
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text('Coco'), findsOneWidget);
      expect(
        find.byKey(FreeBoardKeys.speechBubble).hitTestable(),
        findsNothing,
      );
      final expired = boardRect(tester);
      expectScreenBoardCenter(tester, expired);
      expect(expired.width, board.width);
      final shift = expired.topLeft - board.topLeft;
      expect(tester.getRect(find.text('Coco')), name.shift(shift));
      expect(
        tester.getRect(find.byKey(FreeBoardKeys.playerDetail(Side.black))),
        detail.shift(shift),
      );
      expect(speech.state.speaking, longSpeech);
      expect(voice.stops, stops);
      expect(voice.spoken, hasLength(spoken));
    });
    for (final size in sizes) {
      for (final position in ClockPosition.values) {
        for (final text in [shortSpeech, longSpeech]) {
          testWidgets(
            'R2 P2 $size / $position / ${text.length}: fala acessível '
            'sem interseção e sem deslocar controles',
            (tester) async {
              await pumpScreen(
                tester,
                locale: const Locale('pt'),
                screen: size * 2.625,
                systemInsets: const EdgeInsets.only(top: 52, bottom: 24),
                mode: machine.copyWith(level: 1000),
                characters: _BubbleCharacters(text),
                clock: ClockConfig.same(
                  const TimeControl(initial: Duration(minutes: 3)),
                ),
                clockSettings: ClockSettings(position: position),
              );
              cubit.play(Move.parse('e2e4')!);
              await tester.pumpAndSettle();
              await talk.settled();
              expect(cubit.state.moves, hasLength(2));
              final board = boardRect(tester);
              final actions = tester.getRect(
                find.byKey(FreeBoardKeys.actionsBar),
              );
              final clocks = {
                for (final side in Side.values)
                  side: tester.getRect(find.byKey(FreeBoardKeys.clock(side))),
              };
              final avatar = tester.getRect(find.byType(CharacterAvatar));
              expectScreenBoardCenter(tester, board);
              final balloon = find.byKey(FreeBoardKeys.speechBubble);
              expectSpeechAboveOpponent(tester);
              final name = tester.getRect(find.text('Coco'));
              final detailKey = FreeBoardKeys.playerDetail(Side.black);
              final detail = tester.getRect(find.byKey(detailKey));
              expect(detail.width, greaterThan(0));
              expect(textOf(tester, detailKey), contains('1000'));
              final bubble = tester.getRect(balloon);
              for (final obstacle in [
                board,
                actions,
                avatar,
                ...clocks.values,
                tester.getRect(find.byType(MoveList)),
                tester.getRect(find.byType(AppBar)),
              ]) {
                expect(
                  bubble.overlaps(obstacle),
                  isFalse,
                  reason: '$bubble invade $obstacle',
                );
              }
              expect(balloon.hitTestable(), findsOneWidget);
              expect(
                find.bySemanticsLabel(RegExp(RegExp.escape(text))),
                findsWidgets,
              );
              expect(boardRect(tester), board);
              for (final side in Side.values) {
                expect(
                  tester.getRect(find.byKey(FreeBoardKeys.clock(side))),
                  clocks[side],
                );
              }
              await tester.tap(balloon);
              await tester.pumpAndSettle();
              expect(find.byKey(LessonScriptKeys.speechSheet), findsOneWidget);
              expect(find.text(text, findRichText: true), findsWidgets);
              await tester.tap(find.byKey(LessonScriptKeys.speechSheetClose));
              await tester.pumpAndSettle();
              await tester.pump(const Duration(seconds: 30));
              await tester.pumpAndSettle();
              expect(find.text('Coco'), findsOneWidget);
              expect(balloon.hitTestable(), findsNothing);
              final expired = boardRect(tester);
              expectScreenBoardCenter(tester, expired);
              expect(expired.width, board.width);
              final shift = expired.topLeft - board.topLeft;
              expect(tester.getRect(find.text('Coco')), name.shift(shift));
              expect(
                tester.getRect(find.byKey(detailKey)),
                detail.shift(shift),
              );
              expect(
                tester.getRect(find.byType(CharacterAvatar)),
                avatar.shift(shift),
              );
              final expiredActions = tester.getRect(
                find.byKey(FreeBoardKeys.actionsBar),
              );
              expect(expiredActions.size, actions.size);
              expect(expired.bottom, lessThanOrEqualTo(expiredActions.top));
              for (final side in Side.values) {
                expect(
                  tester.getRect(find.byKey(FreeBoardKeys.clock(side))),
                  clocks[side]!.shift(shift),
                );
              }
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }

    testWidgets('R2 P2: 393×1100 centraliza com largura total e três linhas', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        screen: const Size(393, 1100) * 2.625,
        systemInsets: const EdgeInsets.only(top: 52, bottom: 24),
        mode: machine,
        characters: _BubbleCharacters(longSpeech),
      );
      await talk.settled();
      await tester.pumpAndSettle();
      final board = boardRect(tester);
      expectScreenBoardCenter(tester, board, requireScreenCenter: true);
      expect(board.width, closeTo(393, .5));
      expect(board.center.dy, closeTo(550, .5));
      expectSpeechAboveOpponent(tester);
      expect(
        tester
            .widget<TypewriterText>(
              find.descendant(
                of: find.byKey(FreeBoardKeys.speechBubble),
                matching: find.byType(TypewriterText),
              ),
            )
            .maxLines,
        3,
      );
      final balloon = find.byKey(FreeBoardKeys.speechBubble);
      expect(tester.widget<SpeechBalloon>(balloon).tail, BalloonTail.down);
      final rect = tester.getRect(balloon);
      expect(
        rect.bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(CharacterAvatar)).top),
      );
      expect(
        rect.top,
        greaterThanOrEqualTo(tester.getRect(find.byType(MoveList)).bottom),
      );
      await tester.tap(balloon);
      await tester.pumpAndSettle();
      expect(find.byKey(LessonScriptKeys.speechSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final size in sizes) {
      testWidgets('R2 P2 $size: sem relógio mantém fala acima do adversário', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          screen: size * 2.625,
          systemInsets: const EdgeInsets.only(top: 52, bottom: 24),
          mode: machine.copyWith(level: 1000),
          characters: _BubbleCharacters(longSpeech),
        );
        await talk.settled();
        await tester.pumpAndSettle();
        final balloon = find.byKey(FreeBoardKeys.speechBubble);
        final bubble = tester.getRect(balloon);
        expectSpeechAboveOpponent(tester);
        final board = boardRect(tester);
        expectScreenBoardCenter(tester, board);
        for (final obstacle in [
          board,
          tester.getRect(find.byType(MoveList)),
          tester.getRect(find.byType(CharacterAvatar)),
          tester.getRect(find.byKey(FreeBoardKeys.actionsBar)),
        ]) {
          expect(bubble.overlaps(obstacle), isFalse);
        }
        await tester.tap(balloon);
        await tester.pumpAndSettle();
        expect(find.byKey(LessonScriptKeys.speechSheet), findsOneWidget);
        expect(boardRect(tester), board);
        expect(tester.takeException(), isNull);
      });
    }

    for (final size in sizes) {
      for (final mode in [
        const GameMode(),
        machine,
        machine.copyWith(
          speedrunId: 'queen',
          speedrunAttemptId: 1,
          speedrunStage: 0,
        ),
      ]) {
        testWidgets('$size / $mode: centro da tela e ações inferiores', (
          tester,
        ) async {
          await pumpScreen(
            tester,
            screen: size * 2.625,
            systemBars: true,
            mode: mode,
            clock: mode.opponent.isMachine
                ? ClockConfig.same(
                    const TimeControl(initial: Duration(minutes: 3)),
                  )
                : null,
          );
          await talk.settled();
          await tester.pumpAndSettle();
          final board = boardRect(tester);
          final actions = tester.getRect(find.byKey(FreeBoardKeys.actionsBar));
          final appbar = tester.widget<AppBar>(find.byType(AppBar));
          expect(appbar.actions, isNull);
          expect(appbar.centerTitle, isTrue);
          final appBarRect = tester.getRect(find.byType(AppBar));
          // Centro da imagem, com exceção demonstrável nas telas menores.
          expectScreenBoardCenter(tester, board);
          expect(board.top, greaterThanOrEqualTo(appBarRect.bottom));
          expect(board.bottom, lessThanOrEqualTo(actions.top));
          expect(board.width, closeTo(size.width, .5));
          // Faixas dos jogadores com 68 e o mesmo respiro de 8 até o
          // tabuleiro, em cima e embaixo (PropV2EtapaSpeedrunP360).
          final strips = tester
              .widgetList<ClockRow>(find.byType(ClockRow))
              .map((row) => tester.getRect(find.byWidget(row)))
              .toList();
          expect(strips, hasLength(2));
          final above = strips.firstWhere((r) => r.bottom <= board.top);
          final below = strips.firstWhere((r) => r.top >= board.bottom);
          expect(above.height, closeTo(68, .01));
          expect(below.height, closeTo(68, .01));
          expect(board.top - above.bottom, closeTo(8, .01));
          expect(below.top - board.bottom, closeTo(8, .01));
          final actionKey = mode.opponent.isMachine
              ? FreeBoardKeys.resignButton
              : FreeBoardKeys.flipButton;
          expect(
            tester.getRect(find.byKey(actionKey)).top,
            greaterThanOrEqualTo(actions.top),
          );
          if (mode.opponent.isMachine) {
            final top = tester.getRect(
              find.byKey(FreeBoardKeys.clock(Side.black)),
            );
            final bottom = tester.getRect(
              find.byKey(FreeBoardKeys.clock(Side.white)),
            );
            expect(board.top - top.bottom, closeTo(20, .01));
            expect(bottom.top - board.bottom, closeTo(20, .01));
            final bubble = tester.getRect(
              find.byKey(FreeBoardKeys.speechBubble),
            );
            expect(bubble.overlaps(top), isFalse);
            expect(bubble.overlaps(board), isFalse);
            expect(
              bubble.overlaps(tester.getRect(find.byType(MoveList))),
              isFalse,
            );
            expect(
              find.text(mode.isSpeedrun ? 'Classic' : 'Queen mate'),
              findsOneWidget,
            );
          } else {
            expect(find.byKey(FreeBoardKeys.resignButton), findsNothing);
            expect(find.byKey(FreeBoardKeys.drawButton), findsNothing);
          }
          await tester.ensureVisible(find.byKey(FreeBoardKeys.actionsBar));
          await tester.pumpAndSettle();
          final visibleActions = tester.getRect(
            find.byKey(FreeBoardKeys.actionsBar),
          );
          expect(visibleActions.bottom, closeTo(size.height - 32, .01));
          expect(find.byKey(actionKey).hitTestable(), findsOneWidget);
          expect(boardRect(tester).width, closeTo(size.width, .5));
          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final size in sizes) {
      testWidgets('T72 $size: sem X; o toque no balão abre a fala inteira e a '
          'ponta cai no centro do retrato', (tester) async {
        await pumpScreen(
          tester,
          screen: size * 2.625,
          systemBars: true,
          mode: machine,
          clock: ClockConfig.same(
            const TimeControl(initial: Duration(minutes: 3)),
          ),
        );
        await talk.settled();
        await tester.pumpAndSettle();
        final board = boardRect(tester);
        final balloon = find.byKey(FreeBoardKeys.speechBubble);
        expect(balloon.hitTestable(), findsOneWidget);
        // Nenhum botão de fechar no balão.
        expect(
          find.descendant(of: balloon, matching: find.byType(IconButton)),
          findsNothing,
        );
        expect(
          find.descendant(of: balloon, matching: find.byIcon(Icons.close)),
          findsNothing,
        );
        final rect = tester.getRect(balloon);
        expect(rect.bottom, lessThanOrEqualTo(board.top));
        // A ponta sempre desce: o nome nunca vira conteúdo do balão.
        final shape =
            (tester
                        .widget<CustomPaint>(
                          find.descendant(
                            of: balloon,
                            matching: find.byWidgetPredicate(
                              (w) =>
                                  w is CustomPaint &&
                                  w.painter is BalloonPainter,
                            ),
                          ),
                        )
                        .painter!
                    as BalloonPainter)
                .shape;
        // A ponta é medida na pintura do balão; o vão de 6 fica fora dele.
        final tip = shape.tipOf(
          tester.getRect(
            find.descendant(
              of: balloon,
              matching: find.byWidgetPredicate(
                (w) => w is CustomPaint && w.painter is BalloonPainter,
              ),
            ),
          ),
        );
        final avatar = tester.getRect(
          find.byKey(FreeBoardKeys.characterAvatar(talk.state.emotion)),
        );
        expect(shape.tail, BalloonTail.down);
        expect(tip.dx, closeTo(avatar.center.dx, 2));
        expect(avatar.top - tip.dy, closeTo(6, 0.5));
        expectSpeechAboveOpponent(tester);

        await tester.tap(balloon);
        await tester.pumpAndSettle();
        expect(find.byKey(LessonScriptKeys.speechSheet), findsOneWidget);
        expect(boardRect(tester), board);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'empate exige confirmação; X e toque fora preservam a partida',
      (tester) async {
        await pumpScreen(tester, mode: machine);
        final original = cubit.state.position.fen;
        await tester.ensureVisible(find.byKey(FreeBoardKeys.drawButton));
        await tester.tap(find.byKey(FreeBoardKeys.drawButton));
        await tester.pumpAndSettle();
        expect(find.byKey(FreeBoardKeys.drawSheet), findsOneWidget);
        expect(cubit.state.drawOffer, DrawOffer.none);
        final close = tester.getRect(
          find.byKey(FreeBoardKeys.confirmationClose),
        );
        final sheet = tester.getRect(find.byKey(FreeBoardKeys.drawSheet));
        expect(close.bottom, lessThan(sheet.top));
        await tester.tap(find.byKey(FreeBoardKeys.confirmationClose));
        await tester.pumpAndSettle();
        expect(cubit.state.position.fen, original);
        expect(cubit.state.drawOffer, DrawOffer.none);
        await tester.ensureVisible(find.byKey(FreeBoardKeys.drawButton));
        await tester.tap(find.byKey(FreeBoardKeys.drawButton));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(cubit.state.drawOffer, DrawOffer.none);
        await tester.ensureVisible(find.byKey(FreeBoardKeys.drawButton));
        await tester.tap(find.byKey(FreeBoardKeys.drawButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(FreeBoardKeys.drawConfirmButton));
        await tester.pumpAndSettle();
        expect(find.byKey(FreeBoardKeys.drawSheet), findsNothing);
        expect(cubit.state.drawOffer, isNot(DrawOffer.none));
      },
    );

    testWidgets('X de desistir fica fora da folha e cancela sem perda', (
      tester,
    ) async {
      await pumpScreen(tester, mode: machine);
      await tester.ensureVisible(find.byKey(FreeBoardKeys.resignButton));
      await tester.tap(find.byKey(FreeBoardKeys.resignButton));
      await tester.pumpAndSettle();
      final close = tester.getRect(find.byKey(FreeBoardKeys.confirmationClose));
      final sheet = tester.getRect(find.byKey(FreeBoardKeys.resignSheet));
      expect(close.size, const Size(48, 48));
      expect(close.bottom, lessThan(sheet.top));
      await tester.tap(find.byKey(FreeBoardKeys.confirmationClose));
      await tester.pumpAndSettle();
      expect(cubit.state.end, isNull);
    });
  });

  group('treino', () {
    for (final position in ClockPosition.values) {
      testWidgets(
        'B6b P2: $position preserva nome, avatar único e relógios escolhidos',
        (tester) async {
          await pumpScreen(
            tester,
            screen: const Size(360, 640) * 2.625,
            systemBars: true,
            mode: const GameMode(
              opponent: OpponentKind.maia,
              level: 1600,
              userSide: Side.white,
            ),
            clock: ClockConfig.same(
              const TimeControl(initial: Duration(minutes: 3)),
            ),
            clockSettings: ClockSettings(position: position),
          );
          await talk.settled();
          await tester.pumpAndSettle();
          final board = boardRect(tester);
          final avatar = tester.getRect(find.byType(CharacterAvatar));
          final white = tester.getRect(
            find.byKey(FreeBoardKeys.clock(Side.white)),
          );
          final black = tester.getRect(
            find.byKey(FreeBoardKeys.clock(Side.black)),
          );
          // Nome e detalhe já estão visíveis com o balão aberto.
          expectSpeechAboveOpponent(tester);
          expect(
            textOf(tester, FreeBoardKeys.playerDetail(Side.black)),
            contains('1600'),
          );
          final name = tester.getRect(find.text('Valdini'));
          expect(find.byType(CharacterAvatar), findsOneWidget);
          expect(find.text('Valdini'), findsOneWidget);
          expect(name.width, greaterThan(40));
          expect(avatar.height, 44);
          expect(avatar.center.dy, closeTo(black.center.dy, 1));
          expect(board.width, closeTo(360, .5));
          final appBar = tester.getRect(find.byType(AppBar));
          final actions = tester.getRect(find.byKey(FreeBoardKeys.actionsBar));
          expectScreenBoardCenter(tester, board);
          expect(board.top, greaterThanOrEqualTo(appBar.bottom));
          expect(board.bottom, lessThanOrEqualTo(actions.top));
          if (position == ClockPosition.bottom) {
            expect(avatar.top, greaterThanOrEqualTo(board.bottom));
            expect(white.top, greaterThanOrEqualTo(board.bottom));
            expect(black.top, greaterThanOrEqualTo(board.bottom));
          } else {
            expect(avatar.bottom, lessThanOrEqualTo(board.top));
            expect(black.bottom, lessThanOrEqualTo(board.top));
            if (position == ClockPosition.top) {
              expect(white.bottom, lessThanOrEqualTo(board.top));
            } else {
              expect(white.top, greaterThanOrEqualTo(board.bottom));
            }
          }
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final size in [
      const Size(360, 640),
      const Size(360, 800),
      const Size(412, 915),
    ]) {
      testWidgets(
        'B6b $size: expiração libera reserva e preserva largura da partida',
        (tester) async {
          await pumpScreen(
            tester,
            screen: size * 2.625,
            systemBars: true,
            mode: const GameMode(
              opponent: OpponentKind.maia,
              level: 1600,
              userSide: Side.white,
            ),
            clock: ClockConfig.same(
              const TimeControl(initial: Duration(minutes: 3)),
            ),
          );
          await talk.settled();
          await tester.pumpAndSettle();
          final board = boardRect(tester);
          final appBar = tester.getRect(find.byType(AppBar));
          final actions = tester.getRect(find.byKey(FreeBoardKeys.actionsBar));
          expectScreenBoardCenter(tester, board);
          expect(board.top, greaterThanOrEqualTo(appBar.bottom));
          expect(board.bottom, lessThanOrEqualTo(actions.top));
          expect(board.width, closeTo(size.width, .5));
          expect(find.byKey(FreeBoardKeys.speechBubble), findsOneWidget);
          await tester.pump(const Duration(seconds: 20));
          await tester.pumpAndSettle();
          expectScreenBoardCenter(tester, boardRect(tester));
          expect(boardRect(tester).width, board.width);
          opponent.hold();
          await move(tester, 'e2', 'e4');
          await talk.settled();
          await tester.pumpAndSettle();
          expectScreenBoardCenter(tester, boardRect(tester));
          expect(boardRect(tester).width, board.width);
          expect(tester.takeException(), isNull);
        },
      );
    }

    const vsMachine = GameMode(
      opponent: OpponentKind.stockfish,
      userSide: Side.white,
      goal: PositionGoal.win,
      positionId: 'basic.queen.0001',
    );

    testWidgets('a barra de cima fica só com os botões', (tester) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine,
        locale: const Locale('pt'),
      );

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Ganhar')),
        findsNothing,
      );
    });

    /// Desiste e espera a troca para a conclusão.
    Future<void> resign(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(FreeBoardKeys.resignButton));
      await tester.tap(find.byKey(FreeBoardKeys.resignButton));
      await tester.pumpAndSettle();
      expect(find.byKey(FreeBoardKeys.resignSheet), findsOneWidget);
      await tester.tap(find.byKey(FreeBoardKeys.resignConfirmButton));
      await tester.pump();
      // Os oráculos seguintes medem o estado inicial da viewport.
      Scrollable.of(tester.element(find.byKey(FreeBoardKeys.board))).position
          .jumpTo(0);
      await tester.pump();
    }

    testWidgets('desistir pede confirmação; o resultado aparece em destaque e '
        'a conclusão da partida gravada abre no lugar da partida', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine,
        withReporter: true,
      );

      await resign(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(textOf(tester, FreeBoardKeys.endFlash), 'You lost');
      // Nem o cartão nem o painel do fim: a partida acabou.
      expect(find.byKey(FreeBoardKeys.endPanel), findsNothing);

      // O fim para no tabuleiro: nada avança sozinho.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.byType(FreeBoardScreen), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.seeResultButton), findsOneWidget);
      // Desistir e empate saíram do rodapé.
      expect(find.byKey(FreeBoardKeys.resignButton), findsNothing);
      expect(find.byKey(FreeBoardKeys.drawButton), findsNothing);
      await tester.ensureVisible(find.byKey(FreeBoardKeys.seeResultButton));
      await tester.tap(find.byKey(FreeBoardKeys.seeResultButton));
      await tester.pumpAndSettle();
      final id = await cubit.savedGameId();
      expect(find.text('conclusion $id'), findsOneWidget);
      expect(find.byType(FreeBoardScreen), findsNothing);
      expect(progress.attempts.single.fulfilled, isFalse);
      expect(progress.attempts.single.endReason, GameEndReason.resign);
    });

    testWidgets(
      'desafio de link conserva o motivo de tempo depois do selo inicial',
      (tester) async {
        await pumpScreen(
          tester,
          mode: vsMachine.copyWith(fromLink: true),
          clock: ClockConfig.same(
            const TimeControl(initial: Duration(seconds: 5)),
          ),
        );
        now.advance(const Duration(seconds: 5));
        cubit.tick();
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
        expect(find.text('Time out'), findsOneWidget);
        expect(find.text('You lost'), findsOneWidget);
      },
    );

    for (final size in const [
      Size(360, 740),
      Size(360, 800),
      Size(384, 832),
      Size(393, 873),
      Size(412, 915),
      Size(414, 896),
    ]) {
      testWidgets('resultado de link centrado e ações em uma linha em $size', (
        tester,
      ) async {
        await Goldens.loadFonts();
        await pumpScreen(
          tester,
          locale: const Locale('pt'),
          screen: Size(size.width * 2.625, size.height * 2.625),
          systemBars: true,
          fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
          mode: vsMachine.copyWith(fromLink: true),
        );
        await resign(tester);
        await tester.pumpAndSettle();
        final board = tester.getRect(find.byKey(FreeBoardKeys.board));
        expectScreenBoardCenter(tester, board);
        expect(
          tester.getSize(find.text('Compartilhar')).height,
          lessThanOrEqualTo(24),
        );
        expect(
          tester.getSize(find.text('Jogar de novo')).height,
          lessThanOrEqualTo(24),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('desafio de link sem rating ainda: "No rating" no lugar do '
        'número', (tester) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine.copyWith(fromLink: true),
      );
      expect(
        textOf(tester, FreeBoardKeys.playerDetail(Side.white)),
        'No rating',
      );
    });

    testWidgets('desafio de link: o fim oferece jogar de novo, compartilhar '
        'e conhecer o app, no lugar de "Ver o resultado"', (tester) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine.copyWith(fromLink: true),
        withReporter: true,
      );
      expect(find.byKey(ChallengeKeys.endShare), findsNothing);

      await resign(tester);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.byKey(FreeBoardKeys.seeResultButton), findsNothing);
      expect(find.byKey(ChallengeKeys.endPlayAgain), findsOneWidget);
      expect(find.byKey(ChallengeKeys.endShare), findsOneWidget);
      expect(find.byKey(ChallengeKeys.endMeetApp), findsOneWidget);
      expect(cubit.state.challengeResult?.outcome, AttemptOutcome.loss);
      expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
      expect(find.text('You lost'), findsOneWidget);
      expect(find.text('Resignation'), findsOneWidget);

      await tester.ensureVisible(find.byKey(ChallengeKeys.endPlayAgain));
      await tester.tap(find.byKey(ChallengeKeys.endPlayAgain));
      await tester.pumpAndSettle();
      expect(cubit.state.end, isNull);
      expect(find.byKey(ChallengeKeys.endPlayAgain), findsNothing);
    });

    testWidgets(
      'posição sem histórico (personalizada): a conclusão vai pronta',
      (tester) async {
        await pumpScreen(
          tester,
          fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
          mode: const GameMode(
            opponent: OpponentKind.stockfish,
            userSide: Side.white,
          ),
        );

        await resign(tester);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(FreeBoardKeys.seeResultButton));
        await tester.tap(find.byKey(FreeBoardKeys.seeResultButton));
        await tester.pumpAndSettle();
        expect(find.text('conclusion lost'), findsOneWidget);
        expect(progress.attempts, isEmpty);
      },
    );

    for (final method in [MoveMethod.drag, MoveMethod.tap]) {
      testWidgets('360×640: $method joga c1c2 com rolagem externa', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          screen: const Size(360, 640) * 2.625,
          systemBars: true,
          fen: '7k/8/8/8/8/8/8/2Q4K w - - 0 1',
          board: BoardSettings(moveMethod: method),
          mode: vsMachine,
          clock: ClockConfig.same(
            const TimeControl(initial: Duration(minutes: 3)),
          ),
        );
        final initialBoard = boardRect(tester);
        expectScreenBoardCenter(tester, initialBoard);
        final actions = find.byKey(FreeBoardKeys.actionsBar);
        expect(tester.getRect(actions).bottom, greaterThan(640 - 32));
        await tester.ensureVisible(actions);
        await tester.pumpAndSettle();
        expect(tester.getRect(actions).bottom, closeTo(640 - 32, .5));
        expect(
          find.byKey(FreeBoardKeys.resignButton).hitTestable(),
          findsOneWidget,
        );
        expect(boardRect(tester).width, closeTo(360, .5));
        await tester.ensureVisible(find.byKey(FreeBoardKeys.board));
        await tester.pumpAndSettle();
        final beforeMove = boardRect(tester);
        final scrollable = Scrollable.of(
          tester.element(find.byKey(FreeBoardKeys.board)),
        );
        final offset = scrollable.position.pixels;
        opponent.hold();
        if (method == MoveMethod.drag) {
          await drag(tester, 'c1', 'c2');
        } else {
          await move(tester, 'c1', 'c2');
        }
        expect(cubit.state.moves, ['Qc2']);
        expect(scrollable.position.pixels, closeTo(offset, .01));
        expect(boardRect(tester), beforeMove);
        expect(boardRect(tester).width, closeTo(360, .5));
        expect(tester.takeException(), isNull);
        opponent.release();
        await tester.pumpAndSettle();
      });
    }

    testWidgets('celular pequeno: tabuleiro utilizável e avatar legível', (
      tester,
    ) async {
      // 360 x 640, com o relógio dos lados e o personagem.
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1600),
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(minutes: 3)),
        ),
        screen: const Size(720, 1280),
        withReporter: true,
      );
      tester.view.devicePixelRatio = 2;
      await tester.pumpAndSettle();
      await talk.settled();
      await tester.pumpAndSettle();

      expect(boardRect(tester).width, closeTo(360, .5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('celular baixo: largura total, personagens e relógios íntegros, e arrastar '
        'uma peça joga o lance', (tester) async {
      // Personagem, dois relógios e o tabuleiro em 360 x 533.
      await pumpScreen(
        tester,
        fen: '2Q5/8/8/8/2K5/8/8/5k2 w - - 0 1',
        mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1600),
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(minutes: 3)),
        ),
        board: const BoardSettings(moveMethod: MoveMethod.drag),
        // 360 x 533 na densidade do teste.
        screen: const Size(945, 1400),
      );
      final board = boardRect(tester);
      final appBar = tester.getRect(find.byType(AppBar));
      final area = tester.getRect(find.byKey(FreeBoardKeys.scrollArea));
      expect(appBar.bottom, area.top);
      final actions = tester.getRect(find.byKey(FreeBoardKeys.actionsBar));
      expectScreenBoardCenter(tester, board);
      expect(board.bottom, lessThanOrEqualTo(actions.top));
      expect(
        tester.getRect(find.byKey(FreeBoardKeys.characterBar)).bottom,
        lessThanOrEqualTo(board.top + 0.5),
      );
      expect(
        tester.getRect(find.byKey(FreeBoardKeys.clock(Side.white))).top,
        greaterThanOrEqualTo(board.bottom - 0.5),
      );
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.byKey(FreeBoardKeys.board));
      await tester.pumpAndSettle();
      final visibleBoard = boardRect(tester);
      opponent.hold();
      final gesture = await tester.startGesture(
        squareCenter(visibleBoard, 'c8'),
      );
      await tester.pump();
      for (var step = 1; step <= 6; step++) {
        await gesture.moveBy(
          (squareCenter(visibleBoard, 'g4') -
                  squareCenter(visibleBoard, 'c8')) /
              6,
        );
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(cubit.state.moves, ['Qg4']);
      expect(boardRect(tester), visibleBoard);
      opponent.release();
    });

    testWidgets('fechar o painel de desistir não muda nada', (tester) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine,
      );

      await tester.ensureVisible(find.byKey(FreeBoardKeys.resignButton));
      await tester.tap(find.byKey(FreeBoardKeys.resignButton));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(cubit.state.end, isNull);
    });

    testWidgets('mate na posição de ganhar: objetivo cumprido', (tester) async {
      await pumpScreen(
        tester,
        fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
        mode: vsMachine,
      );

      await moveNow(tester, 'h1', 'h8');
      expect(textOf(tester, FreeBoardKeys.endFlash), 'You won!');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.byType(FreeBoardScreen), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.resignButton), findsNothing);

      await tester.ensureVisible(find.byKey(FreeBoardKeys.seeResultButton));
      await tester.tap(find.byKey(FreeBoardKeys.seeResultButton));
      await tester.pumpAndSettle();
      expect(progress.attempts.single.fulfilled, isTrue);
      expect(find.textContaining('conclusion'), findsOneWidget);
    });

    testWidgets('o selo entra e mantém resultado e motivo após seis segundos', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
        mode: vsMachine,
      );
      await moveNow(tester, 'h1', 'h8');
      double opacity() => tester
          .widget<Opacity>(
            find.ancestor(
              of: find.byKey(FreeBoardKeys.endFlash),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;
      expect(opacity(), lessThan(1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(opacity(), 1);
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.seeResultButton), findsOneWidget);
      expect(find.text('Checkmate'), findsOneWidget);
    });

    testWidgets('final em destaque: resultado permanece após seis segundos', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
        mode: vsMachine.copyWith(featuredId: 'carlsen-so-2017'),
      );
      await moveNow(tester, 'h1', 'h8');
      expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
      await tester.pump(AppMotion.featuredFlash ~/ 2);
      expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
    });

    testWidgets(
      'afogamento: resultado e motivo permanecem após seis segundos',
      (tester) async {
        await pumpScreen(
          tester,
          fen: 'k7/8/1K6/8/8/8/2Q5/8 w - - 0 1',
          mode: vsMachine,
        );
        await moveNow(tester, 'c2', 'c7');
        expect(textOf(tester, FreeBoardKeys.endFlash), 'Draw');
        expect(find.text('Stalemate'), findsOneWidget);
        await tester.pump(const Duration(seconds: 6));
        expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
      },
    );

    testWidgets('abrir partida já terminada preserva resultado e motivo', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        fen: '3k3Q/8/3K4/8/8/8/8/8 b - - 0 1',
        mode: vsMachine,
      );
      expect(cubit.state.end, isNotNull);
      expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
    });

    testWidgets('o selo é região viva com o texto do resultado', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(
        tester,
        fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
        mode: vsMachine,
      );
      await moveNow(tester, 'h1', 'h8');
      final data = tester
          .getSemantics(
            find
                .ancestor(
                  of: find.byKey(FreeBoardKeys.endFlash),
                  matching: find.byType(Semantics),
                )
                .first,
          )
          .getSemanticsData();
      expect(data.flagsCollection.isLiveRegion, isTrue);
      expect(data.label, 'You won!. Checkmate');
      handle.dispose();
    });

    testWidgets('Maratona vencida: a pausa entre etapas é de 1,6 s', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
        mode: vsMachine.copyWith(
          opponent: OpponentKind.maia,
          level: 1000,
          positionId: null,
          speedrunId: 'marathon.queen',
          speedrunAttemptId: 1,
          speedrunStage: 0,
        ),
      );
      await moveNow(tester, 'h1', 'h8');
      await tester.pump(const Duration(milliseconds: 1400));
      expect(find.byType(FreeBoardScreen), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byType(FreeBoardScreen), findsNothing);
    });

    testWidgets('reduzir movimento: só fade, sem escala', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpScreen(
        tester,
        fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
        mode: vsMachine,
      );
      await moveNow(tester, 'h1', 'h8');
      await tester.pump(const Duration(milliseconds: 25));
      expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
      final scale = tester.widget<Transform>(
        find
            .ancestor(
              of: find.byKey(FreeBoardKeys.endFlash),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(scale.transform.getMaxScaleOnAxis(), 1);
      await tester.pump(const Duration(seconds: 6));
      expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
    });

    for (final size in [const Size(360, 740), const Size(412, 917)]) {
      testWidgets(
        '$size: Ver o resultado com 16 dp de margem (CompRodapeAcoes)',
        (tester) async {
          await pumpScreen(
            tester,
            fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
            mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1000),
            clock: ClockConfig.same(
              const TimeControl(initial: Duration(minutes: 5)),
            ),
            screen: size * 2.625,
          );
          await moveNow(tester, 'h1', 'h8');
          final button = tester.getRect(
            find.byKey(FreeBoardKeys.seeResultButton),
          );
          expect(button.left, closeTo(16, 1));
          expect(button.width, closeTo(size.width - 32, 1));
          expect(button.height, closeTo(52, 1));
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('fim com relógio: nenhum relógio fica ativo e o selo e o '
        'botão estão no tabuleiro, em 360x740 com fonte 2,0', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpScreen(
        tester,
        fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
        mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1000),
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(minutes: 5)),
        ),
        screen: const Size(360 * 2.625, 740 * 2.625),
      );

      await moveNow(tester, 'h1', 'h8');
      expect(cubit.state.end, isNotNull);
      final seal = tester.getRect(find.byKey(FreeBoardKeys.endFlash));
      final board = boardRect(tester);
      expect(
        (seal.center - board.center).distance,
        lessThan(24),
        reason: 'o selo fica sobre o tabuleiro',
      );
      final button = tester.getRect(find.byKey(FreeBoardKeys.seeResultButton));
      expect(button.height, greaterThanOrEqualTo(48));
      // O balão do personagem fechou.
      expect(find.byKey(FreeBoardKeys.speechBubble), findsNothing);
      for (final side in [Side.white, Side.black]) {
        final clockWidget = tester.widget<GameClock>(
          find.byKey(FreeBoardKeys.clock(side)),
        );
        expect(clockWidget.running, isFalse, reason: '$side');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a máquina responde e o jogador não move as peças dela', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine,
      );

      await move(tester, 'c1', 'g5');
      await tester.pumpAndSettle();

      expect(cubit.state.moves, hasLength(2));
      expect(cubit.state.position.turn, Side.white);
    });
    testWidgets('contra o Maia, o lado dele leva o nome e o nível', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1400),
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(minutes: 3)),
        ),
      );

      expect(find.text('Maia 1400'), findsOneWidget);
      // O lado do jogador leva o apelido (o de fábrica, sem apelido).
      expect(find.text('Player'), findsOneWidget);
      expect(find.text('White'), findsNothing);
      expect(find.text('Black'), findsNothing);
    });

    testWidgets('contra um personagem: retrato e relógio na mesma linha, '
        'balão em overlay sem deslocar o tabuleiro', (tester) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1600),
        clock: ClockConfig.same(
          const TimeControl(initial: Duration(minutes: 3)),
        ),
      );
      await talk.settled();
      await tester.pumpAndSettle();

      expect(find.byKey(FreeBoardKeys.characterBar), findsOneWidget);
      // O retrato fica só em cima, com o nome para o leitor de tela.
      expect(find.byType(CharacterAvatar), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Valdini(?:\n|$)')),
        findsOneWidget,
      );
      expect(
        find.byKey(FreeBoardKeys.speechText('magician.gameStart.1')),
        findsOneWidget,
      );
      final bar = tester.getRect(find.byKey(FreeBoardKeys.characterBar));
      // O relógio e o retrato compartilham a linha acima do tabuleiro.
      final clock = tester.getRect(find.byKey(FreeBoardKeys.clock(Side.black)));
      final board = boardRect(tester);
      expect(clock.top, greaterThanOrEqualTo(bar.top));
      expect(clock.bottom, lessThanOrEqualTo(bar.bottom));
      expect(clock.bottom, lessThanOrEqualTo(board.top));
      final bubble = tester.getRect(find.byKey(FreeBoardKeys.speechBubble));
      expect(bubble.overlaps(clock), isFalse);
      expect(
        bubble.overlaps(tester.getRect(find.byType(CharacterAvatar))),
        isFalse,
      );
      expect(bubble.overlaps(tester.getRect(find.byType(MoveList))), isFalse);
      expect(bubble.bottom, lessThanOrEqualTo(board.top));
      await tester.pump(const Duration(seconds: 20));
      await tester.pumpAndSettle();
      final expired = boardRect(tester);
      expect(expired.width, board.width);
      final expiredClock = tester.getRect(
        find.byKey(FreeBoardKeys.clock(Side.black)),
      );
      // O avatar permanece legível e alinhado ao relógio.
      final avatar = tester.getRect(find.byType(CharacterAvatar));
      expect(avatar.height, 44);
      expect(avatar.center.dy, closeTo(expiredClock.center.dy, 1));
      // A largura total é preservada; o centro só desce o necessário.
      expectScreenBoardCenter(tester, expired);
    });

    testWidgets('com as falas desligadas, o balão não aparece', (tester) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1600),
        appSettings: const AppSettings(characterTalk: false),
      );
      await talk.settled();
      await tester.pumpAndSettle();

      expect(find.byKey(FreeBoardKeys.characterBar), findsOneWidget);
      expect(find.byKey(FreeBoardKeys.speechBubble), findsNothing);
      expectScreenBoardCenter(tester, boardRect(tester));
    });

    testWidgets('contra a máquina sem relógio, a linha de cada lado diz de '
        'quem é a vez, sem o "pensando"', (tester) async {
      await pumpScreen(
        tester,
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1400),
      );
      opponent.hold();

      // A vez do jogador, na linha dele, embaixo do tabuleiro.
      expectRing(tester);
      expect(
        tester.getCenter(find.byKey(FreeBoardKeys.turn)).dy,
        greaterThan(boardRect(tester).bottom),
      );
      await move(tester, 'c1', 'g5');
      await tester.pump();

      // A vez da máquina, na linha dela, em cima do tabuleiro.
      expectRing(tester);
      expect(
        tester.getCenter(find.byKey(FreeBoardKeys.turn)).dy,
        lessThan(boardRect(tester).top),
      );

      expect(find.byKey(FreeBoardKeys.machineThinking), findsNothing);
      expect(find.text('Maia 1400 is thinking…'), findsNothing);
      opponent.release();
      await tester.pumpAndSettle();
    });
  });
  group('Final do dia na partida', () {
    const daily = GameMode(
      opponent: OpponentKind.stockfish,
      userSide: Side.white,
      positionId: 'basic.queen.0001',
      dailyDate: '2026-10-26',
      goal: PositionGoal.win,
    );

    testWidgets('a meta aparece antes do primeiro lance', (tester) async {
      await pumpScreen(
        tester,
        locale: const Locale('pt'),
        mode: daily,
        fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
      );
      expect(cubit.state.ucis, isEmpty);
      expect(textOf(tester, DailyKeys.goalSubtitle), 'Brancas jogam e ganham');
    });

    testWidgets('empate: "e empatam"', (tester) async {
      await pumpScreen(
        tester,
        locale: const Locale('pt'),
        mode: daily.copyWith(goal: PositionGoal.draw, userSide: Side.black),
        fen: '3k4/8/3K4/8/8/8/8/7Q b - - 0 1',
      );
      expect(textOf(tester, DailyKeys.goalSubtitle), 'Pretas jogam e empatam');
    });

    testWidgets('o jogador mostra o rating, não "Sem rating"', (tester) async {
      await pumpScreen(
        tester,
        locale: const Locale('pt'),
        mode: daily,
        fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
        withReporter: true,
      );
      await cubit.open();
      await tester.pumpAndSettle();
      final detail = textOf(tester, FreeBoardKeys.playerDetail(Side.white));
      expect(detail, isNot('Sem rating'));
      expect(int.tryParse(detail), isNotNull);
    });
  });
  group('Resultado persistente por modo e motivo', () {
    const machine = GameMode(
      opponent: OpponentKind.stockfish,
      userSide: Side.white,
      positionId: 'basic.queen.0001',
    );
    final modes = {
      'comum': machine,
      'Jornada': machine.copyWith(challengeId: 'queen.1'),
      'diário': machine.copyWith(dailyDate: '2026-10-26'),
      'Clássico': machine.copyWith(
        speedrunId: 'queen',
        speedrunAttemptId: 1,
        speedrunStage: 0,
      ),
      'Maratona': machine.copyWith(
        speedrunId: 'marathon.queen',
        speedrunAttemptId: 1,
        speedrunStage: 0,
      ),
    };
    for (final entry in modes.entries) {
      for (final reason in [
        GameEndReason.resign,
        GameEndReason.timeout,
        GameEndReason.checkmate,
      ]) {
        // A vitória da Maratona tem seu teste específico de autoavanço.
        if (entry.key == 'Maratona' && reason == GameEndReason.checkmate) {
          continue;
        }
        testWidgets('${entry.key}: $reason persiste após seis segundos', (
          tester,
        ) async {
          await pumpScreen(
            tester,
            locale: const Locale('pt'),
            mode: entry.value,
            fen: reason == GameEndReason.timeout
                ? 'r2k4/8/3K4/8/8/8/8/7Q w - - 0 1'
                : '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
            clock: reason == GameEndReason.timeout
                ? ClockConfig.same(
                    const TimeControl(initial: Duration(seconds: 1)),
                  )
                : null,
          );
          if (reason == GameEndReason.resign) {
            cubit.resign();
          } else if (reason == GameEndReason.timeout) {
            now.advance(const Duration(seconds: 2));
            await tester.pump(const Duration(seconds: 2));
          } else {
            await moveNow(tester, 'h1', 'h8');
          }
          await tester.pump();
          await tester.pump(const Duration(seconds: 6));
          await tester.pumpAndSettle();
          expect(cubit.state.end?.reason, reason);
          expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
          final l10n = lookupAppLocalizations(const Locale('pt'));
          final label = switch (reason) {
            GameEndReason.resign => l10n.gameResigned,
            GameEndReason.timeout => l10n.freeBoardTimeout,
            _ => l10n.freeBoardCheckmate,
          };
          expect(
            find.descendant(
              of: find.byKey(FreeBoardKeys.endFlash),
              matching: find.text(label),
            ),
            findsOneWidget,
          );
          expect(find.byType(FreeBoardScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
    for (final marathon in [false, true]) {
      testWidgets('nome contextual no título e na saída: $marathon', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          locale: const Locale('pt'),
          mode: modes[marathon ? 'Maratona' : 'Clássico']!,
          fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
        );
        expect(
          textOf(tester, FreeBoardKeys.title),
          marathon ? 'Maratona' : 'Clássico',
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.text(marathon ? 'Sair da Maratona?' : 'Sair do Clássico?'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(FreeBoardKeys.speedrunQuitCancel));
        await tester.pumpAndSettle();
        expect(cubit.state.end, isNull);
      });
    }
  });
  group('Centro do tabuleiro na imagem inteira da tela', () {
    const machine = GameMode(
      opponent: OpponentKind.maia,
      level: 1600,
      userSide: Side.white,
      positionId: 'basic.queen.0001',
    );
    final modes = <String, GameMode>{
      'Partida': machine,
      'Speedrun': machine.copyWith(
        speedrunId: 'queen',
        speedrunAttemptId: 1,
        speedrunStage: 0,
      ),
      'Maratona': machine.copyWith(
        speedrunId: 'marathon.queen',
        speedrunAttemptId: 1,
        speedrunStage: 0,
      ),
    };
    for (final size in const [
      Size(360, 740),
      Size(360, 800),
      Size(384, 832),
      Size(393, 873),
      Size(412, 915),
      Size(414, 896),
    ]) {
      for (final insets in const [
        EdgeInsets.zero,
        EdgeInsets.only(top: 24, bottom: 32),
        EdgeInsets.only(top: 32, bottom: 24),
      ]) {
        for (final entry in modes.entries) {
          for (final ended in [false, true]) {
            testWidgets(
              '${entry.key} em $size $insets, ${ended ? 'fim' : 'jogando'}',
              (tester) async {
                await Goldens.loadFonts();
                await pumpScreen(
                  tester,
                  locale: const Locale('pt'),
                  fen: '3k4/8/3K4/8/8/8/8/7Q w - - 0 1',
                  screen: size * 2.625,
                  systemInsets: insets,
                  mode: entry.value,
                  withReporter: true,
                  clock: ClockConfig.same(
                    const TimeControl(initial: Duration(minutes: 3)),
                  ),
                );
                await cubit.open();
                await talk.settled();
                await tester.pumpAndSettle();
                if (ended) {
                  cubit.resign();
                  await tester.pump();
                  await tester.pump(const Duration(seconds: 6));
                  await tester.pumpAndSettle();
                  expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
                  expect(find.text('Desistência'), findsOneWidget);
                  expect(cubit.state.end, isNotNull);
                  expect(
                    find.byKey(FreeBoardKeys.seeResultButton),
                    findsOneWidget,
                  );
                  final button = tester.getRect(
                    find.byKey(FreeBoardKeys.seeResultButton),
                  );
                  expect(button.height, closeTo(52, 1));
                  // A seta vem antes do texto (CompBotao).
                  final arrow = tester.getRect(
                    find.byIcon(Icons.arrow_forward),
                  );
                  final label = tester.getRect(find.text('Ver o resultado'));
                  expect(arrow.right, lessThanOrEqualTo(label.left));
                }
                final board = boardRect(tester);
                expect(
                  board.top,
                  greaterThanOrEqualTo(
                    tester.getRect(find.byType(AppBar)).bottom,
                  ),
                );
                final footerTop = tester
                    .getRect(
                      find.byKey(
                        ended
                            ? FreeBoardKeys.seeResultButton
                            : FreeBoardKeys.actionsBar,
                      ),
                    )
                    .top;
                expect(board.bottom, lessThanOrEqualTo(footerTop));
                expectScreenBoardCenter(tester, board);
                expect(tester.takeException(), isNull);
              },
            );
          }
        }
      }
    }
  });
}

// Global logical pixels; no BoardViewport/BoardCentering configuration is read.
void expectScreenBoardCenter(
  WidgetTester tester,
  Rect board, {
  bool requireScreenCenter = false,
}) {
  final view = tester.view;
  final ratio = view.devicePixelRatio;
  final width = view.physicalSize.width / ratio;
  final height = view.physicalSize.height / ratio;
  final center = height / 2;
  final context = tester.element(find.byType(FreeBoardScreen));
  final game = context.read<FreeBoardCubit>().state;
  final settings = context.read<SettingsCubit>().state!;
  final talk = context.read<TalkCubit>().state;
  final balloon = find.byKey(FreeBoardKeys.speechBubble);
  // Inspect the rendered fade, not merely the persisted line: IgnorePointer
  // already ignores taps while the balloon is still fading out.
  final fades = find.ancestor(
    of: balloon,
    matching: find.byType(FadeTransition),
  );
  final visible =
      balloon.evaluate().isNotEmpty &&
      fades.evaluate().every(
        (element) => (element.widget as FadeTransition).opacity.value > 0,
      );
  final reservesSpeech =
      game.mode.opponent == OpponentKind.maia &&
      settings.characterTalk &&
      talk.enabled &&
      talk.line != null &&
      visible;
  expect(board.width, closeTo(board.height, .01));
  expect(board.width, closeTo(width, .5));
  expect(board.center.dx, closeTo(width / 2, .5));
  final contentTop = tester.getRect(find.byType(MoveList)).bottom;
  final footer = find.byKey(FreeBoardKeys.actionsBar);
  expect(board.top, greaterThanOrEqualTo(contentTop));
  if (footer.evaluate().isNotEmpty) {
    expect(board.bottom, lessThanOrEqualTo(tester.getRect(footer).top));
  }
  final clocks = game.clock == null
      ? ClockPosition.sides
      : settings.clock.position;
  final above = clocks == ClockPosition.bottom ? 0.0 : 68.0;
  var topExtent = above > 0 ? above + 8 : 0.0;
  var lines = 3;
  // Select the largest summary fitting above a full-width board at h/2.
  // The footer can scroll; its position never reduces the board or summary.
  // Active short/long utterances share geometry; null/expired reserve nothing.
  for (; reservesSpeech && lines >= 1; lines--) {
    final text = TextPainter(
      text: TextSpan(
        text: List.filled(lines, 'M').join('\n'),
        style: Theme.of(context).textTheme.bodyLarge!
            .copyWith(fontSize: 15, height: 1.5),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final speechRoom = text.height + 32 + 16 + 4;
    text.dispose();
    final topReserve =
        above +
        (clocks == ClockPosition.bottom ? speechRoom + 4 : speechRoom - 12);
    topExtent = topReserve + 8;
    if (center - width / 2 >= contentTop + topExtent || lines == 1) break;
  }
  if (reservesSpeech) {
    final summary = find.descendant(
      of: balloon,
      matching: find.byType(TypewriterText),
    );
    expect(tester.widget<TypewriterText>(summary).maxLines, lines);
  }
  final expectedCenter = max(center, contentTop + topExtent + width / 2);
  expect(board.center.dy, closeTo(expectedCenter, .5));
  if (requireScreenCenter) expect(board.center.dy, closeTo(center, .5));
  if (reservesSpeech && expectedCenter > center) {
    expect(lines, 1);
    expect(board.top, closeTo(contentTop + topExtent, .5));
  }
}

void expectSpeechAboveOpponent(WidgetTester tester) {
  final balloon = find.byKey(FreeBoardKeys.speechBubble);
  expect(balloon.hitTestable(), findsOneWidget);
  final widget = tester.widget<SpeechBalloon>(balloon);
  expect(widget.tail, BalloonTail.down);
  expect(widget.padding, const EdgeInsetsDirectional.all(16));
  final bubble = tester.getRect(balloon);
  final board = tester.getRect(find.byKey(FreeBoardKeys.board));
  final avatar = tester.getRect(find.byType(CharacterAvatar));
  expect(bubble.bottom, lessThanOrEqualTo(min(board.top, avatar.top)));
  expect(
    bubble.top - 4,
    greaterThanOrEqualTo(tester.getRect(find.byType(MoveList)).bottom - .5),
  );
  expect(bubble.left, greaterThanOrEqualTo(0));
  expect(
    bubble.right,
    lessThanOrEqualTo(
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
    ),
  );
  for (final clock in find.byType(GameClock).evaluate()) {
    expect(
      bubble.overlaps(tester.getRect(find.byWidget(clock.widget))),
      isFalse,
    );
  }
  final text = tester.widget<TypewriterText>(
    find.descendant(of: balloon, matching: find.byType(TypewriterText)),
  );
  expect(text.maxLines, inInclusiveRange(1, 3));
  expect(text.shrink, isFalse);
  expect(text.style?.fontSize, 15);
  expect(text.style?.height, 1.5);
}

// Real TalkCubit initialization/persistence, with deterministic speech events
// that do not need a chess move or an engine evaluation.
class _FixtureTalkCubit extends TalkCubit {
  _FixtureTalkCubit({
    required super.characters,
    required super.evaluation,
    required super.talk,
    required super.settings,
    required super.now,
    required super.language,
    super.random,
  });

  void showLine(CharacterLine? line) =>
      emit(state.copyWith(line: line, clearLine: line == null));
}

class _BubbleCharacters extends FakeCharacterRepository {
  _BubbleCharacters(this.text);
  final String? text;

  @override
  Future<List<CharacterLine>> lines(
    String characterId,
    String language,
  ) async => [
    if (text != null)
      for (final line in await super.lines(characterId, language))
        CharacterLine(
          id: line.id,
          category: line.category,
          intensity: line.intensity,
          emotion: line.emotion,
          text: text!,
        ),
  ];
}
