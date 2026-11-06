@Tags(['private-content'])
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/endgames/endgame_progress_repository.dart';
import 'package:lucena/data/repositories/learning/learning_repository.dart';
import 'package:lucena/data/repositories/training/training_endgame_content.dart';
import 'package:lucena/data/repositories/training/training_learning_bridge.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/routing/training_goal_destination.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/test_canvas_keys.dart';
import 'package:lucena/ui/core/widgets/course/course_item_tile.dart';
import 'package:lucena/ui/core/widgets/reload_on_return.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';
import 'package:lucena/ui/endgames/view_models/endgame_lesson_cubit.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';
import 'package:lucena/ui/endgames/widgets/exercise_screen.dart';
import 'package:lucena/ui/endgames/widgets/exercises_done_screen.dart';
import 'package:lucena/ui/endgames/widgets/exercises_intro_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../testing/board_gestures.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

/// O Teste do capítulo 1 do Pilares com o conteúdo REAL (39 exercícios do
/// arquivo local `pilares.c1.json`, as falas e o índice do curso): Catálogo ->
/// Teste -> exercícios -> resultado -> volta ao Catálogo, e o fechar do app no
/// meio. Fake só no que não é o conteúdo: o repositório de treino em memória.
const _chapter = 'pilares.c1';

class _PrivateFiles extends AssetService {
  @override
  Future<String> loadString(String path) async {
    if (path == 'assets/courses/pilares/index.json') {
      final original =
          jsonDecode(io.File(path).readAsStringSync()) as Map<String, dynamic>;
      return jsonEncode({
        ...original,
        'partes': [
          for (final part in original['partes'] as List)
            {
              ...part as Map,
              'capitulos': [
                for (final chapter in part['capitulos'] as List)
                  if ((chapter as Map)['id'] == _chapter) chapter,
              ],
            },
        ],
      });
    }
    final file = io.File(path);
    if (!file.existsSync()) throw const LessonContentNotFound();
    return file.readAsStringSync();
  }
}

/// Deixa o trabalho de futuros de fora do relógio falso (arquivo, preferências)
/// terminar, e então assenta os quadros.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Lê no relógio real: o `await` de futuro nascido fora do falso trava o teste.
Future<T> real<T>(WidgetTester tester, Future<T> Function() read) async {
  final value = await tester.runAsync<T>(read);
  return value as T;
}

/// Um app inteiro em memória, que pode ser "morto" e reaberto com o mesmo
/// disco (preferências) e o mesmo repositório de treino.
class _Session {
  _Session(this.tester, this.disk, this.training);

  final WidgetTester tester;
  final FakeTrainingRepository training;
  // O disco do app: o que sobrevive a fechar à força.
  final PreferencesService disk;
  final now = FakeNow(DateTime(2026, 10, 30, 9));
  late final LocalEndgameProgressRepository progress =
      LocalEndgameProgressRepository(disk);
  late final content = TrainingEndgameContent(
    _PrivateFiles(),
    school: FakeLessonRepository(),
    indexes: {'pilares': 'assets/courses/pilares/index.json'},
  ).forId(_chapter)!;
  late final bridge = TrainingLearningBridge(training);
  late final learning = LearningRepository(
    disk,
    now,
    currentUid: () => null,
    versionOf: (_, _) async => 'v1',
    onUnitCompleted: bridge.call,
  );
  late CourseGuideCubit guide;
  late SettingsCubit settings;
  late GoRouter router;
  late EndgameLesson lesson;

  /// Abre o app. Leitura de arquivo e futuros prontos precisam nascer fora do
  /// relógio falso do widget, senão o `await` dentro do teste não anda.
  Future<void> open() async {
    await tester.runAsync(_prepare);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        endgameProgressRepository: progress,
        router: router,
        child: const SizedBox(),
      ),
    );
    await settle(tester);
  }

  Future<void> _prepare() async {
    await content.texts('pt');
    lesson = (await content.trail()).lesson(_chapter)!;
    guide = CourseGuideCubit(
      repository: training,
      config: TrainingCourseConfig.pilares,
      now: now,
      testLessons: content,
      testProgress: progress,
    );
    settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    await settings.load();
    await guide.load();
    EndgameLessonCubit chapterCubit() => EndgameLessonCubit(
      lessons: content,
      progress: progress,
      journey: FakeJourneyRepository(),
      characters: FakeCharacterRepository(),
    );
    router = GoRouter(
      initialLocation: '/guide',
      routes: [
        GoRoute(
          path: '/guide',
          builder: (context, _) => BlocProvider.value(
            value: guide,
            child: Builder(
              builder: (context) => ReloadOnReturn(
                onResume: true,
                onReturn: () => guide.load(),
                child: CourseGuideScreen(
                  onLevelTest: () {},
                  onBack: () {},
                  onPlan: () {},
                  onHelp: () {},
                  onWelcomeContinue: () {},
                  onLesson: (l) => context.push(
                    trainingLessonDestination(l, origin: 'treino_guia'),
                  ),
                  onChapter: (_) {},
                  goalsBuilder: (_) => const SizedBox(),
                  progressBuilder: (_) => const SizedBox(),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/endgames/:lesson/intro',
          builder: (context, state) => BlocProvider(
            create: (_) => chapterCubit()..load(_chapter, 'pt'),
            child: const ExercisesIntroScreen(),
          ),
        ),
        GoRoute(
          path: '/endgames/:lesson/done',
          builder: (context, state) => BlocProvider(
            create: (_) => chapterCubit()..load(_chapter, 'pt'),
            child: const ExercisesDoneScreen(),
          ),
        ),
        GoRoute(
          path: '/endgames/:lesson/ex/:exercise',
          builder: (context, state) {
            final exercise = state.pathParameters['exercise']!;
            return BlocProvider(
              key: ValueKey('$_chapter.$exercise'),
              create: (_) => ExerciseCubit(
                learning: learning,
                now: now,
                lessons: content,
                progress: progress,
                characters: FakeCharacterRepository(),
              )..load(_chapter, exercise, 'pt', restartPosition: true),
              child: ExerciseScreen(
                key: ValueKey('exercise.$_chapter.$exercise'),
                trainingTest: true,
                lessonId: _chapter,
                exerciseId: exercise,
              ),
            );
          },
        ),
      ],
    );
  }

  /// Fechar à força: a árvore some, só o disco fica.
  Future<void> kill() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.runAsync(() async {
      await guide.close();
      await settings.close();
    });
  }

  String get path =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;
  String get currentExercise => path.split('/').last;

  Finder get testTile => find.byKey(CourseGuideKeys.chapterLesson(_chapter));

  Future<void> openTestFromCatalog() async {
    await tester.tap(testTile);
    await settle(tester);
  }

  CourseItemState get tileState =>
      tester.widget<CourseItemTile>(testTile).state;

  /// Joga o exercício aberto: o lance ensinado ou um lance legal fora dos
  /// aceitos.
  Future<void> answerCurrent({required bool correct}) async {
    final exercise = lesson.exercises.firstWhere(
      (e) => e.id == currentExercise,
    );
    final accepted = exercise.line.first.accept;
    final String uci;
    if (correct) {
      uci = exercise.line.first.accept.first;
    } else {
      final position = GameRules.fromFen(exercise.fen)!;
      final moves = GameRules.legalMoves(position);
      uci = [
        for (final from in moves.entries)
          for (final to in from.value)
            if (!accepted.any(
              (a) => a.startsWith('${from.key.name}${to.name}'),
            ))
              '${from.key.name}${to.name}',
      ].first;
    }
    expect(uci.length, 4, reason: 'sem promoção nos exercícios do capítulo 1');
    final board = tester.getRect(find.byKey(ExerciseKeys.board));
    final side = exercise.step.side;
    await tester.tapAt(
      squareCenter(board, uci.substring(0, 2), orientation: side),
    );
    await tester.pump();
    await tester.tapAt(
      squareCenter(board, uci.substring(2, 4), orientation: side),
    );
    await settle(tester);
  }

  /// Responde do exercício aberto até o resultado; [wrong] são os índices
  /// (0..38) errados de propósito.
  Future<void> playToResult({Set<int> wrong = const {}}) async {
    var guard = 0;
    while (path.contains('/ex/')) {
      expect(guard++, lessThan(lesson.exercises.length + 1));
      final index = lesson.exercises.indexWhere((e) => e.id == currentExercise);
      await answerCurrent(correct: !wrong.contains(index));
    }
  }
}

void main() {
  late FakeTrainingRepository training;
  late PreferencesService disk;
  final config = TrainingCourseConfig.pilares;
  final resources = TrainingResources(
    lessons: const [
      TrainingLesson(
        id: _chapter,
        kind: TrainingLessonKind.test,
        title: 'Teste',
        partId: 'p1',
        partTitle: 'Primeira parte',
        groupId: _chapter,
        group: 'Capítulo 1',
      ),
    ],
  );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() => training.dispose());

  Future<_Session> launch(WidgetTester tester) async {
    setPhoneSize(tester, const Size(412, 917));
    await tester.runAsync(() async {
      disk = PreferencesService();
      training = FakeTrainingRepository(
        content: {config.course: resources},
        states: {
          config.course:
              BuildDayGoals(FakeNow(DateTime(2026, 10, 30, 9)), config)(
                TrainingState(
                  course: config.course,
                  installSeed: 'real',
                  onboardingDone: true,
                  tab: CourseGuideTab.catalog,
                ),
                resources,
              ),
        },
      );
    });
    final session = _Session(tester, disk, training);
    await session.open();
    addTearDown(() async {
      await session.guide.close();
      await session.settings.close();
    });
    return session;
  }

  /// A tabela de medalhas da introdução: nome e "N de 39" por linha.
  List<(String, String)> medalTable(WidgetTester tester) {
    final texts = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(ExercisesIntroKeys.tiers),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data!)
        .toList();
    // [cabeçalho, nome, limite, nome, limite, ...]
    return [
      for (var i = 1; i + 1 < texts.length; i += 2) (texts[i], texts[i + 1]),
    ];
  }

  String resultTitle(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(ExercisesDoneKeys.current)).data!;

  testWidgets('conteúdo real: 39 exercícios, sem promoção, tabela do 39', (
    tester,
  ) async {
    final session = await launch(tester);
    expect(session.lesson.exercises, hasLength(39));
    await session.openTestFromCatalog();
    expect(session.path, Routes.endgameExercisesIntro(_chapter));
    expect(find.text('Teste do capítulo 1'), findsOneWidget);
    expect(find.text('39 exercícios'), findsOneWidget);
    expect(find.text('Sem dica'), findsOneWidget);
    expect(medalTable(tester), [
      ('Perfeito', '39 de 39'),
      ('Excelente', '36 de 39'),
      ('Ótimo', '33 de 39'),
      ('Você passou', '30 de 39'),
      ('Não passou', '29 ou menos'),
    ]);
  });

  testWidgets(
    'todos certos: Perfeito, curso registra o teste, Catálogo mostra',
    (tester) async {
      final session = await launch(tester);
      expect(session.tileState, isNot(CourseItemState.approved));
      await session.openTestFromCatalog();
      await tester.tap(find.byKey(ExercisesIntroKeys.start));
      await settle(tester);
      await session.playToResult();

      expect(session.path, Routes.endgameExercisesDone(_chapter));
      expect(resultTitle(tester), 'Perfeito');
      expect(find.text('Teste do capítulo 1 · 39 de 39'), findsOneWidget);
      expect(find.byKey(TestCanvasKeys.answer(38)), findsOneWidget);

      final saved = (await real(tester, session.progress.load)).of(_chapter);
      expect(saved.stars, hasLength(39));
      expect(saved.completedTestOf(session.lesson)!.values, everyElement(true));
      final state = await real(
        tester,
        () => training.load(TrainingCourse.pilares),
      );
      expect(state.completedLessons.containsKey(_chapter), isTrue);

      await tester.tap(find.byKey(ExercisesDoneKeys.back));
      await settle(tester);
      expect(session.path, '/guide');
      expect(session.tileState, CourseItemState.approved);
      expect(session.guide.state.testScores[_chapter], 100);
      expect(session.guide.state.testProgress[_chapter]?.score, 39);
      expect(session.guide.state.testProgress[_chapter]?.maxScore, 39);
    },
  );

  testWidgets('6 erros: Ótimo (33 de 39), na borda da tabela; aprovado', (
    tester,
  ) async {
    final session = await launch(tester);
    await session.openTestFromCatalog();
    final table = medalTable(tester);
    await tester.tap(find.byKey(ExercisesIntroKeys.start));
    await settle(tester);
    await session.playToResult(wrong: {0, 7, 13, 20, 31, 38});

    expect(resultTitle(tester), 'Ótimo');
    expect(table[2], ('Ótimo', '33 de 39'));
    expect(find.text('Teste do capítulo 1 · 33 de 39'), findsOneWidget);
    final saved = (await real(tester, session.progress.load)).of(_chapter);
    final answers = saved.completedTestOf(session.lesson)!;
    expect(answers.values.where((v) => v), hasLength(33));
    for (final index in [0, 7, 13, 20, 31, 38]) {
      expect(answers[session.lesson.exercises[index].id], isFalse);
    }
    expect(
      (await real(
        tester,
        () => training.load(TrainingCourse.pilares),
      )).completedLessons,
      contains(_chapter),
    );
    await tester.tap(find.byKey(ExercisesDoneKeys.back));
    await settle(tester);
    expect(session.tileState, CourseItemState.approved);
    expect(session.guide.state.testScores[_chapter], 85);
  });

  testWidgets('10 erros: 29 de 39 não passa; teste não conclui no curso', (
    tester,
  ) async {
    final session = await launch(tester);
    await session.openTestFromCatalog();
    await tester.tap(find.byKey(ExercisesIntroKeys.start));
    await settle(tester);
    await session.playToResult(wrong: {for (var i = 0; i < 39; i += 4) i});

    expect(find.text('Teste do capítulo 1 · 29 de 39'), findsOneWidget);
    expect(resultTitle(tester), 'Quase lá');
    expect(find.byKey(TestCanvasKeys.reviewLessons), findsOneWidget);
    expect(find.byKey(ExercisesDoneKeys.back), findsNothing);
    expect(
      (await real(
        tester,
        () => training.load(TrainingCourse.pilares),
      )).completedLessons,
      isNot(contains(_chapter)),
    );
    await tester.tap(find.byKey(ExercisesDoneKeys.close));
    await settle(tester);
    expect(session.path, '/guide');
    expect(session.tileState, isNot(CourseItemState.approved));
    // A nota aparece mesmo sem passar.
    expect(session.guide.state.testProgress[_chapter]?.score, 29);
  });

  testWidgets(
    'segundo plano mantém tudo; fechar de verdade retoma na pergunta',
    (tester) async {
      var session = await launch(tester);
      await session.openTestFromCatalog();
      await tester.tap(find.byKey(ExercisesIntroKeys.start));
      await settle(tester);
      for (var i = 0; i < 10; i++) {
        await session.answerCurrent(correct: i != 3);
      }
      final open = session.lesson.exercises[10].id;
      expect(session.currentExercise, open);

      // Segundo plano: mesma tela, mesmo exercício, nada perdido.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(minutes: 5));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(session.currentExercise, open);
      expect(find.byKey(ExerciseKeys.board), findsOneWidget);
      expect(
        (await real(tester, session.progress.load)).of(_chapter).stars,
        hasLength(10),
      );

      // Fechar à força: o app volta ao Catálogo; as 10 respostas ficam e o
      // teste retoma exatamente na 11.
      await session.kill();
      SharedPreferencesAsyncPlatform.instance =
          SharedPreferencesAsyncPlatform.instance;
      session = _Session(tester, disk, training);
      await session.open();
      addTearDown(() async {
        await session.guide.close();
        await session.settings.close();
      });
      expect(session.path, '/guide');
      expect(session.tileState, isNot(CourseItemState.approved));
      final stars = (await real(
        tester,
        session.progress.load,
      )).of(_chapter).stars;
      expect(stars, hasLength(10));
      expect(stars[session.lesson.exercises[3].id], 0);
      await session.openTestFromCatalog();
      await tester.tap(find.byKey(ExercisesIntroKeys.start));
      await settle(tester);
      expect(session.currentExercise, open);
      expect(find.text('Teste · 11 de 39'), findsOneWidget);
      await session.playToResult();
      expect(find.text('Teste do capítulo 1 · 38 de 39'), findsOneWidget);
      expect(resultTitle(tester), 'Excelente');
    },
  );

  // BUG PARA DECISÃO DE PRODUTO (não corrigido): com o teste fechado
  // (aprovado ou não), tocar nele no Catálogo abre a introdução com o "Começar"
  // sem ação (`nextExercise` é nulo com todos respondidos). Falta decidir o
  // destino: ir direto ao resultado, ou a introdução com "Refazer". Tire o
  // `skip` quando a decisão sair; o teste já cobre os dois casos.
  for (final (name, wrong) in [
    ('aprovado (39 de 39)', <int>{}),
    ('não passou (29 de 39)', {for (var i = 0; i < 39; i += 4) i}),
  ]) {
    testWidgets(
      'teste fechado $name: tocar de novo no Catálogo não é beco sem saída',
      skip: true,
      (tester) async {
        final session = await launch(tester);
        await session.openTestFromCatalog();
        await tester.tap(find.byKey(ExercisesIntroKeys.start));
        await settle(tester);
        await session.playToResult(wrong: wrong);
        await tester.tap(find.byKey(ExercisesDoneKeys.close));
        await settle(tester);
        expect(session.path, '/guide');
        await session.openTestFromCatalog();
        // Ou vê o resultado, ou pode refazer: nunca um Começar morto.
        final start = find.byKey(ExercisesIntroKeys.start);
        if (start.evaluate().isNotEmpty) {
          expect(tester.widget<FilledButton>(start).onPressed, isNotNull);
        } else {
          expect(session.path, Routes.endgameExercisesDone(_chapter));
        }
      },
    );
  }
}
