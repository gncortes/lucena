import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/data/repositories/endgames/endgame_progress_repository.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/school_training_progress.dart';
import 'package:lucena/domain/models/training/school_training_resources.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/use_cases/training/play_training_opening.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';
import 'package:lucena/ui/course_guide/widgets/training_goals_tab.dart';
import 'package:lucena/ui/course_guide/widgets/training_progress_tab.dart';
import 'package:lucena/ui/training_help/widgets/training_tour.dart';
import 'package:lucena/ui/training_help/widgets/training_help_screen.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/training/training_scenario_builder.dart';
import '../course_entry/course_states_canvas_test.dart' as capture;

class _Files extends LessonContentReader {
  @override
  Future<String> read(String path) async {
    if (!isLessonContentPath(path)) throw ArgumentError.value(path);
    final file = File(path);
    if (!file.existsSync()) throw const LessonContentNotFound();
    return file.readAsString();
  }
}

class _NoPreferences extends PreferencesService {
  @override
  Future<String?> getString(String key) async => null;
}

class _CheckpointProgress extends EndgameProgressRepository {
  _CheckpointProgress(this.value);
  EndgameProgress value;
  @override
  Future<EndgameProgress> load() async => value;
  @override
  Future<void> save(EndgameProgress progress) async => value = progress;
}

void main() {
  if (!File('assets/courses/pilares/index.json').existsSync() ||
      !File('assets/lessons/course.json').existsSync()) {
    test(
      'private content required for full Canvas scenarios',
      () {},
      skip: true,
    );
    return;
  }
  late TrainingResources pilares, escola;
  setUpAll(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await Goldens.loadFonts();
    final assets = LessonContentAssets(reader: _Files());
    final repository = TrainingRepositoryLocal(
      _NoPreferences(),
      assets,
      installSeed: 'visual',
    );
    pilares = await repository.resources(TrainingCourse.pilares);
    await repository.dispose();
    final course = AssetLessonRepository.parseCourse(
      jsonDecode(await assets.loadString('assets/lessons/course.json')),
    );
    final texts = LessonTexts.fromJson(
      jsonDecode(await assets.loadString('assets/lessons/pt/lessons.json'))
          as Map<String, dynamic>,
    );
    escola = schoolTrainingResources(course, texts);
  });
  setUp(() async {
    capture.settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    await capture.settings.load();
    capture.speech = SpeechCubit(
      FakeVoiceRepository(settings: const VoiceSettings(enabled: true)),
    );
    await capture.speech.load();
  });
  tearDown(() async {
    await capture.speech.close();
    await capture.settings.close();
  });

  const goalSamples = {
    'MetasPrimeira': 'first',
    'MetasSegunda': 'second',
    'Metas': 'middle',
    'MetasMetaFeita': 'goalDone',
    'MetasAulaExtra': 'extraLesson',
    'MetasDiaSeguinte': 'nextDay',
    'MetasCheio': 'large',
    'MetasCheioRolada': 'large',
    'MetasFeito': 'done',
    'MetasFeitoExtra': 'doneExtra',
    'MetasDobrada': 'doubled',
    'MetasFolga': 'dayOff',
  };
  for (final size in [
    const Size(412, 917),
    const Size(360, 740),
    const Size(412, 2000),
  ]) {
    for (final name in [
      'AulaBoasVindas',
      'AulaPrimeira',
      'Aula',
      'AulaConcluida',
      'AbConcluida',
      'LicaoRetomada',
      'Catalogo',
      'ProgressoVazio',
      'Progresso',
      'ProgressoRolada',
      'ProgressoFim',
      'ProgressoTestes',
      'ProgressoCompleto',
      'Tour1',
      'Tour2',
      'Tour3',
      'Tour4',
      'Ajuda',
      ...goalSamples.keys,
      'EscolaAulaBoasVindas',
      'EscolaAulaPrimeira',
      'EscolaAula',
      'EscolaCatalogo',
      'EscolaProgresso',
      'EscolaMetasPrimeira',
      'EscolaMetasDia1',
      'EscolaMetas',
      'EscolaMetasMates',
      'EscolaMetasFeito',
    ]) {
      if ((name == 'ProgressoCompleto') != (size.height == 2000)) continue;
      testWidgets('Canvas tabs $name $size', (tester) async {
        setPhoneSize(tester, size);
        final school = name.startsWith('Escola');
        final config = school
            ? TrainingCourseConfig.escola
            : TrainingCourseConfig.pilares;
        final data = school ? escola : pilares;
        final scenario = TrainingScenarioBuilder(
          config.course,
          date: DateTime(2026, 10, 26, 12),
          resources: data,
        );
        final themes = data.lessons
            .where((l) => l.kind == TrainingLessonKind.theme)
            .toList();
        var state = school
            ? scenario.schoolDayOne()
            : scenario.goalsScenario('first');
        if (name.startsWith('Tour')) {
          state = scenario.canvasGoalsScenario('middle');
        }
        final scores = <String, int?>{};
        var tab = CourseGuideTab.lesson;
        if (name.endsWith('BoasVindas')) {
          state = state.copyWith(onboardingDone: false);
        }
        if (goalSamples.containsKey(name)) {
          state = scenario.canvasGoalsScenario(goalSamples[name]!);
          tab = CourseGuideTab.goals;
        } else if (name.contains('Progresso')) {
          tab = CourseGuideTab.progress;
          if (school) {
            state = state.copyWith(
              completedLessons: {
                for (final l in data.lessons.take(4)) l.id: '2026-10-25',
              },
              school: SchoolTrainingProgress(
                pieceLevels: {'rook': 2, 'bishop': 1, 'queen': 1, 'king': 1},
              ),
            );
          } else if (name == 'ProgressoVazio') {
            final opening = data.lessons.firstWhere(
              (l) =>
                  l.kind == TrainingLessonKind.opening &&
                  data.openings.containsKey(l.id),
            );
            state = state.copyWith(
              cycles: {
                themes.first.id: ThemeCycle(
                  lessonId: themes.first.id,
                  startedOn: '2026-10-26',
                ),
              },
              openings: {
                opening.id: OpeningTrack(
                  lessonId: opening.id,
                  startedOn: '2026-10-26',
                ),
              },
            );
          } else {
            final cycles = <String, ThemeCycle>{};
            const weights = [1, 1, 2, 2, 3, 3, 3];
            for (var i = 0; i < 4; i++) {
              final correct = i == 0
                  ? {0, 1, 2, 3, 4, 5, 6}
                  : i == 1
                  ? {0, 4, 5}
                  : i == 2
                  ? {2, 4, 5, 6}
                  : {0, 1, 2};
              cycles[themes[i].id] = ThemeCycle(
                lessonId: themes[i].id,
                startedOn: '2026-10-01',
                days: [
                  for (var d = 0; d < (i == 3 ? 6 : 7); d++)
                    ThemeDay(
                      date: '2026-10-${10 + d}',
                      exerciseId: '$i.$d',
                      stars: weights[d],
                      correct: correct.contains(d),
                    ),
                ],
              );
            }
            final openings = <String, OpeningTrack>{};
            final orderedOpenings = data.lessons
                .where(
                  (lesson) =>
                      lesson.kind == TrainingLessonKind.opening &&
                      data.openings.containsKey(lesson.id),
                )
                .take(4);
            for (final (i, lesson) in orderedOpenings.indexed) {
              final entry = MapEntry(lesson.id, data.openings[lesson.id]!);
              if (i == 1) continue;
              final count = i == 0
                  ? 1
                  : i == 2
                  ? 2
                  : entry.value.length;
              openings[entry.key] = OpeningTrack(
                lessonId: entry.key,
                startedOn: '2026-10-01',
                doneTrechos: {
                  for (final p in entry.value.take(count)) p.id: '2026-10-25',
                },
                firstTry: {
                  for (final (j, p) in entry.value.take(count).indexed)
                    p.id: () {
                      final total = PlayTrainingOpening(p)
                          .validStudentMoveCounts
                          .first;
                      final score = i == 0
                          ? 67
                          : i == 2
                          ? (j == 0 ? 100 : 80)
                          : [100, 40, 80, 100, 100][j % 5];
                      return List.generate(
                        total,
                        (index) => index < (total * score / 100).round(),
                      );
                    }(),
                },
              );
            }
            final tests = data.lessons
                .where((l) => l.kind == TrainingLessonKind.test)
                .take(4)
                .toList();
            for (final (i, test) in tests.indexed) {
              scores[test.id] = [100, 92, 75, 67][i];
            }
            state = state.copyWith(
              cycles: name == 'ProgressoTestes' ? {} : cycles,
              openings: name == 'ProgressoTestes' ? {} : openings,
            );
          }
        } else if (name.contains('Catalogo')) {
          tab = CourseGuideTab.catalog;
          state = state.copyWith(
            completedLessons: {
              for (final l in data.lessons.take(school ? 5 : 5))
                l.id: '2026-10-25',
            },
          );
        } else if (name.startsWith('EscolaMetas')) {
          tab = CourseGuideTab.goals;
          state = switch (name) {
            'EscolaMetas' => scenario.schoolPieces(),
            'EscolaMetasMates' => scenario.schoolMates(),
            'EscolaMetasFeito' => scenario.schoolAllDone(),
            'EscolaMetasDia1' => scenario.schoolDayOneProgress(),
            _ => scenario.schoolDayOne(),
          };
        } else if (name == 'Aula' || name == 'EscolaAula') {
          state = state.copyWith(
            completedLessons: {
              for (final l in data.lessons.take(4)) l.id: '2026-10-25',
            },
          );
        }
        if (name != 'MetasFolga') {
          final plan = state.plan.copyWith(weekdays: 127);
          final day = state.day;
          state = state.copyWith(
            plan: plan,
            day: day == null
                ? null
                : DayGoals(
                    date: day.date,
                    studyDay: day.studyDay,
                    plan: plan,
                    goals: day.goals,
                    doubled: day.doubled,
                  ),
          );
        }
        state = state.copyWith(tab: tab);
        final repository = FakeTrainingRepository(
          states: {config.course: state},
          content: {config.course: data},
        );
        _CheckpointProgress? checkpoint;
        if (name == 'AulaConcluida' || name == 'AbConcluida') {
          final next = data.lessons.firstWhere(
            (lesson) => name == 'AulaConcluida'
                ? lesson.id.endsWith('.knightMates')
                : lesson.kind == TrainingLessonKind.opening &&
                      lesson.partId == 'pilares.p2' &&
                      lesson.id.contains('caro'),
          );
          await repository.update(
            config.course,
            (_) => state.copyWith(
              completedLessons: {
                for (final l in data.lessons.takeWhile((l) => l.id != next.id))
                  l.id: '2026-10-26',
              },
              openingProfileStartPart: 'pilares.p1',
              day: DayGoals(
                date: '2026-10-26',
                studyDay: true,
                plan: state.plan,
                goals: const [],
              ),
            ),
          );
        } else if (name == 'LicaoRetomada') {
          checkpoint = _CheckpointProgress(
            const EndgameProgress(
              ongoing: LessonCheckpoint(
                lessonId: 'pilares.c2',
                part: 'pin',
                step: 1,
                scriptExample: 0,
                open: false,
              ),
            ),
          );
        }
        final cubit = CourseGuideCubit(
          repository: repository,
          config: config,
          now: scenario.now,
          characters: FakeCharacterRepository(),
          testProgress: checkpoint,
        );
        addTearDown(repository.dispose);
        addTearDown(cubit.close);
        await cubit.load();
        final guide = CourseGuideScreen(
          onBack: () {},
          onPlan: () {},
          onHelp: () {},
          onWelcomeContinue: () {},
          onLesson: (_) {},
          onChapter: (_) {},
          goalsBuilder: (_) => TrainingGoalsTab(
            onGoal: (_) {},
            onOpening: (_) {},
            onPlan: () {},
          ),
          progressBuilder: (_) => TrainingProgressTab(
            onTheme: (_) {},
            onOpenings: () {},
            onTest: (_) {},
            testScores: scores,
          ),
        );
        await capture.mount(
          tester,
          BlocProvider.value(
            value: cubit,
            child: name.startsWith('Tour')
                ? TrainingTour(
                    child: guide,
                    onTab: (tab) => cubit.selectTab(tab),
                    onClose: () {},
                  )
                : name == 'Ajuda'
                ? TrainingHelpScreen(onBack: () {}, onTour: () {})
                : guide,
          ),
        );
        if (name == 'MetasPrimeira' && size == const Size(412, 917)) {
          final context = tester.element(find.byType(CourseGuideScreen));
          final notice = find
              .ancestor(
                of: find.text(context.l10n.trainingFirstInfo),
                matching: find.byType(Material),
              )
              .first;
          expect(tester.getRect(notice).top, 344);
        }
        if (name.startsWith('Tour')) {
          for (var i = 1; i < int.parse(name.substring(4)); i++) {
            await tester.tap(find.byKey(TrainingKeys.tourNext));
            await tester.pumpAndSettle();
          }
        }
        if (name == 'MetasCheio' || name == 'MetasCheioRolada') {
          final exercises = cubit.state.training!.day!.goals
              .where((goal) => goal.kind == GoalKind.exercise)
              .toList();
          final first = find.byKey(
            TrainingKeys.goalTile(GoalKind.exercise.name, exercises.first.ref),
          );
          final second = find.byKey(
            TrainingKeys.goalTile(GoalKind.exercise.name, exercises[1].ref),
          );
          expect(
            tester.getTopLeft(second).dy - tester.getBottomLeft(first).dy,
            closeTo(8, 0.01),
          );
          expect(
            tester.getTopLeft(find.byKey(TrainingKeys.goalsSummary)).dy,
            124,
          );
          if (name == 'MetasCheioRolada') {
            final scroll = find.descendant(
              of: find.byType(TrainingGoalsTab),
              matching: find.byType(Scrollable),
            );
            final third = find.byKey(
              TrainingKeys.goalTile(GoalKind.exercise.name, exercises[2].ref),
            );
            await tester.scrollUntilVisible(third, 150, scrollable: scroll);
            await tester.pumpAndSettle();
            final context = tester.element(find.byType(CourseGuideScreen));
            final header = find.text(context.l10n.trainingSectionExercisesN(7));
            final viewportTop = tester.getTopLeft(scroll).dy;
            final headerHeight = tester.getSize(header).height + 12;
            final distance =
                tester.getTopLeft(third).dy - viewportTop - headerHeight;
            await tester.drag(scroll, Offset(0, -distance), touchSlopY: 0);
            await tester.pumpAndSettle();
            expect(tester.getTopLeft(header).dy, closeTo(128, 0.01));
            expect(
              tester.getTopLeft(third).dy,
              closeTo(viewportTop + headerHeight, 0.01),
            );
            if (second.evaluate().isNotEmpty) {
              expect(tester.getBottomLeft(second).dy, lessThanOrEqualTo(156));
            }
          }
        }
        if (name == 'ProgressoRolada' || name == 'ProgressoFim') {
          final context = tester.element(find.byType(CourseGuideScreen));
          final t = context.l10n;
          final title = name == 'ProgressoFim'
              ? t.reviewLegend
              : t.trainingOpeningsTitle;
          final target = find.text(title);
          await tester.scrollUntilVisible(
            target,
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await Scrollable.ensureVisible(tester.element(target), alignment: 0);
          await tester.pumpAndSettle();
        }
        await capture.shot(tester, name, size);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
    }
  }
}
