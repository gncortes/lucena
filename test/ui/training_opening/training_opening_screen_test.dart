import 'dart:ui' as ui;

import 'package:chessground/chessground.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';
import 'package:lucena/ui/core/widgets/exercise_actions.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/training_opening/view_models/training_opening_cubit.dart';
import 'package:lucena/ui/training_opening/widgets/training_opening_screen.dart';
import 'package:lucena/ui/training_opening/widgets/training_openings_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
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
  Future<void> prepare() async {
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
                items: {'one': 't1', 'two': 't1'},
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
      expect(
        tester.getSize(find.byKey(TrainingKeys.openingBoard)).width,
        size.width > size.height ? lessThan(size.width) : size.width,
      );
      void expectCenteredBoard() {
        final board = tester.getRect(find.byKey(TrainingKeys.openingBoard));
        expect(
          board.width,
          size.width > size.height ? lessThan(size.width) : size.width,
        );
        expect(board.width, greaterThan(0));
        expect(board.center.dy, closeTo((52 + size.height - 24) / 2, .01));
        final speech = tester.getRect(find.byType(TeacherSpeech));
        expect(
          Theme.of(tester.element(find.byType(TeacherSpeech)))
              .textTheme
              .bodyLarge!
              .fontSize,
          14,
        );
        expect(speech.bottom, closeTo(board.top, .01));
        expect(speech.top, greaterThanOrEqualTo(52 + 64));
      }

      expectCenteredBoard();
      final cubit = tester
          .element(find.byKey(TrainingKeys.openingBoard))
          .read<TrainingOpeningCubit>();
      expect(
        tester.widget<ExerciseActions>(find.byType(ExerciseActions)).navigation,
        ExerciseNavigation.start,
      );
      expect(
        tester.widget<ExerciseActions>(find.byType(ExerciseActions)).onNextMove,
        isNull,
      );
      await cubit.play('e2e4');
      await tester.pumpAndSettle();
      expect(
        tester.widget<ExerciseActions>(find.byType(ExerciseActions)).navigation,
        ExerciseNavigation.end,
      );
      await tester.tap(find.byKey(TrainingKeys.prevMove));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ExerciseActions>(find.byType(ExerciseActions)).navigation,
        ExerciseNavigation.middle,
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
    'completion fades before loading another opening from its initial position',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 915);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await prepare();
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
      expect(cubit.state.lessonId, 'one');
      expect(
        tester
            .widget<AnimatedOpacity>(
              find
                  .ancestor(
                    of: find.byKey(TrainingKeys.openingBoard),
                    matching: find.byType(AnimatedOpacity),
                  )
                  .first,
            )
            .duration,
        const Duration(milliseconds: 300),
      );
      await tester.pump(const Duration(milliseconds: 299));
      expect(cubit.state.lessonId, 'one');
      await tester.pump(const Duration(milliseconds: 1));
      for (var i = 0; i < 20 && cubit.state.lessonId != 'two'; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(cubit.state.lessonId, 'two');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find
            .descendant(
              of: find.byKey(TrainingKeys.openingBoard),
              matching: find.byType(RepaintBoundary),
            )
            .first,
      );
      final firstPixels = await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        image.dispose();
        return bytes;
      });
      await tester.pumpAndSettle();
      final finalPixels = await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        image.dispose();
        return bytes;
      });
      expect(firstPixels, isNotNull);
      expect(finalPixels, isNotNull);
      expect(
        listEquals(firstPixels, finalPixels),
        isTrue,
        reason:
            'Incoming opening must already paint its initial position; '
            'only the board opacity may animate during the transition',
      );
      expect(cubit.state.lessonId, 'two');
      expect(cubit.state.cursor, 0);
      await cubit.play('e2e4');
      await cubit.play('g1f3');
      await tester.pumpAndSettle();
      expect(find.byKey(TrainingKeys.nextGoal), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('list opens frozen available opening through host callback', (
    tester,
  ) async {
    await prepare();
    String? selected;
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        child: TrainingOpeningsScreen(
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
