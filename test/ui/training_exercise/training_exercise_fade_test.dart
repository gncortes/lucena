import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
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
import 'package:lucena/ui/core/motion/lucena_motion.dart';
import 'package:lucena/ui/core/motion/tabuleiro_hero.dart';
import 'package:lucena/ui/core/motion/troca_com_fade.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/training_exercise/widgets/training_exercise_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// H-ANI-03: no treino, "Ver solução" volta a posição do exercício. O
/// tabuleiro fica parado e a posição troca num fade (TrocaComFade), sem as
/// peças deslizarem de volta.
void main() {
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

  Future<void> abrir(WidgetTester tester) async {
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
          teacher: const Character(
            id: Character.masterId,
            level: 2600,
            name: 'Viktor',
            tagline: {},
            personality: {},
            traits: [],
            avatar: 'assets/branding/stockfish.png',
          ),
          onNextGoal: () {},
          onRedoLesson: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder tabuleiros() => find.byKey(TrainingKeys.exerciseBoard);

  testWidgets('H-ANI-03: "Ver solução" troca a posição em fade, parado', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.byType(TrocaComFade), findsOneWidget);
    final antes = tester.getRect(find.byType(TabuleiroHero));
    await tester.tap(find.byKey(TrainingKeys.secondary));
    await tester.pump();
    await tester.pump(LucenaMotion.trocaComFade ~/ 2);
    // Os dois cruzam no mesmo lugar: o antigo some, o novo aparece.
    expect(tabuleiros(), findsNWidgets(2));
    final opacidades = [
      for (final e in tabuleiros().evaluate())
        tester
            .widget<FadeTransition>(
              find
                  .ancestor(
                    of: find.byWidget(e.widget),
                    matching: find.byType(FadeTransition),
                  )
                  .first,
            )
            .opacity
            .value,
    ];
    expect(opacidades.every((o) => o > 0 && o < 1), isTrue);
    expect(tester.getRect(find.byType(TabuleiroHero)), antes);
    await tester.pump(LucenaMotion.trocaComFade);
    await tester.pumpAndSettle();
    expect(tabuleiros(), findsOneWidget);
    // A posição nova entrou pronta (sem deslize de volta).
    expect(
      tester.widget<Chessboard>(tabuleiros()).controller.game.fen,
      exercise.fen,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('H-ANI-03 reduzido: a troca acaba no fade curto do kit', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await abrir(tester);
    await tester.tap(find.byKey(TrainingKeys.secondary));
    await tester.pump();
    expect(tabuleiros(), findsNWidgets(2));
    await tester.pump(LucenaMotion.fadeReduzido);
    await tester.pump();
    expect(tabuleiros(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
