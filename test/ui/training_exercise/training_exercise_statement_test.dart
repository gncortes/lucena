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
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/training_exercise/view_models/training_exercise_cubit.dart';
import 'package:lucena/ui/training_exercise/widgets/training_exercise_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/test_app.dart';

/// H-LIC-40 a 43: enunciado do autor, sem estrela na barra, dica em texto e
/// botão "Dica" que some depois de usado, marca única de acerto e erro.
void main() {
  setUpAll(Goldens.loadFonts);
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

  Future<TrainingExerciseCubit> open(
    WidgetTester tester,
    TrainingExercise exercise, {
    double dpr = 1,
    Size physical = const Size(412, 915),
  }) async {
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = physical;
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
    return tester
        .element(find.byKey(TrainingKeys.exerciseBoard))
        .read<TrainingExerciseCubit>();
  }

  TrainingExercise build({String? statement, String? hint}) => TrainingExercise(
    id: 'mock',
    stars: 1,
    fen: '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1',
    solution: ['a1a8'],
    mock: true,
    statement: statement,
    hintText: hint,
  );

  testWidgets('mostra o enunciado do autor no lugar do texto genérico', (
    tester,
  ) async {
    await open(tester, build(statement: 'Brancas jogam e dão mate.'));
    expect(find.text('Brancas jogam e dão mate.'), findsWidgets);
    expect(find.text('Encontre o melhor lance.'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sem enunciado mostra o texto genérico', (tester) async {
    await open(tester, build());
    expect(find.text('Encontre o melhor lance.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a barra não tem a estrela de dificuldade', (tester) async {
    await open(tester, build());
    expect(find.byKey(TrainingKeys.exerciseTitleDifficulty), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a dica aparece em texto e o botão Dica some', (tester) async {
    await open(
      tester,
      build(statement: 'Brancas jogam.', hint: 'Olhe a última fileira.'),
    );
    expect(find.byKey(TrainingKeys.exerciseHint), findsOneWidget);
    await tester.tap(find.byKey(TrainingKeys.exerciseHint));
    await tester.pumpAndSettle();
    expect(find.text('Olhe a última fileira.'), findsWidgets);
    expect(find.byKey(TrainingKeys.exerciseHint), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sem dica cadastrada a lâmpada não aparece', (tester) async {
    await open(tester, build(statement: 'Brancas jogam.'));
    expect(find.byKey(TrainingKeys.exerciseHint), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('canvas PropV1TreinoErrou: o resultado não põe marca na app bar '
      '(o selo fica só na peça)', (tester) async {
    final cubit = await open(tester, build(statement: 'Brancas jogam.'));
    await cubit.play('a1a8');
    await tester.pumpAndSettle();
    final bar = find.byType(AppBar);
    for (final icon in [Icons.check_circle, Icons.cancel]) {
      expect(
        find.descendant(of: bar, matching: find.byIcon(icon)),
        findsNothing,
      );
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('canvas PropV1TreinoErrou em 1080x2400 a 420 dpi: sem lupa e '
      '"Ver a solução" numa linha', (tester) async {
    final cubit = await open(
      tester,
      build(statement: 'Brancas jogam.'),
      dpr: 420 / 160,
      physical: const Size(1080, 2400),
    );
    await cubit.play('a1a2');
    await tester.pumpAndSettle();
    expect(find.byKey(TrainingKeys.exerciseAnalyze), findsNothing);
    final label = find.descendant(
      of: find.byKey(TrainingKeys.secondary),
      matching: find.text('Ver a solução'),
    );
    expect(label, findsOneWidget);
    // Uma linha de 16/24; duas dariam 48.
    expect(tester.getSize(label).height, lessThan(30));
    await tester.pumpWidget(const SizedBox());
  });
}
