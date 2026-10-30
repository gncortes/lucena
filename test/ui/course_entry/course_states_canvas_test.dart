import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/data/repositories/training/course_download_repository.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';
import 'package:lucena/ui/course_entry/widgets/course_entry_gate.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';
import 'package:lucena/ui/course_guide/widgets/training_goals_tab.dart';
import 'package:lucena/ui/course_guide/widgets/training_progress_tab.dart';
import 'package:lucena/ui/training_opening/view_models/training_opening_cubit.dart';
import 'package:lucena/ui/training_opening/widgets/training_opening_screen.dart';
import 'package:lucena/ui/training_opening/widgets/training_opening_progress_screen.dart';
import 'package:lucena/ui/training_exercise/widgets/training_exercise_screen.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

class _Downloads extends CourseDownloadRepository {
  _Downloads({this.failure, this.loading = false}) : super.unconfigured();
  final Object? failure;
  final bool loading;
  @override
  Future<void> prepare(TrainingCourseConfig config, {String? chapterId}) async {
    if (loading) await Completer<void>().future;
    if (failure case final error?) throw error;
  }
}

const sizes = [
  Size(360, 740),
  Size(360, 800),
  Size(384, 832),
  Size(393, 873),
  Size(412, 915),
  Size(414, 896),
  Size(412, 917),
];
const capture = String.fromEnvironment('T85_CAPTURE');
final surface = GlobalKey();
late SettingsCubit settings;
late SpeechCubit speech;

Future<void> mount(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: surface,
      child: TestApp(
        mediaBuilder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 52, bottom: 24),
            viewPadding: const EdgeInsets.only(top: 52, bottom: 24),
            disableAnimations: true,
          ),
          child: child!,
        ),
        speechCubit: speech,
        settingsCubit: settings,
        locale: const Locale('pt'),
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 52, bottom: 24),
              viewPadding: const EdgeInsets.only(top: 52, bottom: 24),
              disableAnimations: true,
            ),
            child: Navigator(
              key: ObjectKey(child),
              onGenerateInitialRoutes: (navigator, initialRoute) => [
                MaterialPageRoute<void>(builder: (_) => const SizedBox()),
                MaterialPageRoute<void>(builder: (_) => child),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pumpAndSettle();
}

Future<void> shot(WidgetTester tester, String name, Size size) async {
  expect(tester.takeException(), isNull);
  for (final key in [TrainingKeys.exerciseBoard, TrainingKeys.openingBoard]) {
    if (find.byKey(key).evaluate().isNotEmpty) {
      final board = tester.getRect(find.byKey(key));
      expect(board.center.dy, closeTo((52 + size.height - 24) / 2, .01));
    }
  }
  if (capture.isEmpty) return;
  final boundary =
      surface.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  boundary.markNeedsPaint();
  await tester.pump();
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(
      '$capture/${name}_${size.width.toInt()}x${size.height.toInt()}.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void canvasTest(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (tester) async {
      final shadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        await body(tester);
      } finally {
        debugDisableShadows = shadows;
      }
    });

void main() {
  setUpAll(Goldens.loadFonts);
  setUp(() async {
    speech = SpeechCubit(
      FakeVoiceRepository(settings: const VoiceSettings(enabled: true)),
    );
    await speech.load();
    settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    await settings.load();
  });
  tearDown(() => settings.close());
  tearDown(() async {
    await speech.close();
  });
  for (final size in sizes) {
    canvasTest('C1-C3 Canvas states ${size.width}x${size.height}', (
      tester,
    ) async {
      setPhoneSize(tester, size);
      for (final config in [
        TrainingCourseConfig.pilares,
        TrainingCourseConfig.escola,
      ]) {
        final accounts = FakeAccountRepository();
        final scheduler = SyncScheduler(accounts, FakeSyncRepository());
        addTearDown(scheduler.dispose);
        Widget entry(CourseDownloadRepository downloads, {String? chapter}) =>
            MultiRepositoryProvider(
              providers: [
                RepositoryProvider<AccountRepository>.value(value: accounts),
                RepositoryProvider<CharacterRepository>(
                  create: (_) => FakeCharacterRepository(),
                ),
                RepositoryProvider<SyncScheduler>.value(value: scheduler),
                RepositoryProvider<CourseDownloadRepository>.value(
                  value: downloads,
                ),
              ],
              child: CourseEntryGate(
                key: UniqueKey(),
                config: config,
                chapterId: chapter,
                title: chapter == null ? null : 'Espeto',
                child: const SizedBox(),
              ),
            );
        final prefix = config.course == TrainingCourse.pilares
            ? 'Curso'
            : 'Escola';
        await mount(tester, entry(_Downloads()));
        expect(find.text('Usar e-mail'), findsOneWidget);
        await shot(tester, '${prefix}Conta', size);
        accounts.account = FakeAccountRepository.google;
        await mount(tester, entry(_Downloads(loading: true)));
        await shot(tester, '${prefix}Baixando', size);
        await mount(
          tester,
          entry(_Downloads(failure: const LessonContentNetworkUnavailable())),
        );
        expect(find.text('Tentar de novo'), findsOneWidget);
        await shot(tester, '${prefix}SemInternet', size);
        if (size == const Size(412, 917)) {
          for (final (name, error) in [
            ('Erro', const LessonContentUnavailable()),
            (
              'SemEspaco',
              const LessonContentStorageUnavailable(2 * 1024 * 1024),
            ),
          ]) {
            await mount(tester, entry(_Downloads(failure: error)));
            expect(find.textContaining('o curso'), findsOneWidget);
            await shot(tester, '$prefix$name', size);
          }
        }
        if (config.course == TrainingCourse.pilares) {
          await mount(
            tester,
            entry(_Downloads(loading: true), chapter: 'pilares.c1'),
          );
          await shot(tester, 'CapituloBaixando', size);
          for (final (name, error) in [
            ('CapituloSemInternet', const LessonContentNetworkUnavailable()),
            ('CapituloErro', const LessonContentUnavailable()),
            (
              'CapituloSemEspaco',
              const LessonContentStorageUnavailable(2 * 1024 * 1024),
            ),
          ]) {
            await mount(
              tester,
              entry(_Downloads(failure: error), chapter: 'pilares.c1'),
            );
            await shot(tester, name, size);
          }
        }
      }
    });

    canvasTest('C5-C7 and D6 course shell ${size.width}x${size.height}', (
      tester,
    ) async {
      setPhoneSize(tester, size);
      final clock = FakeNow(DateTime(2026, 10, 30, 12));
      const lesson = TrainingLesson(
        id: 'london',
        kind: TrainingLessonKind.opening,
        title: 'Sistema London',
        groupId: 'chapter',
        partId: 'p1',
      );
      final bank = [
        for (var i = 1; i <= 5; i++)
          OpeningTrecho(
            id: 'part-$i',
            title: 'Sistema London',
            openingId: 'london',
            profile: 'solido',
            lines: [
              ['d2d4', 'd7d5', 'c1f4'],
            ],
          ),
      ];
      for (final config in [
        TrainingCourseConfig.pilares,
        TrainingCourseConfig.escola,
      ]) {
        final repository = FakeTrainingRepository(
          states: {
            config.course: TrainingState(
              course: config.course,
              installSeed: 'canvas-test',
              onboardingDone: true,
              completedLessons: {'london': '2026-10-29'},
            ),
          },
          content: {
            config.course: TrainingResources(lessons: [lesson]),
          },
        );
        final cubit = CourseGuideCubit(
          repository: repository,
          config: config,
          now: clock,
        );
        addTearDown(cubit.close);
        addTearDown(repository.dispose);
        await cubit.load();
        Widget screen({Widget? override}) => BlocProvider.value(
          value: cubit,
          child: CourseGuideScreen(
            onBack: () {},
            onPlan: () {},
            onHelp: () {},
            onWelcomeContinue: () {},
            onLesson: (_) {},
            onChapter: (_) {},
            onStartPilares: () {},
            goalsBuilder: (_) => TrainingGoalsTab(
              onGoal: (_) {},
              onPlan: () {},
              onOpening: (_) {},
            ),
            progressBuilder: (_) => TrainingProgressTab(onTheme: (_) {}),
            bodyOverride: override,
            centerTitle: override != null,
            showHeaderActions: override == null,
            titleOverride: override == null ? null : 'Aberturas',
          ),
        );
        await mount(tester, screen());
        await shot(
          tester,
          config.course == TrainingCourse.pilares
              ? 'CursoConcluido'
              : 'EscolaConcluida',
          size,
        );
        if (config.course == TrainingCourse.escola) continue;
        repository.content[config.course] = TrainingResources(
          lessons: [
            lesson,
            const TrainingLesson(
              id: 'future',
              kind: TrainingLessonKind.theme,
              title: 'Próxima aula',
              visible: false,
              published: false,
            ),
          ],
          hasUnpublishedContent: true,
        );
        await cubit.load();
        await tester.pump();
        await shot(tester, 'AulaEmBreve', size);
        repository.content[config.course] = TrainingResources(
          lessons: [
            lesson,
            const TrainingLesson(
              id: 'next',
              kind: TrainingLessonKind.theme,
              title: 'Próxima aula',
              partId: 'p2',
            ),
            for (final slot in [
              'e4White',
              'dragon',
              'kingsIndian',
              'othersAggr',
            ])
              for (var i = 1; i <= 5; i++)
                TrainingLesson(
                  id: 'pilares.ab$i.$slot$i',
                  kind: TrainingLessonKind.opening,
                  title: slot == 'e4White'
                      ? [
                          "Escocesa: o peão de e5 expulsa o cavalo",
                          "Alapin: a dama que chega cedo vira alvo",
                          "Escandinava: espaço e tempo contra a dama",
                          "Tarrasch: jogar contra o peão isolado",
                          "Panov: o ataque com peças ativas",
                        ][i - 1]
                      : 'Lição $i',
                  openingProfile: 'agressivo',
                  partId: 'p$i',
                  visible: false,
                ),
          ],
          openings: {
            'london': bank,
            for (final (id, title) in [
              ('caroKann', 'Caro-Kann'),
              ('slav', 'Defesa Eslava'),
              ('others', 'Contra o resto'),
            ])
              id: [
                for (final part in bank)
                  OpeningTrecho.fromJson({
                    ...part.toJson(),
                    'abertura': id,
                    'titulo': title,
                    'cor': 'pretas',
                  }),
              ],
            for (final (slot, title) in [
              ('e4White', '1.e4'),
              ('dragon', 'Dragão Acelerado'),
              ('kingsIndian', 'Índia do Rei'),
              ('othersAggr', 'Contra o resto'),
            ])
              for (var i = 1; i <= 5; i++)
                'pilares.ab$i.$slot$i': [
                  for (final part in bank)
                    OpeningTrecho.fromJson({
                      ...part.toJson(),
                      'abertura': slot,
                      'titulo': title,
                      'perfil': 'agressivo',
                    }),
                ],
          },
        );
        await repository.update(
          config.course,
          (s) => s.copyWith(
            day: DayGoals(
              date: '2026-10-30',
              studyDay: true,
              goals: [
                TrainingGoal(
                  kind: GoalKind.openings,
                  ref: 'openings',
                  items: {'london': 'part-2'},
                ),
              ],
            ),
            openings: {
              for (final id in ['caroKann', 'slav', 'others'])
                id: OpeningTrack(lessonId: id, startedOn: '2026-10-29'),
              'london': OpeningTrack(
                lessonId: 'london',
                startedOn: '2026-10-29',
                doneTrechos: {'part-1': '2026-10-29'},
                firstTry: {
                  'part-1': [true, true, false],
                },
              ),
            },
          ),
        );
        await cubit.load();
        await cubit.selectTab(CourseGuideTab.progress);
        await mount(
          tester,
          screen(override: TrainingOpeningProgressScreen(onTrain: (_, _) {})),
        );
        await shot(tester, 'ProgressoAberturas', size);
        await tester.tap(find.byKey(TrainingKeys.openingProfile('change')));
        await tester.pumpAndSettle();
        await shot(tester, 'PerfilTrocar', size);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(TrainingKeys.openingProfile('change')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(TrainingKeys.openingProfile('confirm')));
        await tester.pumpAndSettle();
        expect(
          (await repository.load(config.course))
              .openings['london']!
              .doneTrechos['part-1'],
          '2026-10-29',
        );
        await shot(tester, 'PerfilTrocado', size);
        await cubit.selectOpeningProfile('solido');
        await tester.pumpAndSettle();
        await cubit.selectTab(CourseGuideTab.goals);
        await mount(tester, screen());
        await shot(tester, 'Metas', size);
        repository.content[config.course] = TrainingResources(
          lessons: [
            lesson,
            const TrainingLesson(
              id: 'offline',
              kind: TrainingLessonKind.theme,
              title: 'Espeto',
              groupId: 'offline-chapter',
            ),
          ],
          openings: {'london': bank},
          offlineChapters: {'offline-chapter'},
        );
        await repository.update(
          config.course,
          (s) => s.copyWith(
            day: s.day!.copyWith(
              goals: [
                TrainingGoal(kind: GoalKind.lesson, ref: 'offline'),
                ...s.day!.goals,
              ],
            ),
          ),
        );
        await cubit.load();
        await tester.pumpAndSettle();
        await shot(tester, 'MetasSemInternet', size);
      }
    });

    canvasTest('C6 fixed exercise prompt ${size.width}x${size.height}', (
      tester,
    ) async {
      setPhoneSize(tester, size);
      final clock = FakeNow(DateTime(2026, 10, 30, 12));
      final exercise = TrainingExercise(
        id: 'no-text',
        stars: 1,
        fen: '5r1k/5Rb1/p2P2Pp/1p5n/2p5/P4B1P/1pP5/5R1K b - - 2 32',
        solution: ['f8f7'],
      );
      final goal = TrainingGoal(
        kind: GoalKind.exercise,
        ref: 'theme',
        itemId: exercise.id,
      );
      final repository = FakeTrainingRepository(
        states: {
          TrainingCourse.pilares: TrainingState(
            course: TrainingCourse.pilares,
            installSeed: 'canvas-test',
            day: DayGoals(date: '2026-10-30', studyDay: true, goals: [goal]),
            cycles: {
              'theme': ThemeCycle(lessonId: 'theme', startedOn: '2026-10-29'),
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
      addTearDown(repository.dispose);
      await mount(
        tester,
        TrainingExerciseScreen(
          repository: repository,
          config: TrainingCourseConfig.pilares,
          now: clock,
          goalKey: goal.key,
          title: 'Garfo de cavalo',
          teacher: FakeCharacterRepository.viktor,
          onNextGoal: () {},
          onRedoLesson: (_) {},
        ),
      );
      expect(find.text('Encontre o melhor lance.'), findsOneWidget);
      await shot(tester, 'ExercicioSemFala', size);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    canvasTest(
      'D6 part start wrong correct review completed ${size.width}x${size.height}',
      (tester) async {
        setPhoneSize(tester, size);
        final clock = FakeNow(DateTime(2026, 10, 30, 12));
        final bank = [
          for (var i = 1; i <= 5; i++)
            OpeningTrecho(
              id: 'part-$i',
              title: 'Sistema London',
              lines: [
                ['d2d4', 'd7d5', 'c1f4', 'g8f6', 'e2e3'],
              ],
            ),
        ];
        final repository = FakeTrainingRepository(
          states: {
            TrainingCourse.pilares: TrainingState(
              course: TrainingCourse.pilares,
              installSeed: 'canvas-test',
              day: DayGoals(
                date: '2026-10-30',
                studyDay: true,
                goals: [
                  TrainingGoal(
                    kind: GoalKind.openings,
                    ref: 'openings',
                    items: {'london': 'part-2'},
                  ),
                ],
              ),
              openings: {
                'london': OpeningTrack(
                  lessonId: 'london',
                  startedOn: '2026-10-29',
                  doneTrechos: {'part-1': '2026-10-29'},
                  firstTry: {
                    'part-1': [true],
                  },
                ),
              },
            ),
          },
          content: {
            TrainingCourse.pilares: TrainingResources(
              openings: {
                'london': bank,
                for (final (id, title) in [
                  ('caroKann', 'Caro-Kann'),
                  ('slav', 'Defesa Eslava'),
                  ('others', 'Contra o resto'),
                ])
                  id: [
                    for (final part in bank)
                      OpeningTrecho.fromJson({
                        ...part.toJson(),
                        'abertura': id,
                        'titulo': title,
                        'cor': 'pretas',
                      }),
                  ],
              },
            ),
          },
        );
        addTearDown(repository.dispose);
        await mount(
          tester,
          TrainingOpeningScreen(
            repository: repository,
            config: TrainingCourseConfig.pilares,
            now: clock,
            lessonId: 'london',
            teacher: FakeCharacterRepository.viktor,
            onNextGoal: () {},
            onProgress: () {},
          ),
        );
        await shot(tester, 'AberturaParteInicio', size);
        final initialBoard = tester.getRect(
          find.byKey(TrainingKeys.openingBoard),
        );
        final cubit = tester
            .element(find.byKey(TrainingKeys.openingScreen))
            .read<TrainingOpeningCubit>();
        await cubit.play('e2e4');
        await tester.pumpAndSettle();
        expect(find.text('Procure outro lance.'), findsOneWidget);
        await shot(tester, 'AberturaParteErrou', size);
        await cubit.play('d2d4');
        await tester.pumpAndSettle();
        await shot(tester, 'AberturaTrecho', size);
        cubit.review(0);
        await tester.pumpAndSettle();
        await shot(tester, 'AberturaTrechoRevendo', size);
        expect(cubit.state.reviewing, true);
        cubit.review(cubit.state.cursor);
        await cubit.play('c1f4');
        await cubit.play('e2e3');
        await tester.pumpAndSettle();
        expect(find.text('Parte 2 concluída.'), findsOneWidget);
        await shot(tester, 'AberturaParteFim', size);
        expect(
          tester.getRect(find.byKey(TrainingKeys.openingBoard)),
          initialBoard,
        );
        expect(find.byKey(TrainingKeys.exerciseHint), findsNothing);
        expect(cubit.state.firstTry, [false, true, true]);
        for (var i = 3; i <= 5; i++) {
          await cubit.nextPart();
          await cubit.play('d2d4');
          await cubit.play('c1f4');
          await cubit.play('e2e3');
        }
        await tester.pumpAndSettle();
        await shot(tester, 'AberturaTreinoConcluido', size);
        expect(
          tester.getRect(find.byKey(TrainingKeys.openingBoard)),
          initialBoard,
        );
        final speechScroll = find.descendant(
          of: find.byType(TeacherSpeech),
          matching: find.byType(Scrollable),
        );
        final position = tester.state<ScrollableState>(speechScroll).position;
        if (position.maxScrollExtent > 0) {
          await tester.drag(speechScroll, const Offset(0, -240));
          await tester.pumpAndSettle();
          expect(position.pixels, position.maxScrollExtent);
          await shot(tester, 'AberturaConcluidaRolada', size);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );
  }
}
