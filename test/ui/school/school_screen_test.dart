import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/widgets/course/course_continue_card.dart';
import 'package:lucena/ui/core/widgets/course/course_part_header.dart';
import 'package:lucena/ui/endgames/widgets/grade_widgets.dart';
import 'package:lucena/ui/school/view_models/school_cubit.dart';
import 'package:lucena/ui/school/widgets/school_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_placement_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

void main() {
  Future<void> pumpStarted(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    final cubit = SchoolCubit(
      lessons: FakeLessonRepository(),
      progress: FakeSchoolProgressRepository(
        const SchoolProgress(completed: {'pieces.rook'}),
      ),
      characters: FakeCharacterRepository(),
      profile: FakeProfileRepository(const UserProfile(rating: 800)),
    );
    addTearDown(cubit.close);
    await cubit.load(locale.languageCode);
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        child: BlocProvider.value(value: cubit, child: const SchoolScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('padrão T1: o Continuar na lição seguinte e as partes com '
      '"N de M"', (tester) async {
    await pumpStarted(tester);
    expect(find.text('Part 1 · lesson 2'), findsOneWidget);
    expect(find.byKey(SchoolKeys.continueButton), findsOneWidget);
    expect(find.byKey(SchoolKeys.module('pieces')), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    // A Escola não guarda pontuação: nenhuma medalha.
    expect(find.byType(GradeMedal), findsNothing);
  });

  for (final size in phoneSizes) {
    testWidgets('geometria do canvas (PropV2EscolaCurso) em '
        '${size.width.toInt()}×${size.height.toInt()}', (tester) async {
      setPhoneSize(tester, size);
      await pumpStarted(tester, locale: const Locale('pt'));
      expect(tester.takeException(), isNull);
      // Mede a partir do topo (a tela pode ter rolado até a lição atual).
      await tester.drag(find.byKey(SchoolKeys.scroll), const Offset(0, 2000));
      await tester.pumpAndSettle();
      final width = size.width;
      final bar = tester.getRect(find.byType(AppBar));
      final card = tester.getRect(find.byType(CourseContinueCard));
      expect(card.top, closeToDp(bar.bottom + 8));
      expect(card.left, closeToDp(16));
      expect(card.right, closeToDp(width - 16));
      expect(rectOf(tester, SchoolKeys.continueButton).height, closeToDp(48));
      final header = tester.getRect(find.byType(CoursePartHeader).first);
      final rook = rectOf(tester, SchoolKeys.lesson('pieces.rook'));
      final mate = rectOf(tester, SchoolKeys.lesson('pieces.mate'));
      expect(rook.top, closeToDp(header.bottom + 12));
      expect(mate.top, closeToDp(rook.bottom + 8));
      for (final tile in [rook, mate]) {
        expect(tile.left, closeToDp(16));
        expect(tile.right, closeToDp(width - 16));
        expect(tile.height, greaterThanOrEqualTo(48));
      }
      expect(find.text('Parte 1 · lição 2'), findsOneWidget);
      expect(find.text('1 de 2'), findsOneWidget);
    });
  }

  testWidgets(
    'C12c: módulo dispensado inteiro continua na trilha; grupo expandido retorna sem chaves duplicadas',
    (tester) async {
      tester.view
        ..physicalSize = const Size(360, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final progress = FakeSchoolProgressRepository(
        const SchoolProgress(
          ongoing: LessonCheckpoint(lessonId: 'mates.queen', step: 0),
        ),
      );
      final cubit = SchoolCubit(
        lessons: FakeLessonRepository(),
        progress: progress,
        characters: FakeCharacterRepository(),
        profile: FakeProfileRepository(const UserProfile(rating: 1500)),
        placement: FakePlacementRepository(
          skills: SkillMap.fromJson({
            'nodes': [
              {
                'id': 'rules.rook',
                'group': 'rules',
                'band': 'beginner',
                'lessons': [
                  {'id': 'pieces.rook', 'kind': 'school'},
                ],
              },
              {
                'id': 'mate.inOne',
                'group': 'mates',
                'band': 'beginner',
                'lessons': [
                  {'id': 'pieces.mate', 'kind': 'school'},
                ],
              },
              {
                'id': 'mate.queen',
                'group': 'mates',
                'band': 'casual',
                'lessons': [
                  {'id': 'mates.queen', 'kind': 'school'},
                ],
              },
            ],
          }),
          saveResultValue: PlacementResult(
            theta: 1500,
            low: 1400,
            high: 1600,
            takenAt: DateTime.utc(2026, 10, 11),
            nodes: const {
              'rules.rook': NodeStatus(NodeState.mastered, confirmed: true),
              'mate.inOne': NodeStatus(NodeState.mastered, confirmed: true),
              'mate.queen': NodeStatus(NodeState.gap, confirmed: true),
            },
          ),
        ),
        endgames: FakeEndgameLessonRepository(),
        endgameProgress: FakeEndgameProgressRepository(),
      );
      addTearDown(cubit.close);
      await cubit.load('en');
      final router = GoRouter(
        initialLocation: Routes.school,
        routes: [
          GoRoute(
            path: Routes.school,
            builder: (_, _) =>
                BlocProvider.value(value: cubit, child: const SchoolScreen()),
            routes: [
              GoRoute(
                path: ':lesson/roteiro',
                builder: (context, state) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      await progress.save(
                        SchoolProgress(
                          ongoing: LessonCheckpoint(
                            lessonId: state.pathParameters['lesson']!,
                            step: 0,
                          ),
                        ),
                      );
                      await cubit.load('en');
                      if (context.mounted) context.pop();
                    },
                    child: const Text('return to school'),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        TestApp(router: router, child: const SizedBox.shrink()),
      );
      await tester.pumpAndSettle();
      expect(
        cubit.state.skipped.keys,
        containsAll(['pieces.rook', 'pieces.mate']),
      );
      // Ao entrar, o nó atual distante fica visível sem gesto de rolagem.
      final current = find.byKey(SchoolKeys.lesson('mates.queen'));
      expect(current.hitTestable(), findsOneWidget);
      expect(tester.getRect(current).bottom, lessThanOrEqualTo(640));
      // O módulo inteiro permanece montado abaixo do componente de conhecidas.
      expect(find.byKey(SchoolKeys.module('pieces')), findsOneWidget);
      for (final lesson in FakeLessonRepository.sample.lessons) {
        expect(find.byKey(SchoolKeys.lesson(lesson.id)), findsOneWidget);
        expect(cubit.state.status(lesson.id), isNot(LessonStatus.locked));
      }
      await tester.ensureVisible(find.byKey(SchoolKeys.reviewSkipped));
      await tester.tap(find.byKey(SchoolKeys.reviewSkipped));
      await tester.pumpAndSettle();
      expect(cubit.state.showSkipped, isTrue);
      for (final id in ['pieces.rook', 'pieces.mate']) {
        expect(find.byKey(SchoolKeys.skippedLesson(id)), findsOneWidget);
        expect(find.byKey(SchoolKeys.lesson(id)), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      final known = find.byKey(SchoolKeys.skippedLesson('pieces.rook'));
      await tester.ensureVisible(known);
      await tester.tap(known);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        Uri.parse(Routes.lessonScript('pieces.rook')).path,
      );
      await tester.tap(find.text('return to school'));
      await tester.pumpAndSettle();
      expect(cubit.state.showSkipped, isTrue);
      expect(
        find.byKey(SchoolKeys.skippedLesson('pieces.rook')),
        findsOneWidget,
      );
      expect(
        find.byKey(SchoolKeys.lesson('pieces.rook')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
