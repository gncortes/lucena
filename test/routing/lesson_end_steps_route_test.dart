import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/lesson_ad/course_access_repository.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/data/repositories/training/demo_offer_repository.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/domain/use_cases/training/demo_offer_rules.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/routing/frentes/d1_routes.dart';
import 'package:lucena/routing/route_names.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/lesson_end_keys.dart';

import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/fakes/fake_course_training_repository.dart';
import '../../testing/fakes/fake_lesson_ad_repositories.dart';
import '../../testing/fakes/fake_now.dart';
import '../domain/use_cases/training/goal/goal_rules_test.dart' show course;
import '../domain/use_cases/training/lesson_end_steps_test.dart' show planned;

const _finishKey = Key('test.finish');

class _MemoryOffers implements DemoOfferRepository {
  _MemoryOffers(this.now);
  final Now now;
  DemoOfferState state = const DemoOfferState();

  @override
  Future<DemoOfferState> load(TrainingCourse course) async => state;

  @override
  Future<DemoOfferState> markShown(TrainingCourse course) async =>
      state = DemoOfferRules.shown(state, now());
}

class _Harness {
  _Harness(CourseAccess access) : access = FakeCourseAccessRepository(access);

  final FakeCourseAccessRepository access;
  final now = FakeNow(DateTime(2026, 11, 7, 18));
  late final offers = _MemoryOffers(now);
  final saved = planned(dayDone: true).copyWith(
    cycles: {
      'c1.l3': ThemeCycle(
        lessonId: 'c1.l3',
        startedOn: '2026-11-04',
        days: const [
          ThemeDay(date: 'a', exerciseId: 'e1', stars: 3, correct: true),
          ThemeDay(date: 'b', exerciseId: 'e2', stars: 0, correct: false),
        ],
      ),
    },
  );
  String? next = 'não terminou';

  Future<void> pump(WidgetTester t) async {
    final training = FakeTrainingRepository(
      states: {TrainingCourse.pilares: saved},
      content: {TrainingCourse.pilares: course()},
    );
    addTearDown(training.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              key: _finishKey,
              onPressed: () async => next = await showLessonEndSteps(
                context,
                course: TrainingCourse.pilares,
                saved: saved,
                lessonId: 'c1.l3',
                lessonTitle: 'Garfo de cavalo',
              ),
              child: const Text('terminar'),
            ),
          ),
        ),
        GoRoute(
          name: RouteNames.pilaresOffer,
          path: '/oferta',
          builder: (_, _) => const Scaffold(),
        ),
        ...d1Routes,
      ],
    );
    addTearDown(router.dispose);
    await t.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<TrainingRepository>.value(value: training),
          RepositoryProvider<CourseAccessRepository>.value(value: access),
          RepositoryProvider<DemoOfferRepository>.value(value: offers),
          RepositoryProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(),
          ),
          RepositoryProvider<Now>.value(value: now),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
        ),
      ),
    );
    await t.tap(find.byKey(_finishKey));
    await t.pumpAndSettle();
  }
}

void main() {
  testWidgets('H-LIC-50: comprador vê a meta do dia e volta sem oferta', (
    t,
  ) async {
    final h = _Harness(CourseAccess.owned);
    await h.pump(t);
    expect(find.byKey(LessonEndKeys.dayGoal), findsOneWidget);
    expect(find.text('Capítulo 1 · Capítulo 1'), findsOneWidget);
    await t.tap(find.byKey(LessonEndKeys.dayGoalBack));
    await t.pumpAndSettle();
    expect(find.byKey(LessonEndKeys.offer), findsNothing);
    expect(find.byKey(_finishKey), findsOneWidget);
    expect(h.next, isNull);
    expect(h.offers.state.count, 0);
  });

  testWidgets('H-LIC-50: "Fazer o teste agora" leva ao teste do capítulo', (
    t,
  ) async {
    final h = _Harness(CourseAccess.owned);
    await h.pump(t);
    await t.tap(find.byKey(LessonEndKeys.dayGoalTest));
    await t.pumpAndSettle();
    expect(h.next, Routes.endgameExercisesIntro('c1.test'));
  });

  testWidgets('H-LIC-51: na demo a oferta vem depois da meta e conta a '
      'exibição; "Agora não" volta ao Treino', (t) async {
    final h = _Harness(CourseAccess.demo);
    await h.pump(t);
    await t.tap(find.byKey(LessonEndKeys.dayGoalBack));
    await t.pumpAndSettle();
    expect(find.byKey(LessonEndKeys.offer), findsOneWidget);
    expect(find.text('Capítulo 1 concluído'), findsOneWidget);
    expect(h.offers.state.count, 1);
    await t.tap(find.byKey(LessonEndKeys.offerNotNow));
    await t.pumpAndSettle();
    expect(find.byKey(_finishKey), findsOneWidget);
    expect(h.next, isNull);
  });

  testWidgets('H-LIC-51: "Ver o curso completo" abre a oferta do Pilares', (
    t,
  ) async {
    final h = _Harness(CourseAccess.demo);
    await h.pump(t);
    await t.tap(find.byKey(LessonEndKeys.dayGoalBack));
    await t.pumpAndSettle();
    await t.tap(find.byKey(LessonEndKeys.offerAction));
    await t.pumpAndSettle();
    expect(h.next, '/oferta?origem=fim_demo');
  });

  testWidgets('H-LIC-51: depois de 2 ofertas a demo não vê mais', (t) async {
    final h = _Harness(CourseAccess.demo);
    h.offers.state = DemoOfferRules.shown(
      DemoOfferRules.shown(const DemoOfferState(), DateTime(2026, 11, 1)),
      DateTime(2026, 11, 4),
    );
    await h.pump(t);
    await t.tap(find.byKey(LessonEndKeys.dayGoalBack));
    await t.pumpAndSettle();
    expect(find.byKey(LessonEndKeys.offer), findsNothing);
    expect(h.next, isNull);
  });
}
