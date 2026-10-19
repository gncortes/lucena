import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/endgames/assessment_attempt_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_progress_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/assessment_attempt.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/routing/router.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/sound/game_haptics.dart';
import 'package:lucena/ui/core/sound/game_sounds.dart';
import 'package:lucena/ui/core/widgets/position_board.dart';
import 'package:lucena/ui/endgames/view_models/assessment_cubit.dart';
import 'package:lucena/ui/endgames/widgets/assessment_pilot_page.dart';
import 'package:lucena/ui/endgames/widgets/assessment_response_form.dart';
import 'package:lucena/ui/endgames/widgets/assessment_screen.dart';
import 'package:lucena/ui/endgames/widgets/exercise_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';
import '../../../testing/test_dependencies.dart';

class _Now implements Now {
  @override
  DateTime call() => DateTime.utc(2026, 1, 1);
}

class _Repository implements AssessmentAttemptRepository {
  AssessmentAttempt? saved;
  int reads = 0;
  @override
  Future<AssessmentAttempt?> loadCurrent() async {
    reads++;
    return saved;
  }

  @override
  Future<AssessmentAttempt?> loadById(String id) async =>
      saved?.attemptId == id ? saved : null;
  @override
  Future<void> save(AssessmentAttempt attempt) async {
    saved = attempt;
  }
}

class _Fixture {
  final repository = _Repository();
  final settings = SettingsCubit(
    FakeSettingsRepository(
      const AppSettings(board: BoardSettings(colors: BoardColors.green)),
    ),
    languages: AppLanguage.selectable,
  );
  late final cubit = AssessmentCubit(
    config: AssessmentConfig(
      lessonId: 'mates.bishopKnight.deletang',
      exerciseId: 'finalNetAssessment01',
      initialFen: GameRules.initial.fen,
      student: Side.black,
      contentIdentity: const {'public': 'synthetic-test'},
      createAttemptId: () => 'public-host-attempt',
      now: _Now(),
    ),
    repository: repository,
    pickOpponent: (position, history) async => null,
    facts: (attempt) async => null,
  );

  Future<void> mount(
    WidgetTester tester, {
    Future<AssessmentCubit> Function()? create,
    VoidCallback? onBack,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await settings.load();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(() async {
        // The host owns disposal. Do not await its already completed close
        // Future again from a different async zone; close only unowned leftovers.
        if (!cubit.isClosed) await cubit.close();
        if (!settings.isClosed) await settings.close();
      });
    });
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        child: AssessmentPilotPage(
          create: create ?? () async => cubit,
          onBack: onBack ?? () {},
        ),
      ),
    );
    await tester.pump();
  }
}

AssessmentScreen _screen(WidgetTester tester) =>
    tester.widget<AssessmentScreen>(find.byType(AssessmentScreen));

Future<void> _tapSheet(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

GoRoute _exerciseRoute(List<RouteBase> routes) {
  for (final route in routes.whereType<GoRoute>()) {
    if (route.path == 'ex/:exercise') return route;
    try {
      return _exerciseRoute(route.routes);
    } on StateError {
      /* Continue sibling search. */
    }
  }
  throw StateError('Exercise route missing');
}

void main() {
  testWidgets(
    'pilot host create failure offers neutral retry and back then loads once',
    (tester) async {
      final f = _Fixture();
      var creates = 0, backs = 0;
      await f.mount(
        tester,
        create: () async {
          if (++creates == 1) throw StateError('synthetic creation failure');
          return f.cubit;
        },
        onBack: () => backs++,
      );
      await tester.pumpAndSettle();
      expect(find.byType(AssessmentScreen), findsNothing);
      expect(find.byKey(AssessmentPilotKeys.retry), findsOneWidget);
      await tester.tap(find.byKey(AssessmentPilotKeys.back));
      expect(backs, 1);
      await tester.tap(find.byKey(AssessmentPilotKeys.retry));
      await tester.pumpAndSettle();
      expect(creates, 2);
      expect(f.repository.reads, 1);
      expect(find.byType(AssessmentScreen), findsOneWidget);
      expect(f.cubit.state.conceptualResult, isNull);
    },
  );

  testWidgets(
    'pilot host closes a creation completing after disposal without loading it',
    (tester) async {
      final f = _Fixture();
      final pending = Completer<AssessmentCubit>();
      await f.mount(tester, create: () => pending.future);
      expect(find.byKey(AssessmentPilotKeys.loading), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete(f.cubit);
      await tester.pump();
      expect(f.cubit.isClosed, isTrue);
      expect(f.repository.reads, 0);
      expect(find.byType(AssessmentScreen), findsNothing);
    },
  );

  testWidgets(
    'pilot host owns disposal and passes localized labels preferences and IDs',
    (tester) async {
      final f = _Fixture();
      await f.mount(tester);
      await tester.pumpAndSettle();
      final screen = _screen(tester);
      expect(f.repository.reads, 1);
      expect(screen.labels.title, 'Respostas da avaliação');
      expect(
        screen.responseLabels.pieceLabel(AssessmentPiece.knight),
        'Cavalo',
      );
      expect(screen.boardSettings.colors, BoardColors.green);
      expect(screen.createRelationId(), isNot(screen.createRelationId()));
      expect(screen.confirmNewAttempt, isNotNull);
      expect(screen.confirmRemoveTarget, isNotNull);
      expect(screen.confirmRemoveRelation, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(f.cubit.isClosed, isTrue);
    },
  );

  testWidgets(
    'pilot host confirmations cancel without changing responses and confirm explicitly',
    (tester) async {
      final f = _Fixture();
      await f.mount(tester);
      await tester.pumpAndSettle();
      final screen = _screen(tester);
      final relation = AssessmentRelation(
        id: 'public-relation',
        snapshotRef: null,
        piece: AssessmentPiece.king,
        kind: AssessmentRelationKind.control,
        targetSquares: {'a1'},
        useFor: {AssessmentComponent.pieces},
        moment: AssessmentMoment.plannedOrUnrepresented,
      );
      final confirms = [
        screen.confirmFinishExecution,
        screen.confirmExit,
        screen.confirmRemoveTarget!,
        () => screen.confirmRemoveRelation!(relation),
        screen.confirmNewAttempt!,
      ];
      final before = f.cubit.state.snapshot!.draft.toJson();
      for (final confirm in confirms) {
        final cancelled = confirm();
        await tester.pumpAndSettle();
        await _tapSheet(tester, AssessmentPilotKeys.cancel);
        expect(await cancelled, isFalse);
        expect(f.cubit.state.snapshot!.draft.toJson(), before);
        final accepted = confirm();
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(AssessmentPilotKeys.confirm)).height,
          greaterThanOrEqualTo(52),
        );
        await _tapSheet(tester, AssessmentPilotKeys.confirm);
        expect(await accepted, isTrue);
      }
      final dismissed = screen.confirmExit();
      await tester.pumpAndSettle();
      await _tapSheet(tester, AssessmentPilotKeys.sheetClose);
      expect(await dismissed, isFalse);
    },
  );

  testWidgets(
    'pilot host unrepresented picker offers all coordinates without inventing position',
    (tester) async {
      final f = _Fixture();
      await f.mount(tester);
      await tester.pumpAndSettle();
      final selected = {'a1'};
      final picker = _screen(tester).pickSquares;
      final cancelled = picker(null, selected);
      await tester.pumpAndSettle();
      expect(find.byType(PositionBoard), findsNothing);
      expect(
        tester
            .getSize(find.byKey(AssessmentPilotKeys.square('a1')))
            .shortestSide,
        greaterThanOrEqualTo(44),
      );
      expect(
        find.descendant(
          of: find.byKey(AssessmentPilotKeys.squareGrid),
          matching: find.byType(InkWell),
        ),
        findsNWidgets(64),
      );
      await tester.tap(find.byKey(AssessmentPilotKeys.square('b2')));
      await _tapSheet(tester, AssessmentPilotKeys.cancel);
      expect(await cancelled, isNull);
      expect(selected, {'a1'});
      final accepted = picker(null, selected);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Semantics>(
              find
                  .ancestor(
                    of: find.byKey(AssessmentPilotKeys.square('a1')),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .properties
            .selected,
        isTrue,
      );
      await tester.tap(find.byKey(AssessmentPilotKeys.square('b2')));
      await _tapSheet(tester, AssessmentPilotKeys.confirm);
      expect(await accepted, {'a1', 'b2'});
      expect(selected, {'a1'});
    },
  );

  testWidgets(
    'pilot host positioned picker respects student orientation and X preserves selection',
    (tester) async {
      final f = _Fixture();
      await f.mount(tester);
      await tester.pumpAndSettle();
      final snapshot = AssessmentFormSnapshot(
        ref: 'ply:0',
        fen: GameRules.initial.fen,
        label: 'Posição pública',
      );
      final selected = {'h8'};
      final picker = _screen(tester).pickSquares;
      final dismissed = picker(snapshot, selected);
      await tester.pumpAndSettle();
      final board = tester.widget<PositionBoard>(
        find.byKey(AssessmentPilotKeys.pickerBoard),
      );
      expect(board.orientation, Side.black);
      expect(board.fen, snapshot.fen);
      expect(
        tester.getTopLeft(find.byKey(AssessmentPilotKeys.square('h1'))).dx,
        lessThan(
          tester.getTopLeft(find.byKey(AssessmentPilotKeys.square('a1'))).dx,
        ),
      );
      await tester.tap(find.byKey(AssessmentPilotKeys.square('a1')));
      await _tapSheet(tester, AssessmentPilotKeys.sheetClose);
      expect(await dismissed, isNull);
      expect(selected, {'h8'});
      final accepted = picker(snapshot, selected);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AssessmentPilotKeys.square('a1')));
      await _tapSheet(tester, AssessmentPilotKeys.confirm);
      expect(await accepted, {'h8', 'a1'});
    },
  );

  testWidgets(
    'pilot exit goes to catalog instead of unavailable lesson parent',
    (tester) async {
      final f = _Fixture();
      await f.settings.load();
      final router = GoRouter(
        initialLocation: '/endgames/unavailable/ex/pilot',
        routes: [
          GoRoute(
            path: '/endgames',
            builder: (_, _) =>
                const Scaffold(body: Text('catalog destination')),
            routes: [
              GoRoute(
                path: ':lesson',
                builder: (_, _) =>
                    const Scaffold(body: Text('unavailable parent')),
                routes: [
                  GoRoute(
                    path: 'ex/:exercise',
                    builder: (_, _) =>
                        AssessmentPilotPage(create: () async => f.cubit),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        router.dispose();
        await tester.runAsync(() async {
          if (!f.cubit.isClosed) await f.cubit.close();
          if (!f.settings.isClosed) await f.settings.close();
        });
      });
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          settingsCubit: f.settings,
          router: router,
          child: const SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();
      expect(router.canPop(), isTrue);
      _screen(tester).onExit();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/endgames');
      expect(find.text('catalog destination'), findsOneWidget);
      expect(find.text('unavailable parent'), findsNothing);
    },
  );

  for (final path in [
    '/endgames/mates.bishopKnight.deletang/ex/finalNetAssessment01',
    '/endgames/mates.bishopKnight.deletang/ex/public-other',
    '/endgames/public-other/ex/finalNetAssessment01',
  ]) {
    testWidgets('pilot route uses the real exclusive branch for $path', (
      tester,
    ) async {
      final f = _Fixture();
      var creates = 0;
      final source = buildRouter(
        createAssessmentPilot: () async {
          creates++;
          return f.cubit;
        },
      );
      final leaf = _exerciseRoute(source.configuration.routes);
      final router = GoRouter(
        initialLocation: path,
        routes: [
          GoRoute(
            path: '/endgames/:lesson/ex/:exercise',
            pageBuilder: leaf.pageBuilder,
          ),
        ],
      );
      final deps = testDependencies();
      await f.settings.load();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        router.dispose();
        source.dispose();
        await tester.runAsync(() async {
          if (!f.cubit.isClosed) await f.cubit.close();
          if (!f.settings.isClosed) await f.settings.close();
        });
      });
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<Now>.value(value: deps.now),
            RepositoryProvider<EndgameLessonRepository>.value(
              value: deps.endgameLessonRepository,
            ),
            RepositoryProvider<EndgameProgressRepository>.value(
              value: deps.endgameProgressRepository,
            ),
            RepositoryProvider<CharacterRepository>.value(
              value: deps.characterRepository,
            ),
            RepositoryProvider<GameSounds>.value(
              value: GameSounds(deps.settingsRepository, deps.soundRepository),
            ),
            RepositoryProvider<GameHaptics>.value(
              value: GameHaptics(
                deps.settingsRepository,
                deps.hapticsRepository,
              ),
            ),
          ],
          child: TestApp(
            locale: const Locale('pt'),
            settingsCubit: f.settings,
            router: router,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (path ==
          '/endgames/mates.bishopKnight.deletang/ex/finalNetAssessment01') {
        expect(find.byType(AssessmentPilotPage), findsOneWidget);
        expect(find.byType(AssessmentScreen), findsOneWidget);
        expect(find.byType(ExerciseScreen), findsNothing);
        expect(creates, 1);
        expect(f.repository.reads, 1);
      } else {
        expect(find.byType(AssessmentPilotPage), findsNothing);
        expect(find.byType(ExerciseScreen), findsOneWidget);
        expect(creates, 0);
      }
    });
  }
}
