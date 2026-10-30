import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';

import '../training_exercise/training_exercise_screen_test.dart'
    show expectCanvasBlock;

import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/training_opening/view_models/training_opening_cubit.dart';
import 'package:lucena/ui/training_opening/widgets/training_opening_screen.dart';
import 'package:lucena/ui/training_opening/widgets/opening_goal_cards.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/board_gestures.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';
import '../../../testing/goldens/golden_harness.dart';

void main() {
  setUpAll(Goldens.loadFonts);
  final now = FakeNow(DateTime(2026, 10, 29, 12));
  const teacher = Character(
    id: Character.masterId,
    level: 2600,
    name: 'Viktor',
    tagline: {},
    personality: {},
    traits: [],
    avatar: 'assets/branding/stockfish.png',
  );
  late FakeTrainingRepository repository;
  late SettingsCubit settings;
  // Create the fake's queued Future in the widget test's FakeAsync zone.
  // A repository built in setUp owns a real-zone Future and leaves its
  // transaction (and the screen's loading spinner) pending during fake pumps.
  Future<void> prepare({OpeningTrecho? scripted, bool single = false}) async {
    settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    await settings.load();
    repository = FakeTrainingRepository(
      states: {
        TrainingCourse.pilares: TrainingState(
          course: TrainingCourse.pilares,
          installSeed: 'test',
          day: DayGoals(
            date: '2026-10-29',
            studyDay: true,
            goals: [
              TrainingGoal(
                kind: GoalKind.openings,
                ref: 'all',
                items: {'one': 't1', if (!single) 'two': 't1'},
              ),
            ],
          ),
          openings: {
            for (final id in ['one', 'two'])
              id: OpeningTrack(lessonId: id, startedOn: '2026-10-28'),
          },
        ),
      },
      content: {
        TrainingCourse.pilares: TrainingResources(
          lessons: [
            for (final id in ['one', 'two'])
              TrainingLesson(
                id: id,
                kind: TrainingLessonKind.opening,
                title: id,
              ),
          ],
          openings: {
            for (final id in ['one', 'two'])
              id: [
                scripted ??
                    OpeningTrecho(
                      id: 't1',
                      title: 'line',
                      moves: ['e2e4', 'e7e5', 'g1f3'],
                    ),
              ],
          },
        ),
      },
    );
  }

  tearDown(() async {
    await repository.dispose();
    await settings.close();
  });

  for (final blackTurn in [false, true]) {
    testWidgets(
      'practice input follows real turn with opposite view: $blackTurn',
      (tester) async {
        final fen = GameRules.initial.fen.replaceFirst(
          ' w ',
          blackTurn ? ' b ' : ' w ',
        );
        final uci = blackTurn ? 'e7e5' : 'e2e4';
        await prepare(
          single: true,
          scripted: OpeningTrecho.fromJson({
            'id': 't1',
            'titulo': '',
            'cor': blackTurn ? 'brancas' : 'pretas',
            'exemplo': {
              'id': 'practice',
              'fen': fen,
              'vira': !blackTurn,
              'pratica': {
                'tipo': 'lance',
                'maquina': blackTurn ? 'w' : 'b',
                't': 'practice',
                'linha': [
                  {
                    'certos': [uci],
                  },
                ],
                'erros': <String, String>{},
              },
              'linha': [],
            },
          }),
        );
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            settingsCubit: settings,
            child: TrainingOpeningScreen(
              repository: repository,
              config: TrainingCourseConfig.pilares,
              now: now,
              lessonId: 'one',
              teacher: teacher,
              onNextGoal: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final cubit = tester
            .element(find.byKey(TrainingKeys.openingBoard))
            .read<TrainingOpeningCubit>();
        expect(cubit.state.phase, TrainingOpeningPhase.playing);
        final board = tester.widget<Chessboard>(
          find.byKey(TrainingKeys.openingBoard),
        );
        expect(board.orientation, blackTurn ? Side.white : Side.black);
        expect(
          board.controller.game.playerSide,
          blackTurn ? PlayerSide.black : PlayerSide.white,
        );
        expect(
          tester
              .widget<IconButton>(find.byKey(TrainingKeys.exerciseHint))
              .onPressed,
          isNotNull,
        );
        final rect = tester.getRect(find.byKey(TrainingKeys.openingBoard));
        await tester.tapAt(
          squareCenter(
            rect,
            uci.substring(0, 2),
            orientation: board.orientation,
          ),
        );
        await tester.pump();
        await tester.tapAt(
          squareCenter(
            rect,
            uci.substring(2, 4),
            orientation: board.orientation,
          ),
        );
        await tester.pumpAndSettle();
        expect(cubit.state.phase, TrainingOpeningPhase.complete);
        expect(cubit.state.firstTry, [true]);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'script notation uses authored fullmove and review restores final FEN',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 917);
      addTearDown(tester.view.reset);
      await prepare(scripted: scriptedTrecho());
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          child: TrainingOpeningScreen(
            repository: repository,
            config: TrainingCourseConfig.pilares,
            now: now,
            lessonId: 'one',
            teacher: teacher,
            onNextGoal: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cubit = tester
          .element(find.byKey(TrainingKeys.openingBoard))
          .read<TrainingOpeningCubit>();
      await cubit.play('e2e4');
      await tester.pumpAndSettle();
      expect(find.text('12.'), findsOneWidget);
      expect(find.text('1.'), findsNothing);
      final latest = cubit.state.fen;
      cubit.review(0);
      await tester.pumpAndSettle();
      expect(cubit.state.fen, GameRules.initial.fen);
      cubit.review(cubit.state.cursor);
      await tester.pumpAndSettle();
      expect(cubit.state.fen, latest);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(360, 740),
    const Size(360, 800),
    const Size(384, 832),
    const Size(393, 873),
    const Size(412, 915),
    const Size(414, 896),
    const Size(800, 600),
  ]) {
    testWidgets('full-width board and start/middle/end navigation at $size', (
      tester,
    ) async {
      await prepare();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(top: 52, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 52, bottom: 24);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          child: TrainingOpeningScreen(
            repository: repository,
            config: TrainingCourseConfig.pilares,
            now: now,
            lessonId: 'one',
            teacher: teacher,
            onNextGoal: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      void expectCenteredBoard() {
        final board = tester.getRect(find.byKey(TrainingKeys.openingBoard));
        expect(board.width, greaterThan(0));
        expectCanvasBlock(tester, size, TrainingKeys.openingBoard);
      }

      expectCenteredBoard();
      final cubit = tester
          .element(find.byKey(TrainingKeys.openingBoard))
          .read<TrainingOpeningCubit>();
      expect(
        tester.widget<IconButton>(find.byKey(TrainingKeys.prevMove)).onPressed,
        isNull,
      );
      expect(
        tester.widget<IconButton>(find.byKey(TrainingKeys.nextMove)).onPressed,
        isNull,
      );
      await cubit.play('e2e4');
      await tester.pumpAndSettle();
      expect(
        tester.widget<IconButton>(find.byKey(TrainingKeys.prevMove)).onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(TrainingKeys.prevMove));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IconButton>(find.byKey(TrainingKeys.nextMove)).onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<Chessboard>(find.byKey(TrainingKeys.openingBoard))
            .controller
            .game
            .playerSide,
        PlayerSide.none,
      );
      expectCenteredBoard();
      await tester.tap(find.byKey(TrainingKeys.nextMove));
      await tester.pumpAndSettle();
      expect(cubit.state.reviewing, false);
      expectCenteredBoard();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'completion remains visible until the student chooses the next goal',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 915);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await prepare();
      var nextGoal = false;
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          child: TrainingOpeningScreen(
            repository: repository,
            config: TrainingCourseConfig.pilares,
            now: now,
            lessonId: 'one',
            teacher: teacher,
            onNextGoal: () => nextGoal = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cubit = tester
          .element(find.byKey(TrainingKeys.openingBoard))
          .read<TrainingOpeningCubit>();
      final assets = tester
          .widget<Chessboard>(find.byKey(TrainingKeys.openingBoard))
          .settings
          .pieceAssets;
      await tester.runAsync(
        () => ChessgroundImages.instance.loadAll(assets, devicePixelRatio: 1),
      );
      await tester.pumpAndSettle();
      await cubit.play('e2e4');
      await cubit.play('g1f3');
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.lessonId, 'one');
      expect(cubit.state.phase, TrainingOpeningPhase.complete);
      expect(find.byKey(TrainingKeys.nextGoal), findsOneWidget);
      expect(nextGoal, false);
      await tester.tap(find.byKey(TrainingKeys.nextGoal));
      await tester.pumpAndSettle();
      expect(nextGoal, true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('real opening list ignores retired completed IDs', (
    tester,
  ) async {
    final real = OpeningTrecho.fromJson({
      ...scriptedTrecho().toJson(),
      'id': 'ideia.ex1',
    });
    await prepare(scripted: real);
    await repository.update(
      TrainingCourse.pilares,
      (saved) => saved.copyWith(
        openings: {
          for (final id in ['one', 'two'])
            id: OpeningTrack(
              lessonId: id,
              startedOn: '2026-10-28',
              doneTrechos: {'t1': '2026-10-28'},
              firstTry: {
                't1': [true],
              },
            ),
        },
      ),
    );
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        child: _cards(
          repository: repository,
          config: TrainingCourseConfig.pilares,
          now: now,
          onTrain: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 de 1'), findsNWidgets(2));
    expect(find.text('Todas as partes feitas · só revisão'), findsNothing);
    expect(find.byKey(TrainingKeys.trainTrecho('one')), findsOneWidget);
    final saved = await repository.load(TrainingCourse.pilares);
    expect(saved.day!.goals.last.items['one'], 'ideia.ex1');
    expect(saved.openings['one']!.doneTrechos['t1'], '2026-10-28');
    expect(tester.takeException(), isNull);
  });

  testWidgets('list opens frozen available opening through host callback', (
    tester,
  ) async {
    await prepare();
    String? selected;
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        child: _cards(
          repository: repository,
          config: TrainingCourseConfig.pilares,
          now: now,
          onTrain: (id) => selected = id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(TrainingKeys.openingCard('one')), findsOneWidget);
    await tester.tap(find.byKey(TrainingKeys.trainTrecho('one')));
    expect(selected, 'one');
    expect(tester.takeException(), isNull);
  });
}

OpeningTrecho scriptedTrecho() => OpeningTrecho.fromJson({
  'id': 't1',
  'titulo': 'Script',
  'cor': 'brancas',
  'exemplo': {
    'id': 'example',
    'fen': GameRules.initial.fen,
    'vira': false,
    'objetivo': 'ganhar',
    'fim': 'proximo',
    'linha': [
      {
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 12',
        't': 'snapshot',
      },
      {
        'fen': 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 13',
        't': 'after',
        'seq': ['e2e4', 'e7e5'],
      },
      {
        'fen':
            'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 13',
        't': 'end',
        'lance': 'g1f3',
      },
    ],
  },
});

Widget _cards({
  required FakeTrainingRepository repository,
  required TrainingCourseConfig config,
  required FakeNow now,
  required ValueChanged<String> onTrain,
}) => BlocProvider(
  create: (_) =>
      TrainingOpeningCubit(repository: repository, config: config, now: now)
        ..load(),
  child: BlocBuilder<TrainingOpeningCubit, TrainingOpeningState>(
    builder: (context, state) => Scaffold(
      body: state.saved == null
          ? const SizedBox()
          : SingleChildScrollView(
              child: OpeningGoalCards(
                saved: state.saved!,
                resources: state.resources!,
                onTrain: onTrain,
              ),
            ),
    ),
  ),
);
