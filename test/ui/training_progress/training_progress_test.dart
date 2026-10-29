import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/widgets/animated_progress.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/training_progress_tab.dart';
import 'package:lucena/ui/training_progress/widgets/training_theme_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

void main() {
  final days = <ThemeDay>[
    for (var i = 0; i < 7; i++)
      ThemeDay(
        date: '2026-10-${20 + i}',
        exerciseId: 'e$i',
        stars: [1, 1, 2, 1, 2, 3, 2][i],
        correct: ![2, 5].contains(i),
        hint: i == 4,
      ),
  ];
  final cycle = ThemeCycle(
    lessonId: 'theme',
    startedOn: '2026-10-20',
    phase: ThemePhase.reinforce,
    days: [
      ...days,
      const ThemeDay(
        date: '2026-10-27',
        exerciseId: 'r1',
        stars: 3,
        correct: true,
        phase: ThemePhase.reinforce,
      ),
    ],
    reinforcement: ['r2'],
  );
  final resources = TrainingResources(
    lessons: const [
      TrainingLesson(
        id: 'theme',
        kind: TrainingLessonKind.theme,
        title: 'Tema em reforço',
      ),
      TrainingLesson(
        id: 'opening',
        kind: TrainingLessonKind.opening,
        title: 'Abertura',
      ),
      TrainingLesson(
        id: 'test1',
        kind: TrainingLessonKind.test,
        title: 'Teste com nota',
      ),
      TrainingLesson(
        id: 'test2',
        kind: TrainingLessonKind.test,
        title: 'Teste sem nota',
      ),
    ],
  );

  Future<CourseGuideCubit> load({ThemeCycle? selectedCycle}) async {
    final repository = FakeTrainingRepository(
      content: {TrainingCourse.pilares: resources},
      states: {
        TrainingCourse.pilares: TrainingState(
          course: TrainingCourse.pilares,
          installSeed: 'seed',
          cycles: {'theme': selectedCycle ?? cycle},
          openings: {
            'opening': OpeningTrack(
              lessonId: 'opening',
              startedOn: '2026-10-20',
              firstTry: {
                'a': [true, false, true],
              },
            ),
          },
        ),
      },
    );
    final cubit = CourseGuideCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: FakeNow(DateTime(2026, 10, 28)),
    );
    addTearDown(cubit.close);
    addTearDown(repository.dispose);
    await cubit.load();
    return cubit;
  }

  for (final size in phoneSizes) {
    testWidgets(
      'detalhe embedded reutiliza shell e fase firme sem reforço em $size',
      (tester) async {
        setPhoneSize(tester, size);
        final cubit = await load(
          selectedCycle: cycle.copyWith(phase: ThemePhase.firm),
        );
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            child: BlocProvider.value(
              value: cubit,
              child: const Scaffold(
                body: TrainingThemeScreen(
                  lessonId: 'theme',
                  onBack: _noBack,
                  embedded: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final t = tester.element(find.byType(TrainingThemeScreen)).l10n;
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsNothing);
        expect(find.byKey(TrainingKeys.themeScreen), findsOneWidget);
        expect(find.text(t.trainingThemeReinforceInfo), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
    for (final sample in [
      (score: 47, earned: <int>{0, 1, 2, 4}, color: const Color(0xff9a6b00)),
      (score: 73, earned: <int>{0, 2, 3, 5, 6}, color: const Color(0xff2e6b45)),
      (
        score: 100,
        earned: <int>{0, 1, 2, 3, 4, 5, 6},
        color: const Color(0xff2e6b45),
      ),
    ]) {
      testWidgets(
        'Canvas mastery ${sample.score} color and 70 percent marker at $size',
        (tester) async {
          setPhoneSize(tester, size);
          final subject = ThemeCycle(
            lessonId: 'theme',
            startedOn: '2026-10-20',
            days: [
              for (var i = 0; i < 7; i++)
                ThemeDay(
                  date: '2026-10-${20 + i}',
                  exerciseId: 's$i',
                  stars: [1, 1, 2, 2, 3, 3, 3][i],
                  correct: sample.earned.contains(i),
                ),
            ],
          );
          expect(subject.score, sample.score);
          final cubit = await load(selectedCycle: subject);
          await tester.pumpWidget(
            TestApp(
              locale: const Locale('pt'),
              child: BlocProvider.value(
                value: cubit,
                child: Scaffold(body: TrainingProgressTab(onTheme: (_) {})),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final row = find.byKey(TrainingKeys.masteryRow('theme'));
          final rendered = find.descendant(
            of: row,
            matching: find.byType(LinearProgressIndicator),
          );
          final indicator = tester.widget<LinearProgressIndicator>(rendered);
          final effectiveColor =
              indicator.color ??
              Theme.of(tester.element(rendered)).progressIndicatorTheme.color;
          expect(effectiveColor, sample.color);
          expect(indicator.value, sample.score / 100);
          final bar = tester.getRect(rendered);
          final hitArea = tester.getRect(row);
          expect(hitArea.width, size.width - 64);
          expect(bar.left, 32);
          expect(bar.width, hitArea.width - 28);
          expect(bar.height, 8);
          final marker = find.descendant(
            of: row,
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.constraints?.maxWidth == 2,
            ),
          );
          final mark = tester.getRect(marker);
          expect(mark.size, const Size(2, 14));
          expect(mark.left, closeTo(bar.left + .7 * bar.width, .001));
          expect(mark.center.dy, bar.center.dy);
          expect(tester.takeException(), isNull);
        },
      );
    }
    for (final (stars, phase, _) in [
      (<int>[], ThemePhase.cycle, ProgressRole.error),
      (<int>[1, 1, 2], ThemePhase.cycle, ProgressRole.error),
      (<int>[3, 3, 1], ThemePhase.reinforce, ProgressRole.gold),
      (<int>[3, 3, 3, 2], ThemePhase.firm, ProgressRole.success),
    ]) {
      testWidgets('barra ${phase.name} com ${stars.length} acertos em $size', (
        tester,
      ) async {
        setPhoneSize(tester, size);
        final subject = ThemeCycle(
          lessonId: 'theme',
          startedOn: '2026-10-20',
          phase: phase,
          days: [
            for (var i = 0; i < stars.length; i++)
              ThemeDay(
                date: '2026-10-${20 + i}',
                exerciseId: 's$i',
                stars: stars[i],
                correct: true,
              ),
          ],
        );
        final cubit = await load(selectedCycle: subject);
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            child: BlocProvider.value(
              value: cubit,
              child: Scaffold(body: TrainingProgressTab(onTheme: (_) {})),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final progress = tester.widget<AnimatedProgress>(
          find.byType(AnimatedProgress).first,
        );
        expect(progress.role, ProgressRole.primary);
        expect(
          progress.value,
          subject.cycleDays.length < 7
              ? subject.cycleDays.length / 7
              : subject.score / 100,
        );
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets(
      'progresso usa nota real, falta explícita e lances firmes em $size',
      (tester) async {
        setPhoneSize(tester, size);
        final cubit = await load();
        String? selected;
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            child: BlocProvider.value(
              value: cubit,
              child: Scaffold(
                body: TrainingProgressTab(
                  onTheme: (id) => selected = id,
                  testScores: const {'test1': 83},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(TrainingProgressTab));
        final t = context.l10n;
        expect(find.text(t.trainingPercent(83)), findsOneWidget);
        expect(find.text(t.trainingTestsMissing), findsOneWidget);
        expect(find.text(t.trainingOpeningsFirm(2, 3)), findsOneWidget);
        final progress = tester.widget<AnimatedProgress>(
          find.byType(AnimatedProgress).first,
        );
        expect(progress.value, cycle.score / 100);
        expect(progress.role, ProgressRole.primary);
        await tester.tap(find.byKey(TrainingKeys.masteryRow('theme')));
        expect(selected, 'theme');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'detalhe separa reforço, exibe sete exercícios e dica em $size',
      (tester) async {
        setPhoneSize(tester, size);
        final cubit = await load();
        var back = false;
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            child: BlocProvider.value(
              value: cubit,
              child: TrainingThemeScreen(
                lessonId: 'theme',
                onBack: () => back = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final t = tester.element(find.byType(TrainingThemeScreen)).l10n;
        expect(find.text(t.trainingPercent(cycle.score)), findsOneWidget);
        expect(find.byKey(TrainingKeys.themeChart), findsOneWidget);
        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
        expect(find.text('8'), findsNothing);
        await tester.scrollUntilVisible(
          find.text(t.trainingThemeReinforceInfo),
          120,
        );
        expect(find.text(t.trainingThemeReinforceInfo), findsOneWidget);
        await tester.tap(find.byKey(TrainingKeys.themeBack));
        expect(back, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

void _noBack() {}
