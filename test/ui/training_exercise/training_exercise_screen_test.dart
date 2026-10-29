import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/keys/sheet_keys.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';
import 'package:lucena/ui/core/widgets/actions_footer.dart';
import 'package:lucena/ui/core/theme/app_colors.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/training_exercise/view_models/training_exercise_cubit.dart';
import 'package:lucena/ui/training_exercise/widgets/training_exercise_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';
import '../../../testing/goldens/golden_harness.dart';

void main() {
  setUpAll(Goldens.loadFonts);
  final exercise = TrainingExercise(
    id: 'mock',
    stars: 1,
    fen: '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1',
    solution: ['a1a8'],
    mock: true,
  );
  final goal = TrainingGoal(
    kind: GoalKind.exercise,
    ref: 'theme',
    itemId: 'mock',
  );
  const teacher = Character(
    id: Character.masterId,
    level: 2600,
    name: 'Viktor',
    tagline: {},
    personality: {},
    traits: [],
    avatar: 'assets/branding/stockfish.png',
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
    testWidgets('exercise, hint, result and next goal at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(top: 52, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 52, bottom: 24);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final settings = SettingsCubit(
        FakeSettingsRepository(),
        languages: AppLanguage.selectable,
      );
      await settings.load();
      addTearDown(settings.close);
      final repo = FakeTrainingRepository(
        states: {
          TrainingCourse.pilares: TrainingState(
            course: TrainingCourse.pilares,
            installSeed: 'test',
            day: DayGoals(date: '2026-10-29', studyDay: true, goals: [goal]),
            cycles: {
              'theme': ThemeCycle(lessonId: 'theme', startedOn: '2026-10-28'),
            },
          ),
        },
        content: {
          TrainingCourse.pilares: TrainingResources(
            banks: {
              'theme': [exercise],
            },
          ),
        },
      );
      addTearDown(repo.dispose);
      var next = 0;
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          child: TrainingExerciseScreen(
            repository: repo,
            config: TrainingCourseConfig.pilares,
            now: FakeNow(DateTime(2026, 10, 29, 12)),
            goalKey: goal.key,
            title: 'Tema',
            teacher: teacher,
            onNextGoal: () => next++,
            onRedoLesson: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(TrainingKeys.exerciseBoard), findsOneWidget);
      expect(
        tester.getSize(find.byKey(TrainingKeys.exerciseBoard)).width,
        size.width > size.height ? lessThan(size.width) : size.width,
      );
      void expectCenteredBoard() {
        expectTrainingSpeechFont(tester);
        final board = tester.getRect(find.byKey(TrainingKeys.exerciseBoard));
        expect(
          board.width,
          size.width > size.height ? lessThan(size.width) : size.width,
        );
        expect(board.width, greaterThan(0));
        expect(board.center.dy, closeTo((52 + size.height - 24) / 2, .01));
        final speech = tester.getRect(find.byType(TeacherSpeech));
        expect(speech.bottom, closeTo(board.top, .01));
        expect(speech.top, greaterThanOrEqualTo(52 + 64));
      }

      expectCenteredBoard();
      expect(find.text('As brancas jogam: ache o golpe.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Dica'));
      await tester.pumpAndSettle();
      expect(find.byKey(TrainingKeys.hintBadge), findsOneWidget);
      final cubit = tester
          .element(find.byKey(TrainingKeys.exerciseBoard))
          .read<TrainingExerciseCubit>();
      await cubit.play('a1a8');
      await tester.pumpAndSettle();
      expect(find.text('Correto.'), findsOneWidget);
      expectCenteredBoard();
      expect(find.text('Amanhã, um mais fácil'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(TrainingKeys.nextGoal));
      expect(next, 1);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'completed failed exercise is read-only and shows solution action',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 915);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final settings = SettingsCubit(
        FakeSettingsRepository(),
        languages: AppLanguage.selectable,
      );
      await settings.load();
      addTearDown(settings.close);
      final repo = FakeTrainingRepository(
        states: {
          TrainingCourse.pilares: TrainingState(
            course: TrainingCourse.pilares,
            installSeed: 'test',
            day: DayGoals(
              date: '2026-10-29',
              studyDay: true,
              goals: [goal.complete()],
            ),
            cycles: {
              'theme': ThemeCycle(
                lessonId: 'theme',
                startedOn: '2026-10-28',
                days: [
                  const ThemeDay(
                    date: '2026-10-29',
                    exerciseId: 'mock',
                    stars: 1,
                    correct: false,
                  ),
                ],
              ),
            },
          ),
        },
        content: {
          TrainingCourse.pilares: TrainingResources(
            banks: {
              'theme': [exercise],
            },
          ),
        },
      );
      addTearDown(repo.dispose);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          child: TrainingExerciseScreen(
            repository: repo,
            config: TrainingCourseConfig.pilares,
            now: FakeNow(DateTime(2026, 10, 29, 12)),
            goalKey: goal.key,
            title: 'Tema',
            teacher: teacher,
            onNextGoal: () {},
            onRedoLesson: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Não.'), findsOneWidget);
      expect(find.byKey(TrainingKeys.secondary), findsOneWidget);
      expect(find.byType(Chessboard), findsOneWidget);
      expect(repo.writes, 0);
      await tester.tap(find.byKey(TrainingKeys.secondary));
      await tester.pumpAndSettle();
      expect(find.text('Ra8#'), findsOneWidget);
      expect(find.byKey(SheetKeys.close), findsOneWidget);
      await tester.tap(find.byKey(SheetKeys.close));
      await tester.pumpAndSettle();
      expect(find.text('Ra8#'), findsNothing);
      expect(repo.writes, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final size in [const Size(360, 740), const Size(412, 917)]) {
    for (final ending in ['firm', 'reinforce', 'redo', 'redoAfter']) {
      testWidgets(
        'cycle $ending uses Canvas speech and stacked footer at $size',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final settings = SettingsCubit(
            FakeSettingsRepository(),
            languages: AppLanguage.selectable,
          );
          await settings.load();
          addTearDown(settings.close);
          final after = ending == 'redoAfter';
          final phase = ending == 'firm'
              ? ThemePhase.firm
              : ending == 'reinforce'
              ? ThemePhase.reinforce
              : ThemePhase.redo;
          final completed = TrainingGoal(
            kind: after ? GoalKind.reinforce : GoalKind.exercise,
            ref: 'theme',
            itemId: 'mock',
            done: true,
          );
          final cycle = ThemeCycle(
            lessonId: 'theme',
            startedOn: '2026-10-23',
            phase: phase,
            reinforcement: [for (var i = 0; i < 7; i++) 'remaining$i'],
            days: [
              for (var i = 0; i < 7; i++)
                ThemeDay(
                  date: '2026-10-${23 + i}',
                  exerciseId: 'mock',
                  stars: [1, 1, 2, 2, 3, 3, 3][i],
                  correct: ending == 'firm' || ending != 'redo' && i < 4,
                ),
              if (after)
                for (var i = 0; i < 7; i++)
                  ThemeDay(
                    date: '2026-10-${23 + i}',
                    exerciseId: 'mock',
                    stars: 1,
                    correct: i < 4,
                    phase: ThemePhase.reinforce,
                  ),
            ],
          );
          final repo = FakeTrainingRepository(
            states: {
              TrainingCourse.pilares: TrainingState(
                course: TrainingCourse.pilares,
                installSeed: 'end',
                day: DayGoals(
                  date: '2026-10-29',
                  studyDay: true,
                  goals: [completed],
                ),
                cycles: {'theme': cycle},
              ),
            },
            content: {
              TrainingCourse.pilares: TrainingResources(
                banks: {
                  'theme': [exercise],
                },
              ),
            },
          );
          addTearDown(repo.dispose);
          await tester.pumpWidget(
            TestApp(
              locale: const Locale('pt'),
              settingsCubit: settings,
              child: TrainingExerciseScreen(
                repository: repo,
                config: TrainingCourseConfig.pilares,
                now: FakeNow(DateTime(2026, 10, 29, 12)),
                goalKey: completed.key,
                title: 'Tema',
                teacher: teacher,
                onNextGoal: () {},
                onRedoLesson: (_) {},
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(TrainingKeys.nextGoal));
          await tester.pumpAndSettle();
          expect(find.byKey(TrainingKeys.exerciseEnd), findsOneWidget);
          expect(find.byType(TeacherSpeech), findsOneWidget);
          expectTrainingSpeechFont(tester);
          if (ending == 'firm') {
            expect(
              tester.widget<TeacherSpeech>(find.byType(TeacherSpeech)).text,
              isNot(contains('tropeço')),
            );
          }
          expect(
            tester.widget<ActionsFooter>(find.byType(ActionsFooter)).stacked,
            isTrue,
          );
          expect(
            tester.getSize(find.byKey(TrainingKeys.endPrimary)).height,
            52,
          );
          final circles = tester.widgetList<CircleAvatar>(
            find.byType(CircleAvatar),
          );
          expect(circles, hasLength(7));
          expect(
            circles.every(
              (c) =>
                  c.backgroundColor == AppColors.trainingDayCorrect ||
                  c.backgroundColor == AppColors.trainingDayWrong,
            ),
            isTrue,
          );
          if (ending == 'reinforce') {
            expect(
              find.textContaining('Os 7 exercícios que faltam de Tema'),
              findsOneWidget,
            );
          }
          if (ending != 'firm') {
            expect(
              tester.getSize(find.byKey(TrainingKeys.endSecondary)).height,
              52,
            );
            expect(
              tester.getTopLeft(find.byKey(TrainingKeys.endSecondary)).dy,
              greaterThan(
                tester.getBottomLeft(find.byKey(TrainingKeys.endPrimary)).dy,
              ),
            );
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}

void expectTrainingSpeechFont(WidgetTester tester) {
  final speech = find.byType(TeacherSpeech);
  final widget = tester.widget<TeacherSpeech>(speech);
  expect(Theme.of(tester.element(speech)).textTheme.bodyLarge!.fontSize, 14);
  final rendered = tester
      .widgetList<RichText>(
        find.descendant(of: speech, matching: find.byType(RichText)),
      )
      .where((w) => w.text.toPlainText() == widget.text);
  expect(rendered, isNotEmpty);
  expect(rendered.last.text.style!.fontSize, 14);
}
