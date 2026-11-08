import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/home_course_card.dart';
import 'package:lucena/domain/use_cases/training/needs_opening_profile.dart';
import 'package:lucena/ui/core/keys/training_profile_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/home_actions.dart';
import 'package:lucena/ui/training_profile/widgets/training_profile_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/test_app.dart';

const opening = TrainingLesson(
  id: 'pilares.c5.london',
  kind: TrainingLessonKind.opening,
  title: 'London',
  partId: 'p1',
  openingProfile: 'solido',
);
const aggressive = TrainingLesson(
  id: 'pilares.c5.e4White',
  kind: TrainingLessonKind.opening,
  title: '1.e4',
  partId: 'p1',
  openingProfile: 'agressivo',
);
final resources = TrainingResources(lessons: [opening, aggressive]);
TrainingState fresh() =>
    TrainingState(course: TrainingCourse.pilares, installSeed: 'profile-test');

void main() {
  test('switch goals use the newly downloaded profile and retain non-opening goals', () async {
    final state = fresh().copyWith(
      onboardingDone: true,
      day: DayGoals(
        date: '2026-10-30',
        studyDay: true,
        goals: [
          TrainingGoal(kind: GoalKind.lesson, ref: 'next'),
          TrainingGoal(
            kind: GoalKind.openings,
            ref: 'openings',
            items: {opening.id: 'one'},
          ),
        ],
      ),
      openings: {
        for (final lesson in [opening, aggressive])
          lesson.id: OpeningTrack(lessonId: lesson.id, startedOn: '2026-10-28'),
      },
    );
    final repo = FakeTrainingRepository(
      states: {TrainingCourse.pilares: state},
      content: {TrainingCourse.pilares: resources},
    );
    final cubit = CourseGuideCubit(
      repository: repo,
      config: TrainingCourseConfig.pilares,
      now: FakeNow(DateTime(2026, 10, 30)),
      beforeOpeningProfileLoad: () async {
        repo.content[TrainingCourse.pilares] = TrainingResources(
          lessons: [aggressive],
          openings: {
            aggressive.id: [
              OpeningTrecho(
                id: 'one',
                title: '1.e4',
                moves: const ['e2e4'],
                profile: 'agressivo',
              ),
            ],
          },
        );
      },
    );
    addTearDown(cubit.close);
    addTearDown(repo.dispose);
    await cubit.load();
    expect(await cubit.selectOpeningProfile('agressivo'), isTrue);
    final saved = await repo.load(TrainingCourse.pilares);
    expect(
      saved.day!.goals.where((g) => g.kind == GoalKind.lesson).single.ref,
      'next',
    );
    expect(
      saved.day!.goals.where((g) => g.kind == GoalKind.openings).single.items,
      {aggressive.id: 'one'},
    );
    expect(saved.openings.keys, containsAll([opening.id, aggressive.id]));
  });

  test(
    'gate at opening boundary, selected and legacy histories are respected',
    () {
      final state = fresh();
      expect(needsOpeningProfile(state, resources, opening), isTrue);
      expect(needsOpeningProfile(state, resources, null), isFalse);
      expect(
        needsOpeningProfile(
          state,
          resources,
          const TrainingLesson(
            id: 'theme',
            kind: TrainingLessonKind.theme,
            title: 'Theme',
          ),
        ),
        isFalse,
      );
      expect(
        needsOpeningProfile(
          state.copyWith(openingProfileStartPart: 'p1'),
          resources,
          opening,
        ),
        isFalse,
      );
      expect(
        needsOpeningProfile(
          state.copyWith(completedLessons: {opening.id: '2026-10-30'}),
          resources,
          opening,
        ),
        isFalse,
      );
      expect(
        needsOpeningProfile(
          state.copyWith(
            openings: {
              opening.id: OpeningTrack(
                lessonId: opening.id,
                startedOn: '2026-10-30',
              ),
            },
          ),
          resources,
          opening,
        ),
        isFalse,
      );
      expect(
        needsOpeningProfile(
          TrainingState(course: TrainingCourse.escola, installSeed: 'school'),
          resources,
          opening,
        ),
        isFalse,
      );
    },
  );

  test(
    'choice awaits durable save then downloads and reloads chosen resources',
    () async {
      final repo = FakeTrainingRepository(
        content: {TrainingCourse.pilares: resources},
      );
      final persisted = Completer<void>();
      repo.beforeSave = persisted.future;
      var prepared = false;
      final cubit = CourseGuideCubit(
        repository: repo,
        config: TrainingCourseConfig.pilares,
        now: FakeNow(DateTime(2026, 10, 30)),
        beforeOpeningProfileLoad: () async {
          expect(
            (await repo.load(TrainingCourse.pilares)).openingProfile,
            'agressivo',
          );
          prepared = true;
          repo.content[TrainingCourse.pilares] = TrainingResources(
            lessons: [aggressive],
          );
        },
      );
      addTearDown(cubit.close);
      addTearDown(repo.dispose);
      await cubit.load();
      final choosing = cubit.selectOpeningProfile('agressivo', startPart: 'p1');
      await Future<void>.delayed(Duration.zero);
      expect(prepared, isFalse);
      expect(cubit.state.saving, isTrue);
      persisted.complete();
      expect(await choosing, isTrue);
      expect(prepared, isTrue);
      expect(cubit.state.nextLesson!.id, aggressive.id);
      final restored = TrainingState.fromJson(
        (await repo.load(TrainingCourse.pilares)).toJson(),
      );
      expect(restored.openingProfile, 'agressivo');
      expect(needsOpeningProfile(restored, resources, opening), isFalse);
    },
  );

  test('switch retains both profiles history, download failure blocks launch and retry works', () async {
    final tracks = {
      for (final lesson in [opening, aggressive])
        lesson.id: OpeningTrack(
          lessonId: lesson.id,
          startedOn: '2026-10-28',
          doneTrechos: const {'one': '2026-10-29'},
          firstTry: const {
            'one': [true, false, true],
          },
        ),
    };
    final repo = FakeTrainingRepository(
      content: {TrainingCourse.pilares: resources},
      states: {TrainingCourse.pilares: fresh().copyWith(openings: tracks)},
    );
    var fail = true;
    final cubit = CourseGuideCubit(
      repository: repo,
      config: TrainingCourseConfig.pilares,
      now: FakeNow(DateTime(2026, 10, 30)),
      beforeOpeningProfileLoad: () async {
        if (fail) throw StateError('offline');
      },
    );
    addTearDown(cubit.close);
    addTearDown(repo.dispose);
    await cubit.load();
    expect(await cubit.selectOpeningProfile('agressivo'), isFalse);
    expect(cubit.state.failed, isTrue);
    fail = false;
    expect(await cubit.selectOpeningProfile('agressivo'), isTrue);
    expect(await cubit.selectOpeningProfile('solido'), isTrue);
    final restored = await repo.load(TrainingCourse.pilares);
    expect(
      restored.openings.map((key, value) => MapEntry(key, value.toJson())),
      tracks.map((key, value) => MapEntry(key, value.toJson())),
    );
  });

  testWidgets('draft and cancel do not save; choose persists aggressive once', (
    tester,
  ) async {
    final repo = FakeTrainingRepository(
      content: {TrainingCourse.pilares: resources},
    );
    final cubit = CourseGuideCubit(
      repository: repo,
      config: TrainingCourseConfig.pilares,
      now: FakeNow(DateTime(2026, 10, 30)),
    );
    addTearDown(cubit.close);
    addTearDown(repo.dispose);
    await cubit.load();
    var backed = false, chosen = false;
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(
          value: cubit,
          child: TrainingProfileScreen(
            onBack: () => backed = true,
            onChosen: () => chosen = true,
            onWhyLondon: () {},
            startPart: 'p1',
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(TrainingProfileKeys.card('agressivo')));
    await tester.pump();
    expect(repo.writes, 0);
    expect(find.text('Escolher o Agressivo'), findsOneWidget);
    await tester.tap(find.byKey(TrainingProfileKeys.back));
    expect(backed, isTrue);
    expect(repo.writes, 0);
    await tester.tap(find.byKey(TrainingProfileKeys.choose));
    await tester.pumpAndSettle();
    expect(chosen, isTrue);
    expect(
      (await repo.load(TrainingCourse.pilares)).openingProfile,
      'agressivo',
    );
    expect(repo.writes, 1);
  });

  for (final legacy in [false, true]) {
    testWidgets('Home opening entry gates only new users legacy=$legacy', (
      tester,
    ) async {
      final state = fresh().copyWith(
        openingProfileStartPart: legacy ? 'p1' : '',
      );
      final repo = FakeTrainingRepository(
        states: {TrainingCourse.pilares: state},
      );
      addTearDown(repo.dispose);
      final training = HomeTraining(
        config: TrainingCourseConfig.pilares,
        state: state,
        resources: resources,
        card: HomeCourseCard(
          HomeCourseStatus.lesson,
          HomeCourseDestination.lesson,
          opening.id,
        ),
      );
      String? profilePart;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => openTrainingCourse(context, training),
                child: const Text('Open'),
              ),
            ),
          ),
          GoRoute(
            path: '/training/:course',
            builder: (_, _) => const SizedBox(),
          ),
          GoRoute(
            path: '/training/:course/profile',
            builder: (_, state) {
              profilePart = state.uri.queryParameters['part'];
              return const Scaffold(body: Text('profile-destination'));
            },
          ),
          GoRoute(
            path: '/endgames/:chapter/roteiro',
            builder: (_, _) => const Scaffold(body: Text('lesson-destination')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        RepositoryProvider<TrainingRepository>.value(
          value: repo,
          child: TestApp(router: router, child: const SizedBox()),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      if (legacy) {
        expect(find.text('lesson-destination'), findsOneWidget);
      } else {
        expect(find.text('profile-destination'), findsOneWidget);
        expect(profilePart, 'p1');
      }
    });
  }
}
