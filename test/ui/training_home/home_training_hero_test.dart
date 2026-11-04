import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart'
    as course_training;
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/home_course_card.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/routing/training_launch.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/motion/lucena_motion.dart';
import 'package:lucena/ui/core/motion/tabuleiro_hero.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/hero_card.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_state.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/training_exercise/widgets/training_exercise_screen.dart';
import 'package:lucena/ui/training_opening/widgets/training_opening_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  for (final status in [
    HomeCourseStatus.lesson,
    HomeCourseStatus.exercise,
    HomeCourseStatus.opening,
    HomeCourseStatus.done,
    HomeCourseStatus.dayOff,
  ]) {
    testWidgets('course card $status has the agreed label, action and no bar', (
      tester,
    ) async {
      final settings = SettingsCubit(
        FakeSettingsRepository(),
        languages: AppLanguage.selectable,
      );
      await settings.load();
      addTearDown(settings.close);
      final training = HomeTraining(
        config: TrainingCourseConfig.pilares,
        state: TrainingState(course: TrainingCourse.pilares, installSeed: 's'),
        resources: TrainingResources(
          lessons: [
            const TrainingLesson(
              id: 'lesson',
              kind: TrainingLessonKind.theme,
              title: 'Aula real',
            ),
          ],
        ),
        card: HomeCourseCard(
          status,
          status == HomeCourseStatus.done || status == HomeCourseStatus.dayOff
              ? HomeCourseDestination.lessonTab
              : HomeCourseDestination.lesson,
          'lesson',
        ),
        lessonPreview: const LessonScriptState(
          ready: true,
          fen: '4k3/8/8/8/8/8/8/4K3 b - - 0 1',
          orientation: Side.black,
        ),
      );
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          child: Scaffold(
            body: HeroCard(
              state: HomeState(
                ready: true,
                teacher: FakeCharacterRepository.viktor,
                training: training,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final label = switch (status) {
        HomeCourseStatus.lesson => 'Lição de hoje',
        HomeCourseStatus.done => 'Metas feitas · mais uma lição?',
        HomeCourseStatus.dayOff => 'Dia de folga · mais uma lição?',
        _ => 'Próxima meta',
      };
      final action = switch (status) {
        HomeCourseStatus.lesson => 'Continuar',
        HomeCourseStatus.exercise => 'Resolver',
        HomeCourseStatus.opening => 'Treinar',
        _ => 'Começar',
      };
      expect(find.text(label), findsOneWidget);
      expect(find.text(action), findsOneWidget);
      expect(find.text('Aula real'), findsOneWidget);
      expect(find.byKey(HomeKeys.heroProgress), findsNothing);
      expect(
        find.byKey(HomeKeys.heroBoard),
        status == HomeCourseStatus.done || status == HomeCourseStatus.dayOff
            ? findsNothing
            : findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final opening in [false, true]) {
    for (final black in [false, true]) {
      testWidgets(
        '${opening ? 'opening' : 'exercise'} ${black ? 'black' : 'white'} '
        'flies through the guide before I/O and keeps board geometry',
        (tester) async {
          tester.view
            ..physicalSize = const Size(412, 915)
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final settings = SettingsCubit(
            FakeSettingsRepository(),
            languages: AppLanguage.selectable,
          );
          await settings.load();
          addTearDown(settings.close);
          final exercise = TrainingExercise(
            id: 'item',
            stars: 2,
            fen:
                '6k1/5ppp/8/8/8/8/5PPP/R5K1 '
                '${black ? 'b' : 'w'} - - 0 1',
            solution: black ? ['g8f8'] : ['a1a8'],
          );
          final goal = TrainingGoal(
            kind: opening ? GoalKind.openings : GoalKind.exercise,
            ref: 'theme',
            itemId: 'item',
            items: opening ? {'theme': 'segment'} : const {},
          );
          final resources = TrainingResources(
            lessons: [
              const TrainingLesson(
                id: 'theme',
                kind: TrainingLessonKind.theme,
                title: 'Tema real',
              ),
            ],
            banks: {
              if (!opening) 'theme': [exercise],
            },
            openings: {
              'theme': [
                OpeningTrecho(
                  id: 'segment',
                  title: 'Abertura real',
                  moves: ['e2e4', 'e7e5', 'g1f3', 'b8c6'],
                  black: black,
                ),
              ],
            },
          );
          final saved = TrainingState(
            course: TrainingCourse.pilares,
            installSeed: 'test',
            day: DayGoals(date: '2026-10-29', studyDay: true, goals: [goal]),
            cycles: {
              'theme': ThemeCycle(
                lessonId: 'theme',
                startedOn: '2026-10-28',
                level: exercise.stars,
              ),
            },
          );
          final training = HomeTraining(
            config: TrainingCourseConfig.pilares,
            state: saved,
            resources: resources,
            card: HomeCourseCard(
              opening ? HomeCourseStatus.opening : HomeCourseStatus.exercise,
              opening
                  ? HomeCourseDestination.trecho
                  : HomeCourseDestination.exercise,
              'theme',
              goal: goal,
            ),
          );
          final repository = FakeTrainingRepository(
            states: {TrainingCourse.pilares: saved},
            content: {TrainingCourse.pilares: resources},
          );
          final gate = Completer<void>();
          repository.beforeResources = gate.future;
          addTearDown(repository.dispose);
          final boardKey = opening
              ? TrainingKeys.openingBoard
              : TrainingKeys.exerciseBoard;
          final side = black ? Side.black : Side.white;
          late GoRouter router;
          router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: HeroCard(
                        state: HomeState(
                          ready: true,
                          teacher: FakeCharacterRepository.viktor,
                          training: training,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: Routes.training('pilares'),
                builder: (_, _) => const Scaffold(body: Text('Guia')),
                routes: [
                  GoRoute(
                    path: 'openings',
                    builder: (_, _) => const Scaffold(body: Text('Aberturas')),
                  ),
                  GoRoute(
                    path: '${opening ? 'opening' : 'exercise'}/:theme',
                    pageBuilder: (context, state) {
                      final launch = state.extra! as TrainingLaunch;
                      final Widget child = opening
                          ? TrainingOpeningScreen(
                              repository: repository,
                              config: TrainingCourseConfig.pilares,
                              now: FakeNow(DateTime(2026, 10, 29, 12)),
                              lessonId: 'theme',
                              teacher: launch.teacher,
                              preview: launch.openingPreview,
                              onNextGoal: () {},
                            )
                          : TrainingExerciseScreen(
                              repository: repository,
                              config: TrainingCourseConfig.pilares,
                              now: FakeNow(DateTime(2026, 10, 29, 12)),
                              goalKey: goal.key,
                              title: launch.title,
                              teacher: launch.teacher,
                              preview: launch.exercisePreview,
                              onNextGoal: () {},
                              onRedoLesson: (_) {},
                            );
                      return PaginaComTabuleiro<void>(
                        context: context,
                        key: state.pageKey,
                        child: child,
                      );
                    },
                  ),
                ],
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            RepositoryProvider<course_training.TrainingRepository>.value(
              value: repository,
              child: TestApp(
                settingsCubit: settings,
                locale: const Locale('pt'),
                router: router,
                child: const SizedBox(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final miniature = tester.widget<StaticChessboard>(
            find.descendant(
              of: find.byKey(HomeKeys.heroBoard),
              matching: find.byType(StaticChessboard),
            ),
          );
          expect(miniature.orientation, side);
          expect(miniature.fen, training.fen);
          expect(find.byKey(HomeKeys.heroProgress), findsNothing);
          await tester.tap(find.byKey(HomeKeys.goalAction));
          // Saving the chosen guide tab completes before pages are pushed.
          await tester.pump();
          await tester.pump();
          expect(repository.writes, 1);
          expect(find.byType(SnackBar), findsNothing);
          // First destination frame must contain the matching arrival mark,
          // even while both repository reads are held by the gate.
          // H-ANI-02: a ponta de chegada é o TabuleiroHero do mesmo FEN do
          // cartão do Início.
          // Durante o voo o Hero tira o tabuleiro da árvore: procura-se a
          // ponta pela tela.
          final arrival = find.descendant(
            of: find.byType(
              opening ? TrainingOpeningScreen : TrainingExerciseScreen,
            ),
            matching: find.byType(TabuleiroHero),
          );
          expect(arrival, findsOneWidget);
          expect(tester.widget<TabuleiroHero>(arrival).id, training.fen);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          // No input is accepted from the visual snapshot.
          final ignores = tester.widgetList<IgnorePointer>(
            find.ancestor(of: arrival, matching: find.byType(IgnorePointer)),
          );
          expect(ignores.any((w) => w.ignoring), isTrue);
          await tester.pump(const Duration(milliseconds: 120));
          final flying = tester.getSize(find.byKey(MotionKeys.tabuleiroEmVoo));
          expect(
            flying.width > HeroCard.board && flying.width < 412,
            isTrue,
            reason: 'The Home board must be in the flight overlay',
          );
          await tester.pump(LucenaMotion.vooDoTabuleiro);
          expect(
            tester.widget<Chessboard>(find.byKey(boardKey)).orientation,
            side,
          );
          final destinationRect = tester.getRect(find.byKey(boardKey));
          gate.complete();
          await tester.pumpAndSettle();
          expect(tester.getRect(find.byKey(boardKey)), destinationRect);
          router.pop();
          await tester.pumpAndSettle();
          expect(find.text(opening ? 'Aberturas' : 'Guia'), findsOneWidget);
          if (opening) {
            router.pop();
            await tester.pumpAndSettle();
            expect(find.text('Guia'), findsOneWidget);
          }
          router.pop();
          await tester.pumpAndSettle();
          expect(find.byKey(HomeKeys.courseCard), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
