import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/progress/progress_repository.dart';
import 'package:lucena/data/repositories/race/race_repository.dart';
import 'package:lucena/data/repositories/school/lesson_repository.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/data/repositories/training/training_school_content.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/routing/router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/lesson_finished_keys.dart';
import 'package:lucena/ui/lesson_finished/view_models/lesson_finished_cubit.dart';
import 'package:lucena/ui/lesson_finished/widgets/lesson_finished_screen.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';
import 'package:lucena/ui/lesson_script/widgets/lesson_script_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/fakes/fake_endgame_repositories.dart';
import '../../testing/fakes/fake_kpk_repository.dart';
import '../../testing/fakes/fake_lesson_script_repository.dart';
import '../../testing/fakes/fake_lesson_source.dart';
import '../../testing/fakes/fake_now.dart';
import '../../testing/fakes/fake_progress_repository.dart';
import '../../testing/fakes/fake_race_repository.dart';
import '../../testing/fakes/fake_school_repositories.dart';
import '../../testing/fakes/fake_settings_repository.dart';
import '../../testing/phone_size.dart';
import '../../testing/script_fixture.dart';
import '../../testing/test_app.dart';

void main() {
  test('finished URL keeps legacy bytes and encodes optional origin', () {
    expect(
      Routes.lessonFinished(SurveyKind.school, 'pieces.rook'),
      '/lesson-finished/school/pieces.rook',
    );
    expect(
      Routes.lessonFinished(
        SurveyKind.school,
        'pieces.rook',
        next: 'pieces.mate',
      ),
      '/lesson-finished/school/pieces.rook?next=pieces.mate',
    );
    final uri = Uri.parse(
      Routes.lessonFinished(
        SurveyKind.school,
        'pieces.rook',
        next: 'pieces.mate',
        origin: 'treino_guia',
      ),
    );
    expect(uri.queryParameters, {
      'next': 'pieces.mate',
      'origem': 'treino_guia',
    });
  });

  for (final origin in <String?>[
    null,
    'catalogo',
    'treino_guia',
    'treino_metas',
  ]) {
    for (final transition in ['school', 'endgame-finished', 'endgame-part']) {
      testWidgets('script completion carries $origin through $transition', (
        tester,
      ) async {
        setPhoneSize(tester, const Size(412, 915));
        final school = transition == 'school';
        final source = FakeLessonSource(
          endgame: !school,
          outcome: transition == 'endgame-part'
              ? const LessonOutcome(nextPart: 'second')
              : const LessonOutcome(next: 'pieces.mate'),
        );
        final settings = SettingsCubit(
          FakeSettingsRepository(),
          languages: AppLanguage.selectable,
        );
        await settings.load();
        addTearDown(settings.close);
        final cubit = LessonScriptCubit(
          lessonId: school ? 'pieces.rook' : 'pilares.c1',
          partId: 'first',
          scriptPath: 'fixture.json',
          language: 'pt',
          scripts: FakeLessonScriptRepository(scriptFixture(), scriptTexts()),
          kpk: FakeKpkRepository(),
          source: source,
          origin: origin,
          delay: (_) async {},
        );
        addTearDown(cubit.close);
        final router = GoRouter(
          initialLocation: '/source',
          routes: [
            GoRoute(
              path: '/source',
              builder: (_, _) => RepositoryProvider<CharacterRepository>.value(
                value: FakeCharacterRepository(),
                child: BlocProvider.value(
                  value: cubit,
                  child: LessonScriptScreen(title: Future.value('Fixture')),
                ),
              ),
            ),
            GoRoute(
              path: '/lesson-finished/:kind/:id',
              builder: (_, _) => const Scaffold(),
            ),
            GoRoute(
              path: '/endgames/:id/roteiro',
              builder: (_, _) => const Scaffold(),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          TestApp(
            router: router,
            settingsCubit: settings,
            locale: const Locale('pt'),
            child: const SizedBox(),
          ),
        );
        await tester.pumpAndSettle();
        expect(cubit.state.ready, true);
        await cubit.finishPart();
        await tester.pumpAndSettle();
        expect(source.completed, [
          '${school ? 'pieces.rook' : 'pilares.c1'}/first',
        ]);
        final uri = router.routeInformationProvider.value.uri;
        expect(uri.queryParameters['origem'], origin);
        expect(
          uri.path,
          transition == 'endgame-part'
              ? '/endgames/pilares.c1/roteiro'
              : '/lesson-finished/${school ? 'school' : 'endgames'}/${school ? 'pieces.rook' : 'pilares.c1'}',
        );
        expect(
          uri.queryParameters[transition == 'endgame-part' ? 'part' : 'next'],
          transition == 'endgame-part' ? 'second' : 'pieces.mate',
        );
        await tester.pumpWidget(const SizedBox());
      });
    }

    for (final kind in [SurveyKind.school, SurveyKind.endgames]) {
      testWidgets('finished Next navigates with $origin for ${kind.code}', (
        tester,
      ) async {
        setPhoneSize(tester, const Size(412, 915));
        final cubit = LessonFinishedCubit(
          kind: kind,
          lessonId: 'pieces.rook',
          nextId: 'pieces.mate',
          school: FakeLessonRepository(),
          endgames: FakeEndgameLessonRepository(),
          race: FakeRaceRepository(now: FakeNow(DateTime(2026, 10, 29))),
        );
        await cubit.load('pt');
        addTearDown(cubit.close);
        final location = Uri(
          path: '/finished',
          queryParameters: origin == null ? null : {'origem': origin},
        ).toString();
        final router = GoRouter(
          initialLocation: location,
          routes: [
            GoRoute(
              path: '/finished',
              builder: (_, _) => BlocProvider.value(
                value: cubit,
                child: LessonFinishedScreen(kind: kind),
              ),
            ),
            GoRoute(
              path: '/school/:id/roteiro',
              builder: (_, _) => const Scaffold(),
            ),
            GoRoute(
              path: '/endgames/:id/roteiro',
              builder: (_, _) => const Scaffold(),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          TestApp(
            router: router,
            locale: const Locale('pt'),
            child: const SizedBox(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(LessonFinishedKeys.next));
        await tester.pumpAndSettle();
        final uri = router.routeInformationProvider.value.uri;
        expect(
          uri.path,
          kind == SurveyKind.school
              ? '/school/pieces.mate/roteiro'
              : '/endgames/pieces.mate/roteiro',
        );
        expect(uri.queryParameters['origem'], origin);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('production finished route chooses school source for $origin', (
      tester,
    ) async {
      setPhoneSize(tester, const Size(412, 915));
      final public = FakeLessonRepository();
      final private = TrainingSchoolContent(
        FakeLessonRepository(
          texts: const LessonTexts({
            'pieces.rook.title': ['Título privado'],
          }),
        ),
        includeAll: true,
      );
      final location = Uri(
        path: '/lesson-finished/school/pieces.rook',
        queryParameters: origin == null ? null : {'origem': origin},
      ).toString();
      final router = buildRouter(initialLocation: location);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<LessonRepository>.value(value: public),
            RepositoryProvider<TrainingSchoolContent>.value(value: private),
            RepositoryProvider<EndgameLessonRepository>.value(
              value: FakeEndgameLessonRepository(),
            ),
            RepositoryProvider<RaceRepository>.value(
              value: FakeRaceRepository(now: FakeNow(DateTime(2026, 10, 29))),
            ),
            RepositoryProvider<ProgressRepository>.value(
              value: FakeProgressRepository(),
            ),
          ],
          child: TestApp(
            router: router,
            locale: const Locale('pt'),
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(LessonFinishedScreen));
      expect(
        context.read<LessonFinishedCubit>().school,
        same(origin?.startsWith('treino_') == true ? private : public),
      );
      expect(context.read<LessonFinishedCubit>().state.ready, true);
      expect(
        context.read<LessonFinishedCubit>().state.title,
        origin?.startsWith('treino_') == true ? 'Título privado' : 'The rook',
      );
      await tester.pumpWidget(const SizedBox());
    });
  }
}
