import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// P1 (T71): a lição que reabre numa parte (ou aula) que virou roteiro troca
/// de rota para a tela de roteiro, em vez de ficar em branco.
void main() {
  const fen = FakeEndgameLessonRepository.lucenaFen;

  EndgameTrail trail() => EndgameTrail(
    modules: [
      EndgameModule(
        id: 'rook',
        lessons: [
          EndgameLesson(
            id: 'rook.lucena',
            module: 'rook',
            lesson: Lesson.parted(
              id: 'rook.lucena',
              parts: const [
                LessonPart(
                  id: 'bridge',
                  steps: [TalkStep(id: 'end', fen: fen)],
                ),
                LessonPart(id: 'roteiro', steps: [], script: 'roteiro.json'),
              ],
            ),
            exercises: const [],
            passScore: 0,
            keyPositions: const [],
            practice: const Practice(fen: fen, goal: PositionGoal.win),
          ),
        ],
      ),
    ],
  );

  /// Abre a tela com o cubit carregando depois de montada (como no router)
  /// e devolve a rota em que o app foi parar.
  Future<Uri?> openScreen(
    WidgetTester tester,
    LessonCubit Function() create,
    Future<void> Function(LessonCubit) load,
  ) async {
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    Uri? opened;
    Widget target(GoRouterState state) {
      opened = state.uri;
      return const Scaffold(body: Text('roteiro'));
    }

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => BlocProvider(
            create: (_) {
              final cubit = create();
              load(cubit);
              return cubit;
            },
            child: const LessonScreen(),
          ),
        ),
        GoRoute(
          path: '/endgames/:lesson/roteiro',
          builder: (_, state) => target(state),
        ),
        GoRoute(
          path: '/school/:lesson/roteiro',
          builder: (_, state) => target(state),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(settingsCubit: settings, router: router, child: const SizedBox()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return opened;
  }

  testWidgets('aula de final: o checkpoint numa parte de roteiro abre o '
      'roteiro dessa parte', (tester) async {
    final progress = FakeEndgameProgressRepository(
      const EndgameProgress(
        ongoing: LessonCheckpoint(
          lessonId: 'rook.lucena',
          part: 'roteiro',
          step: 2,
        ),
      ),
    );
    final opened = await openScreen(
      tester,
      () => LessonCubit(
        source: EndgameLessonSource(
          FakeEndgameLessonRepository(trail: trail()),
          progress,
        ),
        characters: FakeCharacterRepository(),
        opponent: FakeOpponentRepository(),
        replyDelay: Duration.zero,
      ),
      (cubit) => cubit.load('rook.lucena', 'en'),
    );
    expect(
      opened.toString(),
      Routes.endgameLessonScript('rook.lucena', part: 'roteiro'),
    );
    expect(find.text('roteiro'), findsOneWidget);
    expect(find.byType(LessonScreen), findsNothing);
  });

  testWidgets('escola: a aula com roteiro e sem passos abre o roteiro', (
    tester,
  ) async {
    const course = Course(
      modules: [
        CourseModule(
          id: 'notation',
          lessons: [
            Lesson(
              id: 'notation.coordinates',
              steps: [],
              script: 'notation.coordinates',
            ),
          ],
        ),
      ],
    );
    final opened = await openScreen(
      tester,
      () => LessonCubit(
        source: SchoolLessonSource(
          FakeLessonRepository(course: course),
          FakeSchoolProgressRepository(),
        ),
        characters: FakeCharacterRepository(),
        opponent: FakeOpponentRepository(),
        replyDelay: Duration.zero,
      ),
      (cubit) => cubit.load('notation.coordinates', 'en'),
    );
    expect(opened.toString(), Routes.lessonScript('notation.coordinates'));
    expect(find.byType(LessonScreen), findsNothing);
  });

  testWidgets('a lição já carregada (sem mudança de estado) também troca de '
      'rota', (tester) async {
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(trail: trail()),
        FakeEndgameProgressRepository(),
      ),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    await cubit.load('rook.lucena', 'en', part: 'roteiro');
    expect(cubit.state.toScript, isTrue);
    final opened = await openScreen(tester, () => cubit, (_) async {});
    expect(
      opened.toString(),
      Routes.endgameLessonScript('rook.lucena', part: 'roteiro'),
    );
  });
}
